from otm.JavaConnect import JavaConnect


class OTMWrapper:

	def __init__(self, configfile, port_num = 25335):

		self.configfile = configfile
		self.sim_output = None
		self.start_time = None
		self.duration = None

		self.conn = JavaConnect()
		if self.conn.pid is not None:
			self.otm = self.conn.gateway.get()
			self.otm.load(configfile,True,False)

	def __del__(self):

		if self.conn is not None:
			self.conn.close()

	# run a simulation
	def run_simple(self,start_time,duration,request_links,request_dt):
            
		self.start_time = start_time
		self.duration = duration

		# request outputs
		self.otm.print_float(4.)
		self.otm.print_set([1.0,2.0,3.0])

 	# 	self.otm.output().request_links_flow([],request_links,request_dt);
		# self.otm.output().request_links_veh([],request_links,request_dt);

		# run the simulation
		# self.otm.run(start_time,duration);
