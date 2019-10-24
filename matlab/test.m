clear
close all

import api.OTM

root = fileparts(fileparts(mfilename('fullpath')));
otm = OTMWrapper(fullfile(root,'configs','line.xml'));

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
% X = otm.set_demand_on_path_in_vph(path_id,commodity_id,start_time,dt,values)
X = otm.get_od_info()
X = otm.get_total_trips()
X = otm.get_num_sensors()
X = otm.get_sensors()
X = otm.get_sensor_with_id(1)
X = otm.get_num_controllers()
X = otm.get_controllers()
X = otm.get_controller_with_id(1)
X = otm.get_actual_controller_with_id(1)
X = otm.get_num_actuators()
X = otm.get_actuators()
X = otm.get_actuator_with_id(1)

% X = otm.show_network(10)

% X = otm.get_link_table

start_time = 0;
duration = 1500;
request_links = [1 2 3];
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
