import os
import inspect
from OTMWrapper import OTMWrapper

# define the input file
this_folder = os.path.dirname(os.path.abspath(inspect.getfile(inspect.currentframe())))
root_folder = os.path.dirname(this_folder)
configfile = os.path.join(root_folder, 'configs', 'line.xml')

# open the api
otm = OTMWrapper(configfile)

# always end by deleting the wrapper
del otm