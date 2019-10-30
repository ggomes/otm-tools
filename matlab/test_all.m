clear
close all

import api.OTM

root = fileparts(fileparts(mfilename('fullpath')));
otm = OTMWrapper(fullfile(root,'configs','line.xml'));

link_ids = [1 2 3];
outDt = 10;
prefix = 'myprefix';
output_folder = 'myoutputfolder';
commodity_id = [];
subnetwork_id = 0;

X = otm.get_info()
X = otm.get_models()
X = otm.get_num_commodities()
X = otm.get_commodities()
X = otm.get_commodity_with_id(1)
X = otm.get_commodity_ids()
X = otm.get_num_subnetworks()
X = otm.get_subnetwork_ids()
X = otm.get_path_ids()
X = otm.get_subnetworks()
X = otm.get_subnetwork_with_id(1)
X = otm.get_num_links()
X = otm.get_num_nodes()
X = otm.get_node_ids()
X = otm.get_link_connectivity()
X = otm.get_links()
X = otm.get_link_with_id(1)
X = otm.get_link_ids()
X = otm.get_source_link_ids()
X = otm.get_in_lanegroups_for_road_connection(1)
X = otm.get_out_lanegroups_for_road_connection(1)
X = otm.get_link2lgs()
X = otm.get_demands()
% X = otm.get_demand_with_ids(typestr,link_or_path_id,commodity_id)
% otm.clear_all_demands()
% X = otm.set_demand_on_path_in_vph(subnetwork_id,commodity_id,start_time,dt,values)
% X = otm.get_od_info()
X = otm.get_total_trips()
X = otm.get_num_sensors()
X = otm.get_sensors()
X = otm.get_sensor_with_id(1)
X = otm.get_num_controllers()
X = otm.get_controllers()
X = otm.get_controller_with_id(1)
% X = otm.get_actual_controller_with_id(1)
X = otm.get_num_actuators()
X = otm.get_actuators()
X = otm.get_actuator_with_id(1)



% X = otm.get_data()


% otm.request_lanegroups(prefix,output_folder)
% 
% otm.request_links_flow(outDt,link_ids,commodity_id,prefix,output_folder)
otm.request_links_flow(outDt,link_ids,commodity_id)
otm.request_links_flow(outDt,link_ids)
otm.request_links_flow(outDt)

otm.request_links_veh(outDt,link_ids,commodity_id,prefix,output_folder)
otm.request_links_veh(outDt,link_ids,commodity_id)
otm.request_links_veh(outDt,link_ids)
otm.request_links_veh(outDt)

otm.request_lanegroup_flw(outDt,link_ids,commodity_id,prefix,output_folder)
otm.request_lanegroup_flw(outDt,link_ids,commodity_id)
otm.request_lanegroup_flw(outDt,link_ids)
otm.request_lanegroup_flw(outDt)

otm.request_lanegroup_veh(outDt,link_ids,commodity_id,prefix,output_folder)
otm.request_lanegroup_veh(outDt,link_ids,commodity_id)
otm.request_lanegroup_veh(outDt,link_ids)
otm.request_lanegroup_veh(outDt)

otm.request_path_travel_time(outDt,subnetwork_id,prefix,output_folder)
otm.request_path_travel_time(outDt,subnetwork_id)
otm.request_path_travel_time(outDt)

otm.request_subnetwork_vht(outDt,subnetwork_id,commodity_id,prefix,output_folder)
otm.request_subnetwork_vht(outDt,subnetwork_id,commodity_id)
otm.request_subnetwork_vht(outDt,subnetwork_id)
otm.request_subnetwork_vht(outDt)

otm.request_vehicle_events(commodity_id,prefix,output_folder)
otm.request_vehicle_events(commodity_id)
otm.request_vehicle_events()

otm.request_vehicle_class(prefix,output_folder)
otm.request_vehicle_class()

otm.request_vehicle_travel_time(prefix,output_folder)
otm.request_vehicle_travel_time()

% otm.request_actuator(prefix,output_folder,actuator_id)
% otm.request_actuator(actuator_ids)
% otm.request_actuator()
% 
% otm.request_controller(prefix,output_folder,controller_id)
% otm.request_controller(controller_ids)
% otm.request_controller()

% X = otm.show_network(10)

% X = otm.get_link_table

X = otm.get_file_names()

otm.clear()


start_time = 0;
duration = 1500;
request_links = otm.get_link_ids;
request_dt = 10;
otm.run_simple(start_time,duration,request_links,request_dt)

X = otm.get_state_trajectory;

figure
subplot(311)
plot(X.time,X.vehs)
subplot(312)
plot(X.time(2:end),X.flows_vph)
subplot(313)
plot(X.time(2:end),X.speed_kph)
