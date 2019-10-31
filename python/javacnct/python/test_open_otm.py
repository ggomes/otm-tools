from __future__ import division
import os
import inspect
from Java_Connection import Java_Connection
import numpy as np
import time
import matplotlib.pyplot as plt
import csv

conn = Java_Connection()

if conn.pid is not None:
    sim_dt = 2.0

    this_folder = os.path.dirname(os.path.abspath(inspect.getfile(inspect.currentframe())))
    root_folder = os.path.dirname(this_folder)
    configfile = os.path.join(root_folder, 'config', 'line.xml')

    otm_api = conn.gateway.entry_point.get_OTM_API()
    otm_api.load(configfile, sim_dt, True, "ctm")

    print(otm_api.get_num_links())

    # kill jvm
    conn.close()

