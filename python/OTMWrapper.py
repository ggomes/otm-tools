from otm.JavaConnect import JavaConnect
import numpy as np

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

	def show_network(self):
		X = []
		return X

	def get_link_table(self):
		X = []
		return X

	# run a simulation
	def run_simple(self,start_time=0.,duration=3600.,output_dt=30.):
            
		self.start_time = float(start_time)
		self.duration = float(duration)

		link_ids = self.otm.scenario().get_link_ids()
		self.otm.output().request_links_flow(None,link_ids,float(output_dt))
		self.otm.output().request_links_veh(None,link_ids,float(output_dt))

		# run the simulation
		self.otm.run(self.start_time,self.duration)

	def get_state_trajectory(self):

		X = {'time':None,'link_ids':None,'vehs':None,'flows_vph':None,'speed_kph':None}
		output_data = self.otm.output().get_data()
		it = output_data.iterator()
		while(it.hasNext()):

			output = it.next()

			# collect common link ids
			if X['link_ids'] is None:
				link_list =list(output.get_link_ids())
				X['link_ids'] = np.array(link_list)
			else:
				if not np.array_equal(X['link_ids'],np.array(list(output.get_link_ids()))):
					raise ValueError('incompatible output requests')

			# collect common time vector
			if X['time'] is None:
				X['time'] = np.array(list(output.get_time()))
			else:
				if not np.array_equal( X['time'],np.array(list(output.get_time()))):
					error('incompatible output requests')

		# initialize outputs
		num_time = len(X['time'])
		num_links = len(X['link_ids'])

		X['vehs'] = np.empty([num_links,num_time])
		X['flows_vph'] = np.empty([num_links,num_time])

		it = output_data.iterator()
		while(it.hasNext()):
			output = it.next()

			for i in range(len(link_list)):
				z = output.get_profile_for_linkid(link_list[i])
				classname = output.getClass().getSimpleName()
				if(classname=="LinkFlow"):
					X['flows_vph'][i,0:-1] = np.diff(np.array(list(z.get_values())))*3600.0/z.get_dt()
				if(classname=="LinkVehicles"):
					X['vehs'][i,:] = np.array(list(z.get_values()))

		X['speed_kph'] = np.empty([num_links,num_time])
		for i in range(len(link_list)):
			link_info = self.otm.scenario().get_link_with_id(link_list[i])
			if link_info.isIs_source():
				X['speed_kph'][i,:] = np.nan;
			else:
				ffspeed_kph = link_info.get_ffspeed_kph()
				link_length_km = link_info.getFull_length()/1000.0;

				with np.errstate(divide='ignore', invalid='ignore'):
					speed_kph = np.nan_to_num( link_length_km * np.divide( X['flows_vph'][i] , X['vehs'][i] ) );
				speed_kph[speed_kph>ffspeed_kph] = ffspeed_kph;
				X['speed_kph'][i] = speed_kph;

		return X