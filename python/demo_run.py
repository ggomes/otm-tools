import os
import inspect
from pyotm.OTMWrapper import OTMWrapper
from matplotlib import pyplot as plt

# define the input file
this_folder = os.path.dirname(os.path.abspath(inspect.getfile(inspect.currentframe())))
root_folder = os.path.dirname(this_folder)
configfile = os.path.join(root_folder, 'configs', 'line_macro.xml')

# open the api
otm = OTMWrapper(configfile)

# Plot the network
# otm.show_network(4)

# run a simulation
otm.run_simple(start_time=0,duration=2500,output_dt=10)

# extract the state trajectory
Y = otm.get_state_trajectory()

# plot the state trajectory
fig = plt.figure()
plt.subplot(211)
plt.plot(Y['time'],Y['vehs'].T)
plt.ylabel("vehicles")
plt.title("OTM simulation result")
plt.subplot(212)
plt.plot(Y['time'],Y['flows_vph'].T)
plt.ylabel("flow [vph]")
# plt.subplot(313)
# plt.plot(Y['time'],Y['speed_kph'].T)
# plt.ylabel("speed [kph]")
# plt.legend(['link 1','link 2','link 3'])
# plt.xlabel("time [sec]")
plt.draw()

plt.show()


