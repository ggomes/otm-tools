classdef OTM < handle
    
    properties(Access=public)
        configfile
        api
    end
    
    properties(Access=public)
        lanewidth  % [m]
        laneGroupMap
        signalMap
        fig
        sim_output
        start_time
        duration
    end
    
    methods(Access=public)
        
        % constructor
        function [this] = OTM(configfile)
            this.lanewidth = 3;
            this.configfile = configfile;
            import runner.OTM
            this.api = OTM.load(configfile,true);
            this.sim_output = [];
        end
        
        % display the network
        function [] = show_network(this,lanewidth)
            
            if nargin>=2
                this.lanewidth = lanewidth
            end
            
            if ~isempty(this.fig) && isvalid(this.fig)
                delete(this.fig)
            end
            
            % compute scalingn factor
            % scale=compute_scaling_factor()
            
            % lanegroup map
            this.laneGroupMap = containers.Map('KeyType','uint32','ValueType','any');
            
            % draw the network
            this.fig = figure; %('units','normalized','outerposition',[0 0 1 1]);
            links = this.api.get_links;
            drawLinks(1:links.size()) = DrawLink();
            for i=1:links.size()
                link = links.get(i-1);
                disp(link.getId())
                drawLinks(i) = DrawLink(link);
                drawLinks(i).draw(link,link.lanegroups,this.lanewidth);
                for j=1:link.lanegroups.size()
                    lg = drawLinks(i).lanegroups(j);
                    this.laneGroupMap(lg.id) = lg;
                end
            end
            axis('equal')
            
            % signal map
            this.signalMap = containers.Map('KeyType','uint32','ValueType','any');
            
            % create the signals
            actuators = this.api.get_actuators;
            for i = 0:actuators.size()-1
                actuator = actuators.get(i);
                if ~strcmp(actuator.type,'signal')
                    continue
                end
                this.signalMap(actuator.id) = DrawSignal(this,actuator);
            end
            
        end
        
        % run an animation
        function [] = animate(this,time_period)
            
            if nargin<2
                time_period = [-inf inf];
            end
            
            if isempty(this.sim_output)
                this.load_all_events(time_period);
            end
            
            % show the network
            if isempty(this.fig) || ~isvalid(this.fig)
                this.show_network()
            end
            
            vmap = containers.Map('KeyType','uint32','ValueType','any');
            h = textpos(0.85,0.95,0,'---',10,gca);
            
            for i=1:numel(this.sim_output.transitions)
                
                pause(0.05)
                
                % take first transition
                t = this.sim_output.transitions{i};
                %                 transitions{i} = {};
                
                h.String = sprintf('%.1f',t.time);
                
                switch class(t)
                    
                    case 'SignalEvent'
                        signal = this.signalMap(t.signal);
                        signal.set_phase_color(t.phase,t.color);
                        
                    case 'VehicleEvent'
                        
                        if vmap.isKey(t.vehicle)
                            vehicle = vmap(t.vehicle);
                        else
                            vehicle = Vehicle(t.vehicle);
                            vmap(t.vehicle) = vehicle;
                        end
                        
                        % remove vehicle from lanegroup
                        if ~isnan(t.from_lanegroup)
                            lanegroup = this.laneGroupMap(t.from_lanegroup);
                            lanegroup.remove_vehicle_from_queue(vehicle,t.from_queue);
                        end
                        
                        % add vehicle to lanegroup
                        if ~isnan(t.to_lanegroup)
                            lanegroup = this.laneGroupMap(t.to_lanegroup);
                            lanegroup.add_vehicle_to_queue(vehicle,t.to_queue);
                        else
                            % this vehicle has been removed from the network
                            delete(vehicle.myPatch)
                            remove(vmap,vehicle.id);
                            clear vehicle
                        end
                end
                
            end
        end
        
        % run a simulation
        function [] = run_simple(this,start_time,duration,request_links,request_dt)
            
            this.start_time = start_time;
            this.duration = duration;
                        
            if nargin>3
                link_ids = java.util.ArrayList;
                for i=1:numel(request_links)
                    link_ids.add(java.lang.Long(request_links(i)));
                end
                this.api.request_links_flow([],link_ids, java.lang.Float(request_dt));
                this.api.request_links_veh([],link_ids, java.lang.Float(request_dt));
            end
            
            % run the simulation
            this.api.run( uint32(start_time), uint32(duration));
            
        end
        
        % run a simulation
        function [] = run_simulation(this,prefix,output_requests_file,output_folder,duration,start_time)
            
            if nargin<6
                start_time = 0;
            end
            
            if nargin<7
                sim_dt = 5;
            end
            
            this.start_time = start_time;
            this.duration = duration;
            
            % run the simulation
            this.api.run( ...
                prefix, ...
                output_requests_file, ...
                output_folder, ...
                uint32(start_time), ...
                uint32(duration));
            
        end
        
        % =====================================================
        % complex methods (not in the Java API)
        % =====================================================
        
        function paths = get_path_travel_times(this)
            
            if ~isfield(this.sim_output,'transitions') || isempty(this.sim_output.transitions)
                this.load_all_events
            end
            
            % load lanegroups
            lanegroups = this.load_lanegroups;
            lanegroup_ids = [lanegroups.id];
            
            % keep vehicle transitions
            transitions = this.sim_output.transitions(cellfun(@(z) isa(z,'VehicleEvent'),this.sim_output.transitions));
            
            vehicle_ids = cellfun(@(z) z.vehicle , transitions);
            
            unique_vehicle_ids = unique(vehicle_ids);
            
            path_struct = struct('link_ids',[],'departure_arrival_times',[]);
            paths = repmat(path_struct,1,0);
            for i=1:numel(unique_vehicle_ids)
                v_trans = transitions(unique_vehicle_ids(i)==vehicle_ids);
                
                % not a complete trajectory
                if ~isempty(v_trans{1}.from_queue) || ~isempty(v_trans{end}.to_queue)
                    continue
                end
                
                link_ids = cellfun( @(z) lanegroups(z.to_lanegroup==lanegroup_ids).link_id  ,v_trans(1:end-1));
                link_ids([1 diff(link_ids)]==0)=[];
                
                path_ind = arrayfun(@(z) numel(z.link_ids)==numel(link_ids) && all(z.link_ids==link_ids) , paths );
                if any(path_ind)
                    paths(path_ind).departure_arrival_times(end+1,:) = [v_trans{1}.time v_trans{end}.time];
                else
                    p = path_struct;
                    p.link_ids = link_ids;
                    p.departure_arrival_times = [v_trans{1}.time v_trans{end}.time];
                    paths(end+1) = p;
                end
                
            end
            
        end
        
        function [X] = get_state_trajectory(this)
            
            output_data = this.api.get_output_data();
            it = output_data.iterator();
            X = struct('time',[],'vehs',[],'flows_vph',[],'speed_kph',[],'link_ids',[]);
            
            while(it.hasNext())

                output = it.next();

                link_ids = Java2Matlab(java.util.ArrayList(output.get_link_ids()));
                if isempty(X.link_ids)
                    X.link_ids = link_ids;
                end

                if ~setequals(X.link_ids,link_ids)
                    error('incompatible output requests')
                end
                    
                for j=1:numel(link_ids)
                    link_id = link_ids(j);
                 
                    z = output.get_profile_for_linkid(java.lang.Long(link_id));
                    time = Java2Matlab(z.get_times);
                    
                    if isempty(X.time)
                        X.time = time;
                    end
                    
                    if( ~all(X.time==time) )
                        error('incompatible output requests')
                    end
                    
                    xind = index_into(link_id,X.link_ids);
                    switch char(output.getClass().getName())
                        case 'output.LinkFlow'
                            X.flows_vph(xind,:) = diff(Java2Matlab(z.get_values))*3600/z.get_dt;
                        case 'output.LinkVehicles'
                            X.vehs(xind,:) = Java2Matlab(z.get_values);
                    end
                    
                end
                
            end
            
            for i=1:numel(X.link_ids)
                link_id = X.link_ids(i);
                link_info = this.api.get_link_with_id(link_id);
                
                if link_info.isIs_source()
                    X.speed_kph(i,:) = nan(1,numel(X.time)-1);
                    continue
                end
                
                ffspeed_kph = link_info.get_ffspeed_kph();
                link_length_km = link_info.getFull_length/1000;
                speed_kph = link_length_km * X.flows_vph(i,:) ./ X.vehs(i,1:end-1);
                speed_kph(speed_kph>ffspeed_kph) = ffspeed_kph;
                X.speed_kph(i,:) = speed_kph;
            end
            
        end
        
%         function [time,X] = get_state_trajectory(this,dt)
%             
%             if ~isfield(this.sim_output,'transitions') || isempty(this.sim_output.transitions)
%                 this.load_all_events
%             end
%             
%             % load lanegroups
%             lanegroups = this.load_lanegroups;
%             lanegroup_ids = [lanegroups.id];
%             
%             % keep vehicle transitions and where vehicles change lane group
%             transitions = this.sim_output.transitions(cellfun(@(z) isa(z,'VehicleEvent') && z.from_lanegroup~=z.to_lanegroup,this.sim_output.transitions));
%             transition_times = cellfun(@(z) z.time,transitions);
%             
%             
%             % state structure
%             time = (this.start_time:dt:(this.start_time+this.duration));
%             X_struct = struct('vehicles',zeros(1,numel(time)),'flow_vph',zeros(1,numel(time)-1));
%             X = repmat(X_struct,1,numel(lanegroup_ids));
%             
%             for k=2:numel(time)
%                 
%                 trans_ind = transition_times>=time(k-1) & transition_times<time(k);
%                 
%                 % leave events
%                 from = cellfun(@(z) double(z.from_lanegroup) , transitions(trans_ind));
%                 unique_from = unique(from(~isnan(from)));
%                 for i = 1:numel(unique_from)
%                     lg_ind = unique_from(i)==lanegroup_ids;
%                     leave_vehicles = sum(from==unique_from(i));
%                     X(lg_ind).vehicles(k) = X(lg_ind).vehicles(k) - leave_vehicles;
%                     X(lg_ind).flow_vph(k-1) = leave_vehicles * 3600/dt;
%                 end
%                 
%                 % enter events
%                 to = cellfun(@(z) double(z.to_lanegroup) , transitions(trans_ind));
%                 unique_to = unique(to(~isnan(to)));
%                 for i = 1:numel(unique_to)
%                     lg_ind = unique_to(i)==lanegroup_ids;
%                     enter_vehicles = sum(to==unique_to(i));
%                     X(lg_ind).vehicles(k) = X(lg_ind).vehicles(k) + enter_vehicles;
%                 end
%                 
%                 % initialize next k
%                 if k<numel(time)
%                     for i = 1:numel(lanegroup_ids)
%                         X(i).vehicles(k+1) = X(i).vehicles(k);
%                     end
%                 end
%                 
%             end
%             
%         end
        
    end
    
    methods(Access=private)
        
        function [this] = load_vehicle_events(this,time_period)
            
            this.sim_output.transitions = [];
            
            if nargin<2
                time_period = [-inf inf];
            end
            
            events_outputs = [];
            output_data = this.api.get_output_data();
            if ~output_data.isEmpty()
                it = output_data.iterator;
                while(it.hasNext)
                    output = it.next;
                    if strcmp(output.getClass,'class output.EventsVehicle')
                        events_outputs = [events_outputs output];
                    end
                end
            end
            clear output_data
            
            
            actuator_outputs = [];
            
            
            
            % get otm events
