import api.OTM

start_time = 0;
duration = 3600;
advance_time = 300;

% load the configuration file into an OTMWrapper object
root = fileparts(fileparts(mfilename('fullpath')));
otm = OTMWrapper(fullfile(root,'configs','line_macro.xml'));

% initialize (prepare/rewind the simulation)
otm.initialize(start_time);

% run step-by-step using the 'advance' method
time = start_time;
end_time = start_time+duration;

while(time<end_time)
	otm.advance(advance_time);

	% Insert your code here -----
	disp(otm.api.get_current_time())
    
	time = time + advance_time;
end