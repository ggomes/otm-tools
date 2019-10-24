clear
close all

% import the OTM API
import api.OTM

% load the configuration file into an OTMWrapper object
root = fileparts(fileparts(mfilename('fullpath')));
otm = OTMWrapper(fullfile(root,'configs','line.xml'));

% Plot the network
otm.show_network(10)

% Table of link information
X = otm.get_link_table

% All information in the configuration
X = otm.get_info()

% run a simulation
start_time = 0;
duration = 1500;
request_links = [1 2 3];
request_dt = 10;
otm.run_simple(start_time,duration,request_links,request_dt)

% extract the state trajectory
Y = otm.get_state_trajectory;

% plot the state trajectory
figure
subplot(311)
plot(Y.time,Y.vehs)
subplot(312)
plot(Y.time(2:end),Y.flows_vph)
subplot(313)
plot(Y.time(2:end),Y.speed_kph)
