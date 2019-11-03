import os
import inspect
from OTMWrapper import OTMWrapper

# define the input file
this_folder = os.path.dirname(os.path.abspath(inspect.getfile(inspect.currentframe())))
root_folder = os.path.dirname(this_folder)
configfile = os.path.join(root_folder, 'configs', 'line.xml')

# open the api
otm = OTMWrapper(configfile)

# # Plot the network
# otm.show_network(10)

# # Table of link information
# X = otm.get_link_table

# # All information in the configuration
# X = otm.get_info()

# run a simulation
# otm.run_simple(start_time=0,duration=1500,request_links=[1,2,3],request_dt=10)
otm.run_simple(0,1500,[1,2,3],10)

# # extract the state trajectory
# Y = otm.get_state_trajectory;

# # plot the state trajectory
# figure
# subplot(311)
# plot(Y.time,Y.vehs)
# subplot(312)
# plot(Y.time(2:end),Y.flows_vph)
# subplot(313)
# plot(Y.time(2:end),Y.speed_kph)

# always end by deleting the wrapper
del otm