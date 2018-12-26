classdef Scenario < handle
    
    properties (Access = public)
        scenario
        link_id_begin_end
    end
    
    methods (Access = public)
        
        function [this] = Scenario(configfile)
            
            if nargin>0
                this.load(configfile,false,true);
            end
            
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %% load/save/clone
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        function x = isempty(this)
            x = isempty(this.link_id_begin_end);
        end
        
        function [this,success]=load(this,configfile,validate,silent)
            % load scenario from an xml file.
            
            if(nargin<3)
                validate = true;
            end
            
            if(nargin<4)
                silent = false;
            end
            
            if(~exist(configfile,'file'))
                error('file not found')
            end
            
            success = false;
            
            % validate
            if(validate)
                root = fileparts(fileparts(fileparts(mfilename('fullpath'))));
                xml_validator = fullfile(root,'lib','xsd11-validator.jar');
                schemafile = fullfile(root,'src','main','resources','beats.xsd');
                if ~silent
                    disp(['Validating ' configfile])
                end
                [status,result] = system(['java -jar "' xml_validator '" -sf "' schemafile '" -if "' configfile '"']);
                
                if(~isempty(result) || status~=0 )
                    disp('Input file not valid')
                    disp(result)
                    return
                end
            end
            
            if ~silent
                disp(['Loading ' configfile])
            end
            
            z = xml2struct(fileread(configfile));
            this.scenario = z.scenario;
            clear z;
            
            % populate link_inputs and link_outputs
            this.generate_link_id_begin_end();
            
            success = true;
            
        end
        
        % generate link/node map ..........................................
        function [] = generate_link_id_begin_end(this)
            numlinks = numel(this.scenario.network.links.link);
            this.link_id_begin_end = nan(numlinks,3);
            for i=1:numlinks
                L=this.scenario.network.links.link(i);
                this.link_id_begin_end(i,:) = [  L.ATTRIBUTE.id ...
                    L.ATTRIBUTE.start_node_id ...
                    L.ATTRIBUTE.end_node_id];
            end
        end
        
        function [this] = save(this,outfile)
            
            
            disp(['Saving ' outfile])
            
            % copy scenario
            scenario = this.scenario; %#ok<*PROPLC>
            
            % comma format subnetworks
            if isfield(scenario,'subnetworks') && isfield(scenario.subnetworks,'subnetwork')
                for i=1:numel(scenario.subnetworks.subnetwork)
                    if ~ischar(scenario.subnetworks.subnetwork(i).CONTENT)
                        scenario.subnetworks.subnetwork(i).CONTENT = Scenario.writecommaformat(scenario.subnetworks.subnetwork(i).CONTENT,'%d');
                    end
                end
            end
            
            % comma format commodities
            if isfield(scenario,'commodities') && isfield(scenario.commodities,'commodity')
                for i=1:numel(scenario.commodities.commodity)
                    if isfield(scenario.commodities.commodity(i).ATTRIBUTE,'subnetworks')
                        if ~ischar(scenario.commodities.commodity(i).ATTRIBUTE.subnetworks)
                            scenario.commodities.commodity(i).ATTRIBUTE.subnetworks = Scenario.writecommaformat(scenario.commodities.commodity(i).ATTRIBUTE.subnetworks,'%d');
                        end
                    end
                end
            end
            
            % comma format phases
            if isfield(scenario,'actuators') && isfield(scenario.actuators,'actuator')
                for i=1:numel(scenario.actuators.actuator)
                    if isfield(scenario.actuators.actuator(i),'signal') && isfield(scenario.actuators.actuator(i).signal,'phase')
                        for j=1:numel(scenario.actuators.actuator(i).signal.phase)
                            if isfield(scenario.actuators.actuator(i).signal.phase(j).ATTRIBUTE,'roadconnection_ids')
                                if ~ischar(scenario.actuators.actuator(i).signal.phase(j).ATTRIBUTE.roadconnection_ids)
                                scenario.actuators.actuator(i).signal.phase(j).ATTRIBUTE.roadconnection_ids = ...
                                    Scenario.writecommaformat(scenario.actuators.actuator(i).signal.phase(j).ATTRIBUTE.roadconnection_ids,'%d');
                                
                                end
                            end
                        end
                    end
                end
            end
            
            % process pathfull
            if isfield(scenario,'commodities') && isfield(scenario.commodities,'commodity')
                for i=1:numel(scenario.commodities.commodity)
                    if isfield(scenario.commodities.commodity(i).ATTRIBUTE,'pathfull') & islogical(scenario.commodities.commodity(i).ATTRIBUTE.pathfull)
                        if scenario.commodities.commodity(i).ATTRIBUTE.pathfull
                            scenario.commodities.commodity(i).ATTRIBUTE.pathfull = 'true';
                        else
                            scenario.commodities.commodity(i).ATTRIBUTE.pathfull = 'false';
                        end
                    end
                end
            end
            
            % remove nans and empties from...
            
            %             % ... point.elevation, point.lat, point.lng
            %             scenario.NetworkSet.network = this.replace_nan_with(scenario.NetworkSet.network,{'position','point','ATTRIBUTE','elevation'},0);
            %             for j=1:length(scenario.NetworkSet.network.NodeList.node)
            %                 scenario.NetworkSet.network.NodeList.node(j) = ...
            %                     this.replace_nan_with(scenario.NetworkSet.network.NodeList.node(j),...
            %                     {'position','point','ATTRIBUTE','elevation'},0);
            %                 scenario.NetworkSet.network.NodeList.node(j) = ...
            %                     this.replace_empty_with(scenario.NetworkSet.network.NodeList.node(j),...
            %                     {'position','point','ATTRIBUTE','elevation'},0);
            %             end
            %             for j=1:length(scenario.NetworkSet.network.LinkList.link)
            %                 scenario.NetworkSet.network.LinkList.link(j) = ...
            %                     this.replace_nan_with(scenario.NetworkSet.network.LinkList.link(j),...
            %                     {'position','point','ATTRIBUTE','elevation'},0);
            %                 scenario.NetworkSet.network.LinkList.link(j) = ...
            %                     this.replace_empty_with(scenario.NetworkSet.network.LinkList.link(j),...
            %                     {'position','point','ATTRIBUTE','elevation'},0);
            %                 scenario.NetworkSet.network.LinkList.link(j) = ...
            %                     this.replace_nan_with(scenario.NetworkSet.network.LinkList.link(j),...
            %                     {'position','point','ATTRIBUTE','lat'},0);
            %                 scenario.NetworkSet.network.LinkList.link(j) = ...
            %                     this.replace_empty_with(scenario.NetworkSet.network.LinkList.link(j),...
            %                     {'position','point','ATTRIBUTE','lat'},0);
            %                 scenario.NetworkSet.network.LinkList.link(j) = ...
            %                     this.replace_nan_with(scenario.NetworkSet.network.LinkList.link(j),...
            %                     {'position','point','ATTRIBUTE','lng'},0);
            %                 scenario.NetworkSet.network.LinkList.link(j) = ...
            %                     this.replace_empty_with(scenario.NetworkSet.network.LinkList.link(j),...
            %                     {'position','point','ATTRIBUTE','lng'},0);
            %             end
            
            %             % set network position
            %             if(isfieldRecursive(scenario.NetworkSet.network,'position','point'))
            %                 scenario.NetworkSet.network.position.point(2:end)=[];
            %             else
            %                 points = repmat(struct('lat',nan,'lng',nan),1,length(scenario.NetworkSet.network.NodeList.node));
            %                 for j=1:length(scenario.NetworkSet.network.NodeList.node)
            %                     if(isfield(scenario.NetworkSet.network.NodeList.node(j),'position'))
            %                         p = scenario.NetworkSet.network.NodeList.node(j).position.point.ATTRIBUTE;
            %                         points(j).lat = p.lat;
            %                         points(j).lng = p.lng;
            %                     end
            %                 end
            %                 scenario.NetworkSet.network.position.point.ATTRIBUTE.elevation = 0;
            %                 scenario.NetworkSet.network.position.point.ATTRIBUTE.lat = mean([points.lat]);
            %                 scenario.NetworkSet.network.position.point.ATTRIBUTE.lng = mean([points.lng]);
            %             end
            
            %             % ... sensors
            %             if(this.has_sensors)
            %                 for i=1:length(scenario.SensorSet.sensor)
            %                     S = scenario.SensorSet.sensor(i);
            %                     S.ATTRIBUTE = this.remove_if_nan(S.ATTRIBUTE,{'health_status','lane_number'});
            %                     S = this.replace_nan_with(S,{'display_position','point','ATTRIBUTE','elevation'},0);
            %                     scenario.SensorSet.sensor(i)=S;
            %                 end
            %             end
            
            %             % ... jam densities
            %             if(this.has_fds)
            %                 for i=1:length(scenario.FundamentalDiagramSet.fundamentalDiagramProfile)
            %                     fd = scenario.FundamentalDiagramSet.fundamentalDiagramProfile(i);
            %                     for j=1:length(fd.fundamentalDiagram)
            %                         fd.fundamentalDiagram(j).ATTRIBUTE=this.remove_if_nan(fd.fundamentalDiagram(j).ATTRIBUTE,{'jam_density'});
            %                     end
            %                     scenario.FundamentalDiagramSet.fundamentalDiagramProfile(i) = fd;
            %                 end
            %             end
            
            %             % ... format demands
            %             if(this.has_demands)
            %                 for i=1:length(scenario.DemandSet.demandProfile)
            %                     dP = scenario.DemandSet.demandProfile(i);
            %                     if(isfield(dP,'demand'))
            %                         for j=1:length(dP.demand)
            %                             if(ischar(dP.demand(j).CONTENT))
            %                                 x = str2double(dP.demand(j).CONTENT);
            %                                 if(isnan(x))
            %                                     x=eval(['[' dP.demand(j).CONTENT ']']);
            %                                 end
            %                             else
            %                                 x = dP.demand(j).CONTENT;
            %                             end
            %                             scenario.DemandSet.demandProfile(i).demand(j).CONTENT = writecommaformat(x,precision.demands);
            %                         end
            %                     end
            %                 end
            %             end
            
            %             % ... format split ratios
            %             if(this.has_splits)
            %                 for i=1:length(scenario.SplitRatioSet.splitRatioProfile)
            %                     sr = scenario.SplitRatioSet.splitRatioProfile(i);
            %                     for j=1:length(sr.splitratio)
            %                         if(isfield(sr.splitratio(j),'CONTENT'))
            %                             if(ischar(sr.splitratio(j).CONTENT))
            %                                 x = str2double(sr.splitratio(j).CONTENT);
            %                                 if(isnan(x))
            %                                     x=eval(['[' sr.splitratio(j).CONTENT ']']);
            %                                 end
            %                             else
            %                                 x = sr.splitratio(j).CONTENT;
            %                             end
            %                             scenario.SplitRatioSet.splitRatioProfile(i).splitratio(j).CONTENT = writecommaformat(x,precision.splits);
            %                         end
            %                         if(isfield(sr,'concentrationParameters')) && (~isempty(sr.concentrationParameters))
            %                             if(isfield(sr.concentrationParameters(j),'CONTENT'))
            %                                 if(ischar(sr.splitratio(j).CONTENT))
            %                                     x = str2double(sr.concentrationParameters(j).CONTENT);
            %                                 else
            %                                     x = sr.concentrationParameters(j).CONTENT;
            %                                 end
            %                                 scenario.SplitRatioSet.splitRatioProfile(i).concentrationParameters(j).CONTENT = writecommaformat(x,precision.demands);
            %                             end
            %                         end
            %                     end
            %                 end
            %             end
            
            %             % add project_id and id to sets
            %             sets = {'NetworkSet','EventSet','ControllerSet'};
            %             for i=1:length(sets)
            %                 if(isfield(scenario,sets{i}))
            %                     if(~isfield(scenario.(sets{i}),'ATTRIBUTE'))
            %                         X = generate_mo(sets{i},true);
            %                         scenario.(sets{i}).ATTRIBUTE = X.ATTRIBUTE;
            %                         clear X
            %                     end
            %                     scenario.(sets{i}).ATTRIBUTE = this.default_to(scenario.(sets{i}).ATTRIBUTE,'project_id',0);
            %                     scenario.(sets{i}).ATTRIBUTE = this.default_to(scenario.(sets{i}).ATTRIBUTE,'id',0);
            %                 end
            %             end
            
            struct2xml(struct('scenario',scenario),outfile);
            clear scenario
            
            %%% POST PROCESSING %%%%%%%%%%%%%%%%%%%%%%%%%%%%
            
            %             fid_in = fopen(outfile,'r');
            %             fname = [num2str(round(rand*10000000000)) '.xml'];
            %             fid_out = fopen(fname,'w+');
            %             while 1
            %                 tline = fgetl(fid_in);
            %                 if ~ischar(tline), break, end
            %
            %                 % remove empty link references from sensors
            %                 if(~isempty(strfind(tline,'sensor')) && ~isempty(strfind(tline,'link_id=""')))
            %                     tline = strrep(tline,'link_id=""', '');
            %                 end
            %
            %                 % remove empty sensor reference from fd
            %                 if(~isempty(strfind(tline,'fundamentalDiagramProfile')) && ~isempty(strfind(tline,'sensor_id=""')))
            %                     tline = strrep(tline,'sensor_id=""', '');
            %                 end
            %
            %                 % remove empty positions
            %                 if(~isempty(strfind(tline,'<position/>')))
            %                     continue
            %                 end
            %
            %                 % remove empty shapes
            %                 if(~isempty(strfind(tline,'<shape/>')))
            %                     continue
            %                 end
            %
            %                 fprintf(fid_out,'%s\n',tline);
            %             end
            %             fclose(fid_in);
            %             fclose(fid_out);
            %             if ispc
            %                 system(['move ' fname ' "' outfile '"']);
            %             elseif isunix || ismac
            %                 system(['mv ' fname ' "' outfile '"']);
            %             end
            
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %% create
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        function [this] = add_node(this,id,pos)
            
            if ~isfield(this.scenario,'network')
                this.scenario.network = struct('nodes',[],'links',[],'roadparams',[],'roadconnections',[]);
            end
            
            if ismember(id,this.get_node_ids)
                error('existing id')
            end
            
            if nargin<3
                x = 0;
                y = 0;
            else
                x = pos(1);
                y = pos(2);
            end
            
            this_node = struct('ATTRIBUTE',struct('id',id,'x',x,'y',y));
            
            if isempty(this.scenario.network.nodes)
                this.scenario.network.nodes.node = this_node;
            else
                this.scenario.network.nodes.node(end+1) = this_node;
            end
            
        end
        
        function [this] = add_roadparam(this,id,capacity,speed,jam_density)
            
            if ~isfield(this.scenario,'network')
                this.scenario.network = struct('nodes',[],'links',[],'roadparams',[],'roadconnections',[]);
            end
            
            if ismember(id,this.get_roadparam_ids)
                error('existing id')
            end
            
            this_roadparam = struct('ATTRIBUTE',struct('id',id,'capacity',capacity, ...
                'speed',speed,'jam_density',jam_density));
            
            if isempty(this.scenario.network.roadparams)
                this.scenario.network.roadparams.roadparam = this_roadparam;
            else
                this.scenario.network.roadparams.roadparam(end+1) = this_roadparam;
            end
            
        end
        
        function [this] = add_link(this,id,start_node,end_node,full_lanes,llength,roadparam)
            
            if ~isfield(this.scenario,'network')
                this.scenario.network = struct('nodes',[],'links',[],'roadparams',[],'roadconnections',[]);
            end
            
            if ismember(id,this.get_link_ids)
                error('existing id')
            end
            
            if ~ismember(roadparam,this.get_roadparam_ids)
                error('bad roadparam')
            end
            
            if ~all(ismember([start_node end_node],this.get_node_ids))
                error('bad node id')
            end
            
            this_link = struct('ATTRIBUTE',struct('id',id,'full_lanes',full_lanes, ...
                'length',llength,'start_node_id',start_node,'end_node_id',end_node,...
                'roadparam',roadparam));
            
            if isempty(this.scenario.network.links)
                this.scenario.network.links.link = this_link;
            else
                this.scenario.network.links.link(end+1) = this_link;
            end
            
            this.generate_link_id_begin_end
            
        end
        
        function [this] = add_road_connection(this,id,inlink,inlanes,outlink,outlanes)
            
            if ~isfield(this.scenario,'network')
                this.scenario.network = struct('nodes',[],'links',[],'roadparams',[],'roadconnections',[]);
            end
            
            if ismember(id,this.get_roadconnection_ids)
                error('existing id')
            end
            
            if ~all(ismember([inlink outlink],this.get_link_ids))
                error('bad roadparam')
            end
            
            this_rc = struct('ATTRIBUTE',struct('id',id,...
                'in_link',inlink,...
                'in_link_lanes',sprintf('%d#%d',inlanes(1),inlanes(2)),...
                'out_link',outlink,...
                'out_link_lanes',sprintf('%d#%d',outlanes(1),outlanes(2))))
            
            if isempty(this.scenario.network.roadconnections)
                this.scenario.network.roadconnections.roadconnection = this_rc;
            else
                this.scenario.network.roadconnections.roadconnection(end+1) = this_rc;
            end
              
        end
        
        function [this] = set_model(this,model_name,links,params)

            if ~isfield(this.scenario,'model')
                this.scenario.model = [];
            end
            
            if ~all(ismember(links,this.get_link_ids))
                error('bad link ids')
            end
                 
            this_model = struct('ATTRIBUTE',[],'CONTENT',writecommaformat(links,'%d'));
            
            if nargin>3
                this_model.ATTRIBUTE = params;
            end
            
            this.scenario.model.(model_name) = this_model;
            
        end
        
        function [this] = add_commodity(this,id,name,pathfull,subnetworks)
            
            if ~isfield(this.scenario,'commodities')
                this.scenario.commodities = [];
            end
            
            if ~all(ismember(subnetworks,this.get_subnetwork_ids))
                error('bad subnetwork id')
            end
  
            if nargin<5
                this_comm = struct('ATTRIBUTE',struct('id',id,'name',name,'pathfull',pathfull));
            else
                this_comm = struct('ATTRIBUTE',struct('id',id,'name',name,'pathfull',pathfull,'subnetworks',writecommaformat(subnetworks,'%d')));
            end
            
            if isempty(this.scenario.commodities)
                this.scenario.commodities.commodity = this_comm;
            else
                this.scenario.commodities.commodity(end+1) = this_comm;
            end
            
        end

        function [this] = add_subnetwork(this,id,links)
            
            if ~isfield(this.scenario,'subnetworks')
                this.scenario.subnetworks = [];
            end
            
            if ismember(id,this.get_subnetwork_ids)
                error('existing id')
            end
            
            this_subnetwork = struct('ATTRIBUTE',struct('id',id),...
                'CONTENT',writecommaformat(links,'%d'));
            
            if isempty(this.scenario.subnetworks)
                this.scenario.subnetworks.subnetwork = this_subnetwork;
            else
                this.scenario.subnetworks.subnetwork(end+1) = this_subnetwork;
            end
            
        end
        
  
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %% get
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        % LINKS
        
        function X = num_links(this)
            if isempty(this.scenario.network.links)
                X = 0;
            else
                X = numel(this.scenario.network.links.link);
            end
        end
        
        function X = get_link_ids(this)
            if isempty(this.scenario.network.links)
                X = [];
            else
                X = arrayfun( @(z) z.ATTRIBUTE.id , this.scenario.network.links.link);
            end
        end
        
        function X = get_links(this,link_ids)
            all_link_ids = this.get_link_ids;
            if ~all(ismember(link_ids,all_link_ids))
                error('I dont recognize all of these ids')
            end
            X = this.scenario.network.links.link(index_into(link_ids,all_link_ids));
        end
        
        function X = get_link_lengths_meters(this,link_ids)
            X = arrayfun(@(x) x.ATTRIBUTE.length,this.get_links(link_ids));
        end
        
        function X = get_link_connections(this,link_id)
            X = struct( 'start_node', nan , 'end_node',nan,...
                'up_links',[],'dn_links',[]);
            ind = this.link_id_begin_end(:,1)==link_id;
            
            if ~any(ind)
                return
            end
            
            X.start_node = this.link_id_begin_end(ind,2);
            X.end_node = this.link_id_begin_end(ind,3);
            
            ind = X.start_node==this.link_id_begin_end(:,3);
            X.up_links = this.link_id_begin_end(ind,1);
            
            ind = X.end_node==this.link_id_begin_end(:,2);
            X.dn_links = this.link_id_begin_end(ind,1);
            
        end
        
        function X = get_link_types(this)
            X = cell(1,numel(this.scenario.network.links.link));
            for i=1:numel(this.scenario.network.links.link)
                Z = this.scenario.network.links.link(i).ATTRIBUTE;
                if isfield(Z,'road_type')
                    X{i} = Z.road_type;
                end
            end
        end
        
        function X = get_link_type(this,link_ids)
            all_link_ids = this.get_link_ids;
            if ~all(ismember(link_ids,all_link_ids))
                error('I dont recognize all of these ids')
            end
            links_types = this.get_link_types;
            X = links_types(index_into(link_ids,all_link_ids));
        end
        
        function X = is_source(this)
            X = arrayfun(@(z) isempty(z.in_links), this.get_node_connections(this.link_id_begin_end(:,2)));
        end
        
        function X = is_sink(this)
            X = arrayfun(@(z) isempty(z.out_links), this.get_node_connections(this.link_id_begin_end(:,3)));
        end
        
        % NODES
        
        function X = num_nodes(this)
            if isempty(this.scenario.network.nodes)
                X = 0;
            else
                X = numel(this.scenario.network.nodes.node);
            end
        end
        
        function X = get_node_ids(this)
            if isempty(this.scenario.network.nodes)
                X = [];
            else
                X = arrayfun( @(z) z.ATTRIBUTE.id , this.scenario.network.nodes.node);
            end
        end
        
        function X = get_nodes(this,node_ids)
            all_node_ids = this.get_node_ids;
            if ~all(ismember(node_ids,all_node_ids))
                error('I dont recognize all of these ids')
            end
            X = this.scenario.network.nodes.node(index_into(node_ids,all_node_ids));
        end
        
        function X = get_node_connections(this,node_ids)
            all_node_ids = this.get_node_ids;
            X = repmat(struct('node_id',nan,'in_links',[],'out_links',[]),1,numel(node_ids));
            for i=1:numel(node_ids)
                node_id = node_ids(i);
                X(i).node_id = node_id;
                if ~any(X(i).node_id==all_node_ids)
                    continue
                end
                X(i).out_links = this.link_id_begin_end(this.link_id_begin_end(:,2)==node_id,1);
                X(i).in_links  = this.link_id_begin_end(this.link_id_begin_end(:,3)==node_id,1);
            end
            
        end
        
        % ROAD CONNECTIONS
        
        function X = get_roadconnection_ids(this)
            if isempty(this.scenario.network.roadconnections)
                X = [];
            else
                X = arrayfun( @(z) z.ATTRIBUTE.id , this.scenario.network.roadconnections.roadconnection);
            end
        end
        
        function X = get_roadconnections(this,rc_ids)
            all_rc_ids = this.get_roadconnection_ids;
            if ~all(ismember(rc_ids,all_rc_ids))
                error('I dont recognize all of these ids')
            end
            X = this.scenario.network.roadconnections.roadconnection(index_into(rc_ids,all_rc_ids));
        end
        
        function X = get_roadconnections_for_node(this,node_id)
            X = [];
            
            link_ids = this.get_link_ids;
            out_links = link_ids( this.link_id_begin_end(:,2)==node_id );
            in_links = link_ids( this.link_id_begin_end(:,3)==node_id );
            
            rc_ind = arrayfun(@(z) ismember(z.ATTRIBUTE.in_link,in_links) , this.scenario.network.roadconnections.roadconnection ) & ...
            arrayfun(@(z) ismember(z.ATTRIBUTE.out_link,out_links) , this.scenario.network.roadconnections.roadconnection );
            
            if any(rc_ind)
                X = arrayfun(@(z) z.ATTRIBUTE.id , this.scenario.network.roadconnections.roadconnection(rc_ind) );
            end
            
        end
        
        % DEPRECATED: This is dangerous.
        function X = get_roadconnection_matrix(this)
            X=arrayfun(@(z) [z.ATTRIBUTE.id z.ATTRIBUTE.in_link z.ATTRIBUTE.out_link] ,this.scenario.network.roadconnections.roadconnection,'UniformOutput',false);
            X=vertcat(X{:});
        end
        
        % ROAD PARAMETERS
                
        function X = get_roadparam_ids(this)
            if isempty(this.scenario.network.roadparams)
                X = [];
            else
                X = arrayfun( @(z) z.ATTRIBUTE.id , this.scenario.network.roadparams.roadparam);
            end
        end
        
        function X = get_roadparam_for_linkid(this,link_id)
            
            if isempty(this.scenario.network.roadparams)
                X = [];
            else
                                
                % get the link and road parameter id
                link = this.get_links(link_id);
                road_param_id = link.ATTRIBUTE.roadparam;

                % get road parameterss
                ind = arrayfun( @(z) z.ATTRIBUTE.id==road_param_id , this.scenario.network.roadparams.roadparam);
                
                if ~any(ind)
                    return;
                end
                
                X = this.scenario.network.roadparams.roadparam(ind).ATTRIBUTE;
                
            end
            
            
        end
        
        % ROAD GEOMS
        
        function X = get_roadgeom_ids(this)
            if ~isfield(this.scenario.network,'roadgeoms') || isempty(this.scenario.network.roadgeoms)
                X = [];
            else
                X = arrayfun( @(z) z.ATTRIBUTE.id , this.scenario.network.roadgeoms.roadgeom);
            end
        end
        
        function X = get_roadgeoms(this)
            if isfield(this.scenario.network,'roadgeoms') && isfield(this.scenario.network.roadgeoms,'roadgeom')
                X = this.scenario.network.roadgeoms.roadgeom;
            else
                X = [];
            end
        end
        
        % ACTUATORS
        
        function X = get_actuator_ids(this)
            if ~isfield(this.scenario,'actuators') || isempty(this.scenario.actuators.actuator)
                X = [];
            else
                X = arrayfun( @(z) z.ATTRIBUTE.id , this.scenario.actuators.actuator);
            end
        end
        
        function X = get_actuator_with_ids(this,ids)
            all_ids = this.get_actuator_ids;
            ind = ismember(all_ids,ids);
            if any(ind)
                X = this.scenario.actuators.actuator(ind);
            else
                X = [];
            end
        end
        
        % COMMODITIES
        
        function X = get_commodity_ids(this)
            if isempty(this.scenario.commodities.commodity)
                X = [];
            else
                X = arrayfun( @(z) z.ATTRIBUTE.id , this.scenario.commodities.commodity);
            end
        end
        
        % DEMANDS
        
        function X = get_link_demands(this)
            if isempty(this.scenario.demands.demand)
                X = [];
            else
                is_link_dem = arrayfun(@(z) isfield(z.ATTRIBUTE,'link_id') && ~isnan(z.ATTRIBUTE.link_id) , this.scenario.demands.demand);
                X = this.scenario.demands.demand(is_link_dem);
            end
        end
        
        function X = get_path_demands(this)
            if isempty(this.scenario.demands.demand)
                X = [];
            else
                is_path_dem = arrayfun(@(z) isfield(z.ATTRIBUTE,'subnetwork') && ~isnan(z.ATTRIBUTE.subnetwork) , this.scenario.demands.demand);
                X = this.scenario.demands.demand(is_path_dem);
            end
        end
        
        % SPLITS
        
        function X = get_split_node_ids(this)
            if isempty(this.scenario.splits)
                X = [];
            else
                X = arrayfun( @(z) z.ATTRIBUTE.node_id , this.scenario.splits.split_node);
            end
        end
        
        %         function X = get_split_ids(this)
        %             if isempty(this.scenario.split)
        %                 X = [];
        %             else
        %                 X = arrayfun( @(z) z.ATTRIBUTE.id , this.scenario.actuators.actuator);
        %             end
        %         end
        
        % CONTROLLER
        
