clear
close all

root = fileparts(fileparts(mfilename('fullpath')));
configfile = fullfile(root,'configs','line.xml');
start_time = 0;
duration = 300;
sim_dt = 2;

otm = OTMWrapper(configfile);

otm.api.initialize(uint32(start_time));

time = start_time;
end_time = start_time + duration;
plot_links = [1 2 3];
link2lgs = Java2Matlab(otm.api.scenario.get_link2lgs());

empty_link_info = struct('lg_vehs',[]);
vehs = repmat(empty_link_info ,duration/sim_dt,numel(plot_links));

k = 1;
while time < end_time
    
    % advance simulation
    otm.api.advance(single(sim_dt));
    
    % exract cell vehicles
    anim_info = otm.api.scenario.get_animation_info();
    for i=1:numel(plot_links)
        java_link_info = anim_info.get_link_info( plot_links(i) );
        link_info = empty_link_info;
        lgs = Java2Matlab(link2lgs(plot_links(i)));
        for j=1:numel(lgs)
            lg_info = java_link_info.get_lanegroup_info(lgs(j));
            
            
            cell_info = Java2Matlab(lg_info.get_total_vehicles_by_cell);
            link_info.lg_vehs = [link_info.lg_vehs;cell_info];
        end
        vehs(k,i) = link_info;
    end
    
    % advance time
    time = time + sim_dt;
    k=k+1;
end

% plot
for i=1:numel(plot_links)
    link_id = plot_links(i);
    A = vertcat(vehs(:,i).lg_vehs);
    num_lgs = link2lgs(link_id).size();
    figure
    for j=1:num_lgs
        subplot(num_lgs,1,j)
        plot(A(j:num_lgs:end,:))
    end
end