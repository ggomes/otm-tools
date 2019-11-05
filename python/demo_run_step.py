import os
import inspect
from OTMWrapper import OTMWrapper

start_time = 0.
duration = 3600.
advance_time = 300.

# load the configuration file
this_folder = os.path.dirname(os.path.abspath(inspect.getfile(inspect.currentframe())))
root_folder = os.path.dirname(this_folder)
configfile = os.path.join(root_folder, 'configs', 'line.xml')
otm = OTMWrapper(configfile)

# initialize (prepare/rewind the simulation)
otm.initialize(start_time)

# run step-by-step using the 'advance' method
time = start_time
end_time = start_time + duration

while(time<end_time):
	otm.advance(advance_time)

	# Insert your code here -----
	print(otm.otm.get_current_time())

	time += advance_time;

# always end by deleting the wrapper
del otm