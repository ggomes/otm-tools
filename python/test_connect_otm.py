import os
import inspect
from otm.JavaConnect import JavaConnect

this_folder = os.path.dirname(os.path.abspath(inspect.getfile(inspect.currentframe())))
root_folder = os.path.dirname(this_folder)
configfile = os.path.join(root_folder, 'configs', 'line_macro.xml')

conn = JavaConnect()

if conn.pid is not None:

    otm = conn.gateway.get()
    otm.load(configfile,True,False)

    conn.close()

