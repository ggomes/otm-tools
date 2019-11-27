classdef ScenarioBuilder < handle
    
    properties
        s @ Scenario
    end
    
    properties(Access = private)
        X  % standard structures
    end
    
    methods(Access = public)
        
        function this = ScenarioBuilder()
            this.s = Scenario;
            
            this.X = ScenarioBuilder.build_structs;
            
            % initialize the scenario
            this.s.scenario.ATTRIBUTE.xmlns='opentrafficmodels';
            this.s.scenario.network = struct( ...
                'links',[], ...
                'nodes',[], ...
                'roadgeoms',[], ...
                'roadconnections',[], ...
                'roadparams',[] ...
                );

            this.s.scenario.network.nodes.node = repmat(this.X.node_struct,1,0);
            this.s.scenario.network.nodes.ATTRIBUTE.gps_or_meters="meters";
            this.s.scenario.network.links.link = repmat(this.X.link_struct,1,0);
            this.s.scenario.network.roadconnections.roadconnection = repmat(this.X.roadconnection_struct,1,0);
            this.s.scenario.network.roadgeoms.roadgeom = repmat(this.X.roadgeoms_struct,1,0);
            this.s.scenario.network.roadparams.roadparam = repmat(this.X.roadparams_struct,1,0);
            
            this.s.scenario.actuators.actuator = repmat(this.X.actuator_struct,1,0);
            this.s.scenario.controllers.controller = repmat(this.X.controller_struct,1,0);

            this.s.scenario.commodities.commodity = repmat(this.X.commodity_struct,1,0);
            this.s.scenario.demands.demand = repmat(this.X.link_demand_struct,1,0);
            this.s.scenario.splits.split_node = repmat(this.X.splitnode_struct,1,0);
            this.s.scenario.models.model = this.X.model_struct_ctm;
                        
        end
        
        % NETWORK -----------------------------
        
        function this = add_node(this,id,x,y)
            
            if ismember(id,this.s.get_node_ids)
                disp('I already have that node')
            end
            
            new_node = this.X.node_struct;
            new_node.ATTRIBUTE.id = id;
            new_node.ATTRIBUTE.x = x;
            new_node.ATTRIBUTE.y = y;
            this.s.scenario.network.nodes.node(end+1) = new_node;
        end
        
        function this = add_nodes(this,nodes)
            all_ids = [nodes.id];
            num_nodes = numel(all_ids);
            if any(ismember(all_ids,this.s.get_node_ids))
                disp('I already have that node')
            end
            new_nodes = repmat(this.X.node_struct,1,num_nodes);
            for i=1:num_nodes
                new_nodes(i).ATTRIBUTE.id = nodes(i).id;
                new_nodes(i).ATTRIBUTE.x = nodes(i).x;
                new_nodes(i).ATTRIBUTE.y = nodes(i).y;
                
            end
            this.s.scenario.network.nodes.node = [this.s.scenario.network.nodes.node new_nodes];

        end
        
        function this = add_link(this,id,start_node_id,end_node_id,L,full_lanes,roadparam,roadgeom,shape)
            
            if nargin<9
                shape = [];
            end
           
            if nargin<8
                roadgeom = [];
            end
            
            if ismember(id,this.s.get_link_ids)
                disp('I already have that link')
            end
            
            new_link = this.X.link_struct;
            new_link.ATTRIBUTE.id = id;
            new_link.ATTRIBUTE.start_node_id = start_node_id;
            new_link.ATTRIBUTE.end_node_id = end_node_id;
            new_link.ATTRIBUTE.length = L;
            new_link.ATTRIBUTE.full_lanes = full_lanes;
            new_link.ATTRIBUTE.roadparam = roadparam;
            if isempty(roadgeom) || isnan(roadgeom)
                new_link.ATTRIBUTE = rmfield(new_link.ATTRIBUTE,'roadgeom');
            else
                new_link.ATTRIBUTE.roadgeom = roadgeom;
            end
            
            if ~isempty(shape)
                new_link.points.point = repmat(this.X.point_struct,1,size(shape,2));
                for i=1:size(shape,2)
                    new_point = this.X.point_struct;
                    new_point.ATTRIBUTE.x = shape(1,i);
                    new_point.ATTRIBUTE.y = shape(2,i);
                    new_link.points.point(i) = new_point;                        
                end
            else
                new_link = rmfield(new_link,'points');
            end
            
            if isempty(this.s.scenario.network.links.link)
                this.s.scenario.network.links.link = new_link;
            else
                this.s.scenario.network.links.link(end+1) = new_link;
            end
            this.s.link_id_begin_end(end+1,:) = [id start_node_id end_node_id];
            
        end
        
        function this = add_links(this,links)
            
            all_ids = [links.id];
            num_links = numel(all_ids);
            if any(ismember(all_ids,this.s.get_link_ids))
                disp('I already have that link')
            end
            
            link_struct = this.X.link_struct;
            
            % can start off with a simpler structure
            if isempty(this.s.scenario.network.links.link)
                if ~isfield(links,'points')
                    link_struct = rmfield(link_struct,'points');
                end

                if ~isfield(links,'roadgeoms')
                    link_struct.ATTRIBUTE = rmfield(link_struct.ATTRIBUTE,'roadgeom');
                end
                this.s.scenario.network.links.link = repmat(link_struct,1,0);
            end
            
            new_links = repmat(link_struct,1,num_links);
            for i=1:num_links
                new_links(i).ATTRIBUTE.id = links(i).id;
                
                new_links(i).ATTRIBUTE.start_node_id = links(i).start_node;
                new_links(i).ATTRIBUTE.end_node_id = links(i).end_node;
                
                new_links(i).ATTRIBUTE.length = links(i).length;
                
                new_links(i).ATTRIBUTE.full_lanes = links(i).full_lanes;
                new_links(i).ATTRIBUTE.roadparam = links(i).roadparam;
                                
            end
            this.s.scenario.network.links.link = [this.s.scenario.network.links.link new_links];
            
            
        end
        
        function this = connect_links(this,id,link_in,link_in_lanes,link_out,link_out_lanes)
            
            M = this.s.get_roadconnection_matrix;
            if ~isempty(M) && any(M(:,1)==link_in & M(:,2)==link_out)
                disp('I already have a connection for this link pairr')
            end
            
            new_rc = this.X.roadconnection_struct;
            new_rc.ATTRIBUTE.id = id;
            new_rc.ATTRIBUTE.in_link = link_in;
            new_rc.ATTRIBUTE.in_link_lanes = writecommaformat(link_in_lanes,'%d','#');
            new_rc.ATTRIBUTE.out_link = link_out;
            new_rc.ATTRIBUTE.out_link_lanes = writecommaformat(link_out_lanes,'%d','#');
            
            this.s.scenario.network.roadconnections.roadconnection(end+1) = new_rc;
            
        end
        
        function this = add_roadgeom(this,id,addlanes)
            
            if ismember(id,this.s.get_roadgeom_ids)
                disp('I already have that noroadgeomde')
            end
            
            new_rg = this.X.roadgeoms_struct;
            new_rg.ATTRIBUTE.id = id;
            new_rg.add_lanes = repmat(this.X.addlanes_struct,1,numel(addlanes));
            for i=1:numel(addlanes)
                new_rg.add_lanes(i).ATTRIBUTE.lanes = addlanes(i).lanes;
                new_rg.add_lanes(i).ATTRIBUTE.side = addlanes(i).side;
                new_rg.add_lanes(i).ATTRIBUTE.start_pos = addlanes(i).start_pos;
            end
            
            this.s.scenario.network.roadgeoms.roadgeom(end+1) = new_rg;
            
        end
        
        function this = add_roadparam(this,id,capacity,speed,jam_density)
            
            if ismember(id,this.s.get_roadparam_ids)
                disp('I already have that road parameter set.')
            end
            
            new_rp = this.X.roadparams_struct;
            new_rp.ATTRIBUTE.id = id;
            new_rp.ATTRIBUTE.capacity= capacity;
            new_rp.ATTRIBUTE.speed = speed;
            new_rp.ATTRIBUTE.jam_density = jam_density;
            
            this.s.scenario.network.roadparams.roadparam(end+1) = new_rp;
            
        end
        
        function this = add_roadparams(this,roadparams)            
            all_ids = [roadparams.id];
            num_params = numel(all_ids);
            if any(ismember(all_ids,this.s.get_roadparam_ids))
                disp('I already have that node')
            end
            new_params = repmat(this.X.roadparams_struct,1,num_params);
            for i=1:num_params
                new_params(i).ATTRIBUTE.id = roadparams(i).id;
                new_params(i).ATTRIBUTE.capacity = roadparams(i).capacity;
                new_params(i).ATTRIBUTE.speed = roadparams(i).speed;
                new_params(i).ATTRIBUTE.jam_density = roadparams(i).jam_density;
                
            end
            this.s.scenario.network.roadparams.roadparam = [this.s.scenario.network.roadparams.roadparam new_params];
        end
        
        % SIGNALS AND PRETIMED CONTROLLER ------------------
        
        function this = add_signal(this,id,node_id,phases)
            
            if ismember(id,this.s.get_actuator_ids)
                disp('I already have that road parameter set.')
            end
            
            new_act = this.X.actuator_struct;
            new_act.ATTRIBUTE.id = id;
            new_act.actuator_target.ATTRIBUTE.id = node_id;
            
            new_act.signal.phase = repmat(this.X.phase_struct,1,numel(phases));
            
            for i=1:numel(phases)
                new_phase = this.X.phase_struct;
                new_phase.ATTRIBUTE.id = phases(i).id;
                new_phase.ATTRIBUTE.roadconnection_ids = writecommaformat(phases(i).rcs,'%d',',');
                new_phase.ATTRIBUTE.yellow_time = phases(i).y;
                new_phase.ATTRIBUTE.red_clear_time = phases(i).r;
                new_phase.ATTRIBUTE.min_green_time = phases(i).ming;
                new_act.signal.phase(i) = new_phase;
            end
            
            this.s.scenario.actuators.actuator(end+1) = new_act;
            
        end
        
        function C = add_controller(this,C)
            this.s.scenario.controllers.controller(end+1) = C.controller;            
        end
        
        % COMMODITIES, DEMANDS, SPLITS -----------------------
        
        function this = add_commodity(this,id,name)       
            if ismember(id,this.s.get_commodity_ids)
                disp('I already have that commodity id.')
            end            
            new_comm = this.X.commodity_struct;
            new_comm.ATTRIBUTE.id = id;
            new_comm.ATTRIBUTE.name = name;
            
            this.s.scenario.commodities.commodity(end+1) = new_comm;
            
        end
        
        function this = add_link_demand(this,commodity_id,link_id,value)
           
            % check if a demand already exists for this link and commodity
            D = this.s.get_link_demands;
            if any(arrayfun(@(z) z.ATTRIBUTE.commodity_id==commodity_id && z.ATTRIBUTE.link_id==link_id , D ))
                disp('I already have a demand for this link and commodity')
            end
            clear D
            
            new_dem = this.X.link_demand_struct;
            new_dem.ATTRIBUTE.commodity_id = commodity_id;
            new_dem.ATTRIBUTE.link_id = link_id;
            new_dem.CONTENT = value;
                        
            this.s.scenario.demands.demand(end+1) = new_dem;

        end

        function this = add_split(this,node_id,commodity_id,link_in,values)
            
            % check whether I already have splits for this node, commodity and in links
            
            
            new_split = this.X.splitnode_struct;
            new_split.ATTRIBUTE.node_id = node_id;
            new_split.ATTRIBUTE.commodity_id = commodity_id;
            new_split.ATTRIBUTE.link_in = link_in;
            new_split.split = repmat(this.X.split_struct,1,size(values,1));
            for i=1:size(values,1)
                new_split.split(i).ATTRIBUTE.link_out = values(i,1);
                new_split.split(i).CONTENT = values(i,2);
            end
            
            this.s.scenario.splits.split_node(end+1) = new_split;
        end
        
        function [] = write(this,outfile)
            
            if isfield(this.s.scenario,'commodities') && isempty(this.s.scenario.commodities.commodity)
                this.s.scenario = rmfield(this.s.scenario,'commodities');
            end
            
            if isfield(this.s.scenario,'actuators') && isempty(this.s.scenario.actuators.actuator)
                this.s.scenario = rmfield(this.s.scenario,'actuators');
            end
            
            if isfield(this.s.scenario,'controllers') && isempty(this.s.scenario.controllers.controller)
                this.s.scenario = rmfield(this.s.scenario,'controllers');
            end
            
            if isfield(this.s.scenario,'demands') && isempty(this.s.scenario.demands.demand)
                this.s.scenario = rmfield(this.s.scenario,'demands');
            end
            
            if isfield(this.s.scenario,'splits') && isempty(this.s.scenario.splits.split_node)
                this.s.scenario = rmfield(this.s.scenario,'splits');
            end
            
            this.s.save(outfile);
        end
        
        function isgood = check_scenario(this)
            
            isgood = true;
            
            % check that all used road geometries are defined
            all_geoms = arrayfun(@(z) z.ATTRIBUTE.roadgeom,this.s.scenario.network.links.link);
            all_geoms = all_geoms(~isnan(all_geoms));
            
            if ~all(ismember(all_geoms,this.s.get_roadgeom_ids))
                isgood = false;
                disp('Not all used road geometries have been defined')
            end
            
            % check that all used road parameters are defined
            all_params = arrayfun(@(z) z.ATTRIBUTE.roadparam,this.s.scenario.network.links.link);
            all_params = all_params(~isnan(all_params));
            
            if ~all(ismember(all_params,this.s.get_roadparam_ids))
                isgood = false;
                disp('Not all used road parameters have been defined')
            end
 
        end
        
    end
    
    methods(Static,Access=public)
        
        function X = build_structs()
            
            X.model_struct_ctm = struct('ATTRIBUTE',struct('type','ctm','name','ctm','is_default','true'));
            X.model_struct_ctm.model_params = struct('ATTRIBUTE',struct('sim_dt','1','max_cell_length','100'));

            X.node_struct = struct('ATTRIBUTE',struct('id',nan,'x',nan,'y',nan));
            
            X.link_struct = struct('ATTRIBUTE',struct('id',nan, ...
                'start_node_id',nan,...
                'end_node_id',nan,...
                'length',nan,...
                'full_lanes',nan,...
                'roadparam',nan,...
                'roadgeom',nan) , ...
                'points',[]);
            
            X.point_struct = struct('ATTRIBUTE',struct('x',nan,'y',nan));
            X.link_struct.points.point = repmat(X.point_struct,1,0);
            
            X.roadconnection_struct = struct('ATTRIBUTE',struct('id',nan, ...
                'in_link',nan,...
                'in_link_lanes',[],...
                'out_link',nan,...
                'out_link_lanes',[]));
            
            X.addlanes_struct = struct('ATTRIBUTE',struct(...
                'lanes',nan,...
                'side','',...
                'start_pos',nan ));
            
            X.roadgeoms_struct = struct('ATTRIBUTE',struct('id',nan), ...
                'add_lanes',repmat(X.addlanes_struct,1,0) );
            
            X.roadparams_struct = struct('ATTRIBUTE',struct('id',nan,...
                'capacity',nan,...
                'speed',nan,...
                'jam_density',nan ) );
            
            X.phase_struct = struct('ATTRIBUTE',struct('id',nan,...
                'roadconnection_ids',[],...
                'yellow_time',nan,...
                'red_clear_time',nan,...
                'min_green_time',nan));
            
            X.actuator_struct = struct('ATTRIBUTE',struct('id',nan,'type','signal'),...
                'actuator_target',struct('ATTRIBUTE',struct('type','node','id',nan)),...
                'signal',struct('phase',repmat(X.phase_struct,1,0)) );
            
            X.stage_struct = struct('ATTRIBUTE',struct('order',nan,'phases',nan,'duration',nan));
            
            X.scheduleitem_struct = struct('ATTRIBUTE',struct('start_time',nan,'cycle',nan,'offset',nan),...
                'stages',[]);
            
            X.scheduleitem_struct.stages.stage = repmat(X.stage_struct,1,0);
            
            X.controller_struct = struct('ATTRIBUTE',struct('id',nan,'type','sig_pretimed'),...
                'target_actuators',struct('ATTRIBUTE',struct('ids',[])),...
                'schedule',[]);
            
            X.controller_struct.schedule.schedule_item = repmat(X.scheduleitem_struct,1,0);

            X.commodity_struct = struct('ATTRIBUTE',struct('id',nan,'name',''));
            
            X.link_demand_struct = struct('ATTRIBUTE',struct('commodity_id',nan,'link_id',nan), ...
                                          'CONTENT','');
                                      
            X.split_struct = struct('ATTRIBUTE',struct('link_out',nan),'CONTENT',nan);
            
            X.splitnode_struct = struct('ATTRIBUTE',struct('node_id',nan,'commodity_id',nan,'link_in',nan), ...
                'split',repmat(X.split_struct,1,0));
           
                                      
        end
        
    end
    
    
end

