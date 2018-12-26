clear
close all

config_folder = 'C:\Users\gomes\code\otm\otm-base\src\main\resources\test_configs';

a = dir(config_folder);
for i=1:numel(a)
    
    if a(i).isdir
        continue
    end
    
    if length(a(i).name)<4 || ~strcmp(a(i).name(end-3:end),'.xml')
        continue
    end
    
    if strcmp(a(i).name,'signal.xml')
        continue
    end
        
    configfile = fullfile(config_folder,a(i).name)
    sim_dt = 1;
    modelname = 'ctm';
    lanewidth = 3;
    duration = 3600;
    time_period = [0 duration];
    out_dt = 10;
    
    otm = OTM(configfile,sim_dt,modelname);
    
    x = Scenario(configfile);
    link_ids = x.get_link_ids;
        
    otm.run_simple(0,duration,link_ids,out_dt)
    X = otm.get_state_trajectory();
    
    figure
    subplot(211)
    plot(X.time,X.vehs,'LineWidth',2)
    ylabel('vehicles')
    grid
    legend(num2str(X.link_ids'))
    subplot(212)
    plot(X.time(1:end-1),X.flows,'LineWidth',2)
    ylabel('flow [vph]')
    grid
    
end