%             files.vehicle_events = OTM.find_with('_vehicle_events_',this.api.get_outputs);
%             files.actuator = OTM.find_with('_actuator_',this.api.get_outputs);
            
            % load transitions
            transitions = [ OTM.load_vehicle_transitions(events_outputs,time_period) ...
                %                             OTM.load_actuator_transitions(files,time_period) ...
                ];
            
            [~,ind] = sort(cellfun(@(z)z.time,transitions));
            this.sim_output.transitions = transitions(ind);
            
        end
        
        function [lanegroups]=load_lanegroups(this)
            
            filename = OTM.find_with('_lanegroups.txt',this.otm_output_files);
            
            fid=fopen(filename{1});
            lg_id=[];
            lk_id=[];
            lg_lanes=[];
            while 1
                tline = fgetl(fid);
                if ~ischar(tline), break, end
                s = split(tline);
                lg_id(end+1) = str2double(s{1});
                lk_id(end+1) = str2double(s{2});
                lg_lanes{end+1} = str2double(split(s{3}(2:end-1),','));
            end
            fclose(fid);
            
            lanegroups = table2struct(table(lg_id',lk_id',lg_lanes',...
                'VariableNames',{'id' 'link_id' 'lanes'}));
            
        end
        
    end
    
    methods(Access=private,Static)
        
        function [X] =  load_vehicle_class(filename)
            X = [];
            if isempty(filename)
                return
            end
            C = load(filename{1});
            X = C(:,2:3);
        end
        
        function [X] =  load_vehicle_travel_time(filename)
            X = [];
            if isempty(filename)
                return
            end
            C = load(filename{1});
            vehicle_ids = unique(C(:,2));
            travel_times = nan(numel(vehicle_ids),1);
            for i=1:numel(vehicle_ids)
                ind = find(C(:,2)==vehicle_ids(i));
                if numel(ind)==2
                    travel_times(i) = diff(C(ind,1));
                end
            end
            X = [vehicle_ids,travel_times];
        end
        
        function [transitions] =  load_vehicle_transitions(outputs,time_period)
            
            transitions = {};
            
            if nargin<3
                time_period = [-inf inf];
            end
            
            for k=1:numel(outputs)
                events = outputs(k).get_events();
                
                for i=1:events.size()
                    event = events.get(i-1);
                    if event.timestamp<time_period(1)
                        continue
                    end
                    if event.timestamp>time_period(2)
                        break
                    end
                    transitions{end+1} = VehicleEvent(event.timestamp,event.get_vehicle_id(),event.from_queue_id(),event.to_queue_id());
                end
                
            end

        end
        
        function [transitions] =  load_actuator_transitions(files,time_period)
            
            transitions = {}; % repmat(SignalEvent(nan),1,0);
            
            if ~isfield(files,'actuator_files') || isempty(files.actuator_files)
                return
            end
            
            if nargin<3
                time_period = [-inf inf];
            end
            
            for i = 1:numel(files.actuator_files)
                
                fid = fopen(files.actuator_files{i});
                
                [~,name]=fileparts(files.actuator_files{i});
                sp = split(name,'_');
                signal_id = uint32(str2double(sp{3}));
                clear sp name
                
                while 1
                    tline = fgetl(fid);
                    if ~ischar(tline), break, end
                    items = split(tline);
                    if numel(items)~=3
                        disp('asdf')
                    end
                    
                    time = str2double(items{1});
                    if time<time_period(1)
                        continue
                    end
                    
                    if time>time_period(2)
                        break
                    end
                    
                    transitions{end+1} = SignalEvent(time,signal_id,items(2:end));
                    
                end
                fclose(fid);
                
                
            end
            
        end
        
        function [scale]=compute_scaling_factor()
            
            %             % compute scaling factor
            %             all_lengths = arrayfun(@(z) z.ATTRIBUTE.length,x.scenario.network.links.link);
            %             [~,ind] = sort(all_lengths);
            %             ind = ind(end-9:end);
            %             for i=1:10
            %                 link = x.scenario.network.links.link(ind(i));
            %                 scale(i) = compute_euclidean_length(link) / link.ATTRIBUTE.length;
            %             end
            %             scale = mean(scale);
            
            
        end
        
        
        function [X] = find_with(str,java_list)
            X = {};
            for i=0:java_list.size()-1
                if ~isempty(strfind(java_list.get(i),str))
                    X{end+1} = java_list.get(i);
                end
            end
        end
        
    end
    
end

