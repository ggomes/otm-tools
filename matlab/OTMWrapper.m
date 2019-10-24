classdef OTMWrapper < handle
    
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
        function [this] = OTMWrapper(configfile,validate)
            
            if(nargin<2)
                validate = true;
            end
            this.lanewidth = 3;
            this.configfile = configfile;
            import api.OTM
            this.api = OTM(configfile,validate,false);
            this.sim_output = [];
        end
        
        % display the network
        function show_network(this,lanewidth)
            
            if nargin>=2
                this.lanewidth = lanewidth;
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
            links = values(Java2Matlab(this.api.scenario.get_links));
            drawLinks(1:numel(links)) = DrawLink();
            for i=1:numel(links)
                link = links{i};
                drawLinks(i) = DrawLink(link);
                drawLinks(i).draw(link,link.lanegroups,this.lanewidth);
                for j=1:numel(link.lanegroups)
                    lg = drawLinks(i).lanegroups(j);
                    this.laneGroupMap(lg.id) = lg;
                end
            end
            axis('equal')
            
            % signal map
            %             this.signalMap = containers.Map('KeyType','uint32','ValueType','any');
            
            % create the signals
            %             actuators = this.api.get_actuators;
            %             for i = 0:actuators.size()-1
            %                 actuator = actuators.get(i);
            %                 if ~strcmp(actuator.type,'signal')
            %                     continue
            %                 end
            %                 this.signalMap(actuator.id) = DrawSignal(this,actuator);
            %             end
            
        end
        
        function T = get_link_table(this)
            val = values(this.get_links);
            T = struct2table([val{:}]);
            T = removevars(T,{'road_geom','shape','lanegroups'});
        end
        
        %         % run an animation
        %         function [] = animate(this,time_period)
        %
        %             if nargin<2
        %                 time_period = [-inf inf];
        %             end
        %
        %             if isempty(this.sim_output)
        %                 this.load_all_events(time_period);
        %             end
        %
        %             % show the network
        %             if isempty(this.fig) || ~isvalid(this.fig)
        %                 this.show_network()
        %             end
        %
        %             vmap = containers.Map('KeyType','uint32','ValueType','any');
        %             h = textpos(0.85,0.95,0,'---',10,gca);
        %
        %             for i=1:numel(this.sim_output.transitions)
        %
        %                 pause(0.05)
        %
        %                 % take first transition
        %                 t = this.sim_output.transitions{i};
        %                 %                 transitions{i} = {};
        %
        %                 h.String = sprintf('%.1f',t.time);
        %
        %                 switch class(t)
        %
        %                     case 'SignalEvent'
        %                         signal = this.signalMap(t.signal);
        %                         signal.set_phase_color(t.phase,t.color);
        %
        %                     case 'VehicleEvent'
        %
        %                         if vmap.isKey(t.vehicle)
        %                             vehicle = vmap(t.vehicle);
        %                         else
        %                             vehicle = Vehicle(t.vehicle);
        %                             vmap(t.vehicle) = vehicle;
        %                         end
        %
        %                         % remove vehicle from lanegroup
        %                         if ~isnan(t.from_lanegroup)
        %                             lanegroup = this.laneGroupMap(t.from_lanegroup);
        %                             lanegroup.remove_vehicle_from_queue(vehicle,t.from_queue);
        %                         end
        %
        %                         % add vehicle to lanegroup
        %                         if ~isnan(t.to_lanegroup)
        %                             lanegroup = this.laneGroupMap(t.to_lanegroup);
        %                             lanegroup.add_vehicle_to_queue(vehicle,t.to_queue);
        %                         else
        %                             % this vehicle has been removed from the network
        %                             delete(vehicle.myPatch)
        %                             remove(vmap,vehicle.id);
        %                             clear vehicle
        %                         end
        %                 end
        %
        %             end
        %         end
        
        % run a simulation
        function [] = run_simple(this,start_time,duration,request_links,request_dt)
            
            this.start_time = start_time;
            this.duration = duration;
            
            if nargin>3
                link_ids = java.util.ArrayList;
                for i=1:numel(request_links)
                    link_ids.add(java.lang.Long(request_links(i)));
                end
                this.api.output.request_links_flow([],link_ids, java.lang.Float(request_dt));
                this.api.output.request_links_veh([],link_ids, java.lang.Float(request_dt));
            end
            
            % run the simulation
            this.api.run( uint32(start_time), uint32(duration));
            
        end
        
        %         % run a simulation
        %         function [] = run_simulation(this,prefix,output_requests_file,output_folder,duration,start_time)
        %
        %             if nargin<6
        %                 start_time = 0;
        %             end
        %
        %             if nargin<7
        %                 sim_dt = 5;
        %             end
        %
        %             this.start_time = start_time;
        %             this.duration = duration;
        %
        %             % run the simulation
        %             this.api.run( ...
        %                 prefix, ...
        %                 output_requests_file, ...
        %                 output_folder, ...
        %                 uint32(start_time), ...
        %                 uint32(duration));
        %
        %         end
        
        %         function paths = get_path_travel_times(this)
        %
        %             if ~isfield(this.sim_output,'transitions') || isempty(this.sim_output.transitions)
        %                 this.load_all_events
        %             end
        %
        %             % load lanegroups
        %             lanegroups = this.load_lanegroups;
        %             lanegroup_ids = [lanegroups.id];
        %
        %             % keep vehicle transitions
        %             transitions = this.sim_output.transitions(cellfun(@(z) isa(z,'VehicleEvent'),this.sim_output.transitions));
        %
        %             vehicle_ids = cellfun(@(z) z.vehicle , transitions);
        %
        %             unique_vehicle_ids = unique(vehicle_ids);
        %
        %             path_struct = struct('link_ids',[],'departure_arrival_times',[]);
        %             paths = repmat(path_struct,1,0);
        %             for i=1:numel(unique_vehicle_ids)
        %                 v_trans = transitions(unique_vehicle_ids(i)==vehicle_ids);
        %
        %                 % not a complete trajectory
        %                 if ~isempty(v_trans{1}.from_queue) || ~isempty(v_trans{end}.to_queue)
        %                     continue
        %                 end
        %
        %                 link_ids = cellfun( @(z) lanegroups(z.to_lanegroup==lanegroup_ids).link_id  ,v_trans(1:end-1));
        %                 link_ids([1 diff(link_ids)]==0)=[];
        %
        %                 path_ind = arrayfun(@(z) numel(z.link_ids)==numel(link_ids) && all(z.link_ids==link_ids) , paths );
        %                 if any(path_ind)
        %                     paths(path_ind).departure_arrival_times(end+1,:) = [v_trans{1}.time v_trans{end}.time];
        %                 else
        %                     p = path_struct;
        %                     p.link_ids = link_ids;
        %                     p.departure_arrival_times = [v_trans{1}.time v_trans{end}.time];
        %                     paths(end+1) = p;
        %                 end
        %
        %             end
        %
        %         end
        
        % Get scenario information.
        function [X] = get_info(this)
            X = Java2Matlab(this.api.scenario.get_info);
        end
        
        function [X] = get_models(this)
            X = Java2Matlab(this.api.scenario.get_models);
        end
        
        % Get the total number of commodities in the scenario.
        function X = get_num_commodities(this)
            X = Java2Matlab(this.api.scenario.get_num_commodities);
        end
        
        % Get information for all commodities in the scenario.
        function X = get_commodities(this)
            X = Java2Matlab(this.api.scenario.get_commodities);
        end
        
        % Get information for a specific commodity.
        function X = get_commodity_with_id(this, id)
            X = Java2Matlab(this.api.scenario.get_commodity_with_id(id));
        end
        
        function X = get_commodity_ids(this)
            X = Java2Matlab(this.api.scenario.get_commodity_ids);
        end
        
        % Get the total number of subnetworks in the scenario.
        function X = get_num_subnetworks(this)
            X = Java2Matlab(Java2Matlab(this.api.scenario.get_num_subnetworks));
        end
        
        % Get list of all subnetwork ids
        function X = get_subnetwork_ids(this)
            X = Java2Matlab(this.api.scenario.get_subnetwork_ids);
        end
        
        % Get list of all path ids (ie linear subnetworks that begin at a source)
        function X = get_path_ids(this)
            X = Java2Matlab(this.api.scenario.get_path_ids);
        end
        
        % Get information for all subnetworks in the scenario.
        function X = get_subnetworks(this)
            X = Java2Matlab(this.api.scenario.get_subnetworks);
        end
        
        % Get information for a specific subnetwork.
        function X = get_subnetwork_with_id(this, id)
            X = Java2Matlab(this.api.scenario.get_subnetwork_with_id(id));
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % network
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        % Get the total number of links in the scenario.
        function X = get_num_links(this)
            X = Java2Matlab(this.api.scenario.get_num_links);
        end
        % Get the total number of nodes in the scenario.
        function X = get_num_nodes(this)
            X = Java2Matlab(this.api.scenario.get_num_nodes);
        end
        function X = get_node_ids(this)
            X = Java2Matlab(this.api.scenario.get_node_ids);
        end
        % Returns a list where every entry is a list with entries [link_id,start_node,end_node]
        function X = get_link_connectivity(this)
            X = Java2Matlab(this.api.scenario.get_link_connectivity);
        end
        % Get information for all links in the scenario.
        function X = get_links(this)
            X = Java2Matlab(this.api.scenario.get_links);
        end
        
        % Get information for a specific link.
        function X = get_link_with_id(this, id)
            X = Java2Matlab(this.api.scenario.get_link_with_id(id));
        end
        
        % Get the list of ids of all links in the network.
        function X = get_link_ids(this)
            X = Java2Matlab(this.api.scenario.get_link_ids);
        end
        
        % Get ids for all source links.
        function X = get_source_link_ids(this)
            X = Java2Matlab(this.api.scenario.get_source_link_ids);
        end
        function X = get_in_lanegroups_for_road_connection(this,rcid)
            X = Java2Matlab(this.api.scenario.get_in_lanegroups_for_road_connection(rcid));
        end
        
        function X = get_out_lanegroups_for_road_connection(this,rcid)
            X = Java2Matlab(this.api.scenario.get_out_lanegroups_for_road_connection(rcid));
        end
        
        function X = get_link2lgs(this)
            X = Java2Matlab(this.api.scenario.get_link2lgs);
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % demands / splits
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        % Get information for all demands in the scenario.
        function X = get_demands(this)
            X = Java2Matlab(this.api.scenario.get_demands);
        end
        
        % Get information for a specific demand.
        function X = get_demand_with_ids(this,typestr,link_or_path_id,commodity_id)
            X = Java2Matlab(this.api.scenario.get_demand_with_ids(typestr,link_or_path_id,commodity_id));
        end
        
        
        function clear_all_demands(this)
            this.api.scenario.clear_all_demands;
        end
        
        % Set or override a demand value for a path.
        % Use this method to set a demand profile of a given commodity on a given path.
        % The profile is a piecewise continuous function starting a time "start_time" and with
        % sample time "dt". The values are given by the "values" array. The value before
        % before "start_time" is zero, and the last value in the array is held into positive
        % infinity time.
        % This method will override any existing demands for that commodity and path.
        
        function set_demand_on_path_in_vph(this,path_id,commodity_id,start_time,dt,values)
            this.api.scenario.set_demand_on_path_in_vph(path_id,commodity_id,start_time,dt,values);
        end
        
        function X = get_od_info(this)
            X = Java2Matlab(this.api.scenario.get_od_info);
        end
        
        
        function X = get_total_trips(this)
            X = Java2Matlab(this.api.scenario.get_total_trips);
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % sensors
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        % Get the total number of sensors in the scenario.
        function X = get_num_sensors(this)
            X = Java2Matlab(this.api.scenario.get_num_sensors);
        end
        % Get information for all sensors in the scenario.
        function X = get_sensors(this)
            X = Java2Matlab(this.api.scenario.get_sensors);
        end
        
        % Get information for a specific sensor.
        
        function X = get_sensor_with_id(this,id)
            X = Java2Matlab(this.api.scenario.get_sensor_with_id(id));
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % controllers
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        % Get the total number of controllers in the scenario.
        function X = get_num_controllers(this)
            X = Java2Matlab(this.api.scenario.get_num_controllers);
        end
        
        % Get information for all controllers in the scenario.
        function X = get_controllers(this)
            X = Java2Matlab(this.api.scenario.get_controllers);
        end
        % Get information for a specific myController.
        function X = get_controller_with_id(this, id)
            X = Java2Matlab(this.api.scenario.get_controller_with_id(id));
        end
        
        function X = get_actual_controller_with_id(this,id)
            X = Java2Matlab(this.api.scenario.get_actual_controller_with_id(id));
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % actuators
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        % Get the total number of actuators in the scenario.
        function X = get_num_actuators(this)
            X = Java2Matlab(this.api.scenario.get_num_actuators);
        end
        % Get information for all actuators in the scenario.
        function X = get_actuators(this)
            X = Java2Matlab(this.api.scenario.get_actuators);
        end
        
        % Get information for a specific actuator.
        function X = get_actuator_with_id(this,id)
            X = Java2Matlab(this.api.scenario.get_actuator_with_id(id));
        end

        function [X] = get_state_trajectory(this)
            
            output_data = this.api.output.get_data();
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
                            X.flows_vph(xind,:) = diff(Java2Matlab(z.get_values))*3600/double(z.get_dt);
                        case 'output.LinkVehicles'
                            X.vehs(xind,:) = Java2Matlab(z.get_values);
                    end
                    
                end
                
            end
            
            for i=1:numel(X.link_ids)
                link_id = X.link_ids(i);
                link_info = this.api.scenario.get_link_with_id(link_id);
                
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
        
        %         function [this] = load_vehicle_events(this,time_period)
        %
        %             this.sim_output.transitions = [];
        %
        %             if nargin<2
        %                 time_period = [-inf inf];
        %             end
        %
        %             events_outputs = [];
        %             output_data = this.api.get_output_data();
        %             if ~output_data.isEmpty()
        %                 it = output_data.iterator;
        %                 while(it.hasNext)
        %                     output = it.next;
        %                     if strcmp(output.getClass,'class output.EventsVehicle')
        %                         events_outputs = [events_outputs output];
        %                     end
        %                 end
        %             end
        %             clear output_data
        %
        %
        %             actuator_outputs = [];
        %
        %
        %
        %             % get otm events
        % %             files.vehicle_events = OTM.find_with('_vehicle_events_',this.api.get_outputs);
        % %             files.actuator = OTM.find_with('_actuator_',this.api.get_outputs);
        %
        %             % load transitions
        %             transitions = [ OTM.load_vehicle_transitions(events_outputs,time_period) ...
        %                 %                             OTM.load_actuator_transitions(files,time_period) ...
        %                 ];
        %
        %             [~,ind] = sort(cellfun(@(z)z.time,transitions));
        %             this.sim_output.transitions = transitions(ind);
        %
        %         end
        
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
        
        %         function [X] =  load_vehicle_class(filename)
        %             X = [];
        %             if isempty(filename)
        %                 return
        %             end
        %             C = load(filename{1});
        %             X = C(:,2:3);
        %         end
        
        %         function [X] =  load_vehicle_travel_time(filename)
        %             X = [];
        %             if isempty(filename)
        %                 return
        %             end
        %             C = load(filename{1});
        %             vehicle_ids = unique(C(:,2));
        %             travel_times = nan(numel(vehicle_ids),1);
        %             for i=1:numel(vehicle_ids)
        %                 ind = find(C(:,2)==vehicle_ids(i));
        %                 if numel(ind)==2
        %                     travel_times(i) = diff(C(ind,1));
        %                 end
        %             end
        %             X = [vehicle_ids,travel_times];
        %         end
        
        %         function [transitions] =  load_vehicle_transitions(outputs,time_period)
        %
        %             transitions = {};
        %
        %             if nargin<3
        %                 time_period = [-inf inf];
        %             end
        %
        %             for k=1:numel(outputs)
        %                 events = outputs(k).get_events();
        %
        %                 for i=1:events.size()
        %                     event = events.get(i-1);
        %                     if event.timestamp<time_period(1)
        %                         continue
        %                     end
        %                     if event.timestamp>time_period(2)
        %                         break
        %                     end
        %                     transitions{end+1} = VehicleEvent(event.timestamp,event.get_vehicle_id(),event.from_queue_id(),event.to_queue_id());
        %                 end
        %
        %             end
        %
        %         end
        
        %         function [transitions] =  load_actuator_transitions(files,time_period)
        %
        %             transitions = {}; % repmat(SignalEvent(nan),1,0);
        %
        %             if ~isfield(files,'actuator_files') || isempty(files.actuator_files)
        %                 return
        %             end
        %
        %             if nargin<3
        %                 time_period = [-inf inf];
        %             end
        %
        %             for i = 1:numel(files.actuator_files)
        %
        %                 fid = fopen(files.actuator_files{i});
        %
        %                 [~,name]=fileparts(files.actuator_files{i});
        %                 sp = split(name,'_');
        %                 signal_id = uint32(str2double(sp{3}));
        %                 clear sp name
        %
        %                 while 1
        %                     tline = fgetl(fid);
        %                     if ~ischar(tline), break, end
        %                     items = split(tline);
        %                     if numel(items)~=3
        %                         disp('asdf')
        %                     end
        %
        %                     time = str2double(items{1});
        %                     if time<time_period(1)
        %                         continue
        %                     end
        %
        %                     if time>time_period(2)
        %                         break
        %                     end
        %
        %                     transitions{end+1} = SignalEvent(time,signal_id,items(2:end));
        %
        %                 end
        %                 fclose(fid);
        %
        %
        %             end
        %
        %         end
        
        %         function [scale]=compute_scaling_factor()
        %             all_lengths = arrayfun(@(z) z.ATTRIBUTE.length,x.scenario.network.links.link);
        %             [~,ind] = sort(all_lengths);
        %             ind = ind(end-9:end);
        %             for i=1:10
        %                 link = x.scenario.network.links.link(ind(i));
        %                 scale(i) = compute_euclidean_length(link) / link.ATTRIBUTE.length;
        %             end
        %             scale = mean(scale);
        %         end
        
        
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