%         function X = get_controllers(this)
%             num_controller = numel(this.scenario.controllers.controller);
%             X = repmat(Controller,1,num_controller);
%             for i=1:num_controller
%                 X(i) = Controller(this.scenario.controllers.controller(i));
%             end
%         end
        
        function X = get_controllerid_for_nodeid(this,node_id)
            X = [];
            for i=1:numel(this.scenario.controllers.controller)
            
                C = this.scenario.controllers.controller(i);
                                
                actuators = this.get_actuator_with_ids(C.target_actuators.ATTRIBUTE.ids);
               
                target_ids = arrayfun(@(z) z.actuator_target.ATTRIBUTE.id, actuators );
                is_node = arrayfun(@(z) strcmp(z.actuator_target.ATTRIBUTE.type,'node'),actuators);

                node_ids = target_ids(is_node);
                
                if ismember(node_id,node_ids)
                    X(end+1) = C.ATTRIBUTE.id;
                end
                
            end
        end
        
        function X = get_pretimed_controller_info_with_controllerid(this,controller_id)
            
            X = [];

            % checks
            if ~isfield(this.scenario,'controllers') || ~isfield(this.scenario.controllers,'controller')
                return
            end


            ind = controller_id==arrayfun(@(z) z.ATTRIBUTE.id ,this.scenario.controllers.controller);
            
            if ~any(ind)
                return
            end
            
            controller = this.scenario.controllers.controller(ind);
            
            if ~strcmp(controller.ATTRIBUTE.type,'sig_pretimed')
               return 
            end
            
            if numel(controller.schedule.schedule_item)~=1
                return
            end
            
            % get the actuator
            ind = ismember(this.get_actuator_ids,controller.target_actuators.ATTRIBUTE.ids);
            
            % allow only single actuator
            if sum(ind)~=1
                error('controller must have a single actuator')
            end
            
            actuator = this.scenario.actuators.actuator(ind);
            phase_ids = arrayfun(@(z) z.ATTRIBUTE.id,actuator.signal.phase);
            
            % get road connection matrix
            RCM = this.get_roadconnection_matrix;
            
            % build a table
            stage = arrayfun(@(z) z.ATTRIBUTE,controller.schedule.schedule_item.stages.stage);
            
            % sort the stages
            [~,ind] = sort([stage.order]);
            stage = stage(ind);
            
            cum_start_time = 0;
            Phase = [];
            InLink = [];
            OutLink = [];
            StartTime = [];
            Duration = [];
            EndTime = [];
            for i=1:numel(stage)
                for j=1:numel(stage(i).phases)
                    phase = stage(i).phases(j);
                    % find that phase in the actuator, then road connections
                    road_conns = actuator.signal.phase(phase==phase_ids).ATTRIBUTE.roadconnection_ids;
                    for k=1: numel(road_conns)
                        Phase(end+1) = phase;
                        StartTime(end+1) = cum_start_time;
                        Duration(end+1) = stage(i).duration;
                        EndTime(end+1) = cum_start_time + stage(i).duration;
                        InLink(end+1) = RCM(RCM(:,1)==road_conns(k),2);
                        OutLink(end+1) = RCM(RCM(:,1)==road_conns(k),3);
                    end
                end
                cum_start_time = cum_start_time + stage(i).duration;
            end
            Phase = Phase';
            StartTime = StartTime';
            Duration = Duration';
            InLink = InLink';
            OutLink = OutLink';
            EndTime = EndTime';
            
            X.cycle = controller.schedule.schedule_item.ATTRIBUTE.cycle;
            X.offset = controller.schedule.schedule_item.ATTRIBUTE.offset;
            X.phase_table = table(Phase,StartTime,EndTime,Duration,InLink,OutLink);
        end
        
        % SUBNEWTORKS
        
        function X = get_subnetwork_ids(this)
            if ~isfield(this.scenario,'subnetworks') || isempty(this.scenario.subnetworks) || isempty(this.scenario.subnetworks.subnetwork)
                X = [];
            else
                X = arrayfun( @(z) z.ATTRIBUTE.id , this.scenario.subnetworks.subnetwork);
            end
        end
        
        function X = get_subnetwork(this,id)
            if isempty(this.scenario.subnetworks.subnetwork)
                X = [];
            else
                ind = id==arrayfun( @(z) z.ATTRIBUTE.id , this.scenario.subnetworks.subnetwork);
                if ~any(ind)
                    X = [];
                else
                    X = this.scenario.subnetworks.subnetwork(ind);
                end
            end
        end

        % SENSORS
        
        function X = get_sensor_table(this)
            if isempty(this.scenario.sensors.sensor)
                X = [];
            else
                id = arrayfun( @(z) z.ATTRIBUTE.id , this.scenario.sensors.sensor)';
                data_id = arrayfun( @(z) str2double(z.ATTRIBUTE.data_id(2:end)) , this.scenario.sensors.sensor)';
                link_id = arrayfun( @(z) z.ATTRIBUTE.link_id , this.scenario.sensors.sensor)';
                X = table(id,link_id,data_id);
            end
        end
        
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %% modify
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        function this = remove_link_ids(this,remove_ids)
            
            % erase links
            this.scenario.network.links.link(ismember(this.get_link_ids,remove_ids)) = [];
            
            % keep some nodes
            node_ids = this.get_node_ids;
            keep_nodes = [ ...
                arrayfun( @(z) z.ATTRIBUTE.end_node_id , this.scenario.network.links.link) ...
                arrayfun( @(z) z.ATTRIBUTE.start_node_id , this.scenario.network.links.link) ];
            keep_nodes = unique(keep_nodes);
            this.scenario.network.nodes.node(~ismember(node_ids,keep_nodes)) = [];
            clear node_ids keep_nodes
            
            % re-compute link_id_begin_end
            this.generate_link_id_begin_end
            
            % keep some roadgeoms
            has_road_geoms = arrayfun( @(z) isfield(z.ATTRIBUTE,'roadgeom') , this.scenario.network.links.link);
            used_road_geoms = unique(arrayfun( @(z) z.ATTRIBUTE.roadgeom , this.scenario.network.links.link(has_road_geoms)));
            road_geom_ids = arrayfun( @(z) z.ATTRIBUTE.id , this.scenario.network.roadgeoms.roadgeom);
            this.scenario.network.roadgeoms.roadgeom(~ismember(road_geom_ids,used_road_geoms)) = [];
            clear has_road_geoms used_road_geoms road_geom_ids
            
            % keep some roadparams
            used_road_params = unique(arrayfun( @(z) z.ATTRIBUTE.roadparam , this.scenario.network.links.link));
            road_param_ids = arrayfun( @(z) z.ATTRIBUTE.id , this.scenario.network.roadparams.roadparam);
            this.scenario.network.roadparams.roadparam(~ismember(road_param_ids,used_road_params)) = [];
            clear used_road_params road_param_ids
            
            % keep some road connections
            link_ids = this.get_link_ids;
            used_connections = arrayfun( @(z) ismember(z.ATTRIBUTE.out_link,link_ids) && ismember(z.ATTRIBUTE.in_link,link_ids) , ...
                this.scenario.network.roadconnections.roadconnection );
            this.scenario.network.roadconnections.roadconnection(~used_connections) = [];
            clear used_connections connection_ids
            
            % keep some sensors
            if isfield(this.scenario,'sensors')
                sensor_link_ids = arrayfun( @(z) z.ATTRIBUTE.link_id , this.scenario.sensors.sensor);
                keep = ismember(sensor_link_ids,link_ids);
                this.scenario.sensors.sensor(~keep) = [];
                clear sensor_link_ids keep
            end
            
            % prune subnetworks
            if isfield(this.scenario,'subnetworks')
                for i=1:numel(this.scenario.subnetworks.subnetwork)
                    keep = ismember(this.scenario.subnetworks.subnetwork(i).CONTENT,link_ids);
                    this.scenario.subnetworks.subnetwork(i).CONTENT(~keep) = [];
                end
                ind = arrayfun( @(z) isempty(z.CONTENT) , this.scenario.subnetworks.subnetwork);
                this.scenario.subnetworks.subnetwork(ind) = [];
            end
            
            % keep some demand
            if isfield(this.scenario,'demands')
                demand_link_ids = arrayfun( @(z) z.ATTRIBUTE.link_id , this.scenario.demands.demand);
                keep = ismember(demand_link_ids,link_ids);                
                this.scenario.demands.demand(~keep) = [];
                clear demand_link_ids keep
            end
            
            % keep some splits
            if isfield(this.scenario,'splits')
                
                % remove for non-existent node or link_in
                split_node_ids = arrayfun( @(z) z.ATTRIBUTE.node_id , this.scenario.splits.split_node);
                remove1 = ~ismember(split_node_ids,this.get_node_ids);
                
                split_linkin_ids = arrayfun( @(z) z.ATTRIBUTE.link_in , this.scenario.splits.split_node);
                remove2 = ~ismember(split_linkin_ids,link_ids);                
                
                this.scenario.splits.split_node(remove1 | remove2) = [];
                clear split_node_ids split_linkin_ids remove1 remove2
                
                % adjust remaining splits
                num_split = numel(this.scenario.splits.split_node);
                remove_entire = false(1,num_split);
                for i=1:num_split
                    split_node = this.scenario.splits.split_node(i);
                    
                    node_io = this.get_node_connections(  split_node.ATTRIBUTE.node_id);
                    
                    if numel(node_io.out_links)<=1
                        remove_entire(i) = true;
                        continue
                    end
                    
                    split_linkout = arrayfun(@(z) z.ATTRIBUTE.link_out , split_node.split);
                    remove = ~ismember(split_linkout,link_ids);

                    if any(remove)
                       sum_remove_split = sum(vertcat(split_node.split(remove).CONTENT));
                       for k=1:numel(split_node.split)
                           this.scenario.splits.split_node(i).split(k).CONTENT = ...
                               split_node.split(k)./(1-sum_remove_split);
                       end
                       this.scenario.splits.split_node(i).split(remove) = [];
                    end
                end
                
                this.scenario.splits.split_node(remove_entire) = [];
                clear remove_entire
            end
            
            
        end
        
        function this = latlng2meters(this)

            % find the center
            origin_lng = mean(arrayfun(@(z) z.ATTRIBUTE.x,this.scenario.network.nodes.node));
            origin_lat = mean(arrayfun(@(z) z.ATTRIBUTE.y,this.scenario.network.nodes.node));

            % recenter nodes
            for i=1:numel(this.scenario.network.nodes.node)
                [px,py] = Scenario.translate_point(this.scenario.network.nodes.node(i),origin_lng,origin_lat);
                this.scenario.network.nodes.node(i).ATTRIBUTE.x = px;
                this.scenario.network.nodes.node(i).ATTRIBUTE.y = py;
            end

            % recenter links
            for i=1:numel(this.scenario.network.links.link)
                link = this.scenario.network.links.link(i);
                for j=1:numel(link.points.point)
                    [px,py] = Scenario.translate_point(link.points.point(j),origin_lng,origin_lat);
                    link.points.point(j).ATTRIBUTE.x = px;
                    link.points.point(j).ATTRIBUTE.y = py;
                end
                this.scenario.network.links.link(i)=link;
            end
            
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %% plot
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        function []=plot_network(this,color_scheme)
            
            if nargin<2
                color_scheme = 'random';
            end
            
            lanewidth = 1;
            
            if strcmp(color_scheme,'road_type')
                type_color = containers.Map;
                type_color('Freeway') = [1 1 1];
                type_color('On-Ramp') = [0 1 0];
                type_color('Off-Ramp') = [0 0 1];
                type_color('Source') = [1 1 0];
                type_color('Sink') = [1 1 0];
                type_color('HOV') = [1 1 1];
                type_color('Interconnect') = [1 0 1];
                %                 type_color('On/Off Ramp') = [1 1 0];
            end
            
            % nodes
            numnodes = numel(this.scenario.network.nodes.node);
            node_pos = nan(numnodes,2);
            node_id = nan(numnodes,1);
            for i=1:numnodes
                node = this.scenario.network.nodes.node(i);
                node_id(i) = node.ATTRIBUTE.id;
                if isfield(node.ATTRIBUTE,'x')
                    node_pos(i,1) = node.ATTRIBUTE.x;
                end
                if isfield(node.ATTRIBUTE,'y')
                    node_pos(i,2) = node.ATTRIBUTE.y;
                end
            end
            
            % sensors
            if isfield(this.scenario,'sensors')
                numsensors = numel(this.scenario.sensors.sensor);
                sensors = repmat(struct('x',nan,'y',nan,'id',nan),1,numsensors);
                for i=1:numsensors
                    sensor = this.scenario.sensors.sensor(i).ATTRIBUTE;
                    [x,y] = this.linkpos_to_xy(sensor.link_id,sensor.position);
                    sensors(i).x = x;
                    sensors(i).y = y;
                    sensors(i).id = sensor.id;
                end
            else
                numsensors = 0;
            end
            
            %             figure('Position',get(0,'ScreenSize'))
            figure
            axis equal
            
            % links
            numlinks = numel(this.scenario.network.links.link);
            for i=1:numlinks
                link = this.scenario.network.links.link(i);
                
                if ~isfield(link,'points')
                    link_x = [nan nan];
                    link_y = [nan nan];
                    
                    % start node
                    ind = node_id==link.ATTRIBUTE.start_node_id;
                    if ~any(ind)
                        error('node not found')
                    end
                    link_x(1) = node_pos(ind,1);
                    link_y(1) = node_pos(ind,2);
                    
                    % end node
                    ind = node_id==link.ATTRIBUTE.end_node_id;
                    if ~any(ind)
                        error('node not found')
                    end
                    link_x(2) = node_pos(ind,1);
                    link_y(2) = node_pos(ind,2);
                    
                else
                    numpoints = numel(link.points.point);
                    link_x = nan(1,numpoints);
                    link_y = nan(1,numpoints);
                    for j=1:numpoints
                        link_x(j) = link.points.point(j).ATTRIBUTE.x;
                        link_y(j) = link.points.point(j).ATTRIBUTE.y;
                    end
                end
                
                h = line(link_x',link_y');
                switch color_scheme
                    case 'random'
                        set(h,'Color',rand(1,3))
                    case 'white'
                        set(h,'Color',[1 1 1])
                    case 'road_type'
                        set(h,'Color',type_color(link.ATTRIBUTE.road_type));
                end
                set(h,'LineWidth',link.ATTRIBUTE.full_lanes*lanewidth);
                
                % link labels
                if ismember(link.ATTRIBUTE.id,[8003100 8003101 547 676])
                    text(mean(link_x),mean(link_y),num2str(link.ATTRIBUTE.id),'Color',[1 1 0])
                end
                hold on
                
            end
            
            plot(node_pos(:,1),node_pos(:,2),'r.')
            %             if numsensors>0
            %                 plot([sensors.x],[sensors.y],'b.','MarkerSize',12)
            %                 for i=1:numsensors
            %                     h=text(sensors(i).x,sensors(i).y,sprintf('%d',sensors(i).id));
            %                     h.Color = [0 1 0];
            %                     h.FontWeight = 'bold';
            %                 end
            %             end
            set(gca,'Color',[0 0 0])
            
            
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %% other
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        function X = get_max_dt_sec(this)
            link_road_param_ids = arrayfun( @(z) z.ATTRIBUTE.roadparam , this.scenario.network.links.link);
            road_param_ids = arrayfun( @(z) z.ATTRIBUTE.id , this.scenario.network.roadparams.roadparam);
            link_road_param_ind = index_into(link_road_param_ids,road_param_ids);
            vf = arrayfun(@(z) z.ATTRIBUTE.speed ,  this.scenario.network.roadparams.roadparam(link_road_param_ind) );
            capacity = arrayfun(@(z) z.ATTRIBUTE.capacity ,  this.scenario.network.roadparams.roadparam(link_road_param_ind) );
            jam_density = arrayfun(@(z) z.ATTRIBUTE.jam_density ,  this.scenario.network.roadparams.roadparam(link_road_param_ind) );
            crit_density = capacity./vf;
            w = capacity./(jam_density-crit_density);
            link_legths_km = arrayfun( @(z) z.ATTRIBUTE.length , this.scenario.network.links.link) / 1000 ;
            wave_speed = max([vf;w]);
            X = 3600*link_legths_km./wave_speed;            
        end
        
    end
    
    methods (Access = private)
        
        function [x,y] = linkpos_to_xy(this,link_id,pos)
            x=nan;
            y=nan;
            
            link_ind = this.link_id_begin_end(:,1)==link_id;
            if ~any(link_ind)
                return
            end
            
            link = this.scenario.network.links.link(link_ind);
            link_length = link.ATTRIBUTE.length;
            points = link.points.point;
            
            if pos<0 || pos>link_length
                return
            end
            
            % special case for pos=0
            if pos==0
                x = points(1).ATTRIBUTE.x;
                y = points(1).ATTRIBUTE.y;
                return
            end
            
            if numel(points)<2
                return
            end
            
            % compute segment length
            segments = nan(1,numel(points)-1);
            for i=2:numel(points)
                p1 = points(i-1).ATTRIBUTE;
                p2 = points(i).ATTRIBUTE;
                segments(i-1) = sqrt((p2.x-p1.x)^2 + (p2.y-p1.y)^2);
            end
            if isnan(sum(segments)) || sum(segments)<=0
                return
            end
            segments  = segments * link_length / sum(segments);
            
            % find my segment
            seg_ind = find(pos<=cumsum(segments),1,'first');
            
            if seg_ind<1 || seg_ind>length(segments)
                error('this shouldn''t happen')
            end
            
            % relative position
            relpos = pos - sum(segments(1:seg_ind-1));
            
            % compute x and y
            p1 = points(seg_ind).ATTRIBUTE;
            p2 = points(seg_ind+1).ATTRIBUTE;
            x = p1.x + (p2.x-p1.x)*relpos/segments(seg_ind);
            y = p1.y + (p2.y-p1.y)*relpos/segments(seg_ind);
            
        end
        
    end
    
    methods (Static,Access=private)
        
        function [str]=writecommaformat(a,f)
            
            if(nargin<2)
                f = '%f';
            end
            
            if(~isvector(a))
                error('this function only works for vectors')
            end
            
            % unpack cell singleton
            if(iscell(a) && length(a)==1)
                a = a{1};
            end
            
            str = sprintf([f ','], a);
            str = str(1:end-1);
        end
        
        function [xx,yy]=translate_point(p,origin_lng,origin_lat)
            p_lat = p.ATTRIBUTE.y;
            p_lng = p.ATTRIBUTE.x;
            xx = sign(p_lng-origin_lng)*lldistkm([p_lat p_lng],[p_lat origin_lng])*1000;
            yy = sign(p_lat-origin_lat)*lldistkm([p_lat p_lng],[origin_lat p_lng])*1000;
        end

    end
    
end

