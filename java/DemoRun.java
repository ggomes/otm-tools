import error.OTMException;
import output.*;
import java.util.Set;

public class DemoRun {
	public static void main(String[] args)  {
	     try {
		    // load the scenario
		    api.OTM otm = new api.OTM("../configs/line.xml");

		    // request 10-second sampling of all link flows and densities
		    float outdt = 10f;  // sampling time in seconds
		    Set<Long> link_ids = otm.scenario.get_link_ids();  // request all link ids
		    otm.output.request_links_flow(null, link_ids, outdt);
		    otm.output.request_links_veh(null, link_ids, outdt);

		    // run the simulation for 200 seconds
		    otm.run(0,200f);

		    // plot the output by iterating through the requested output data and
		    // calling the 'plot_for_links' method.
		    for(AbstractOutput output :  otm.output.get_data()){
			if (output instanceof LinkFlow)
			    ((LinkFlow) output).plot_for_links(null, String.format("%sflow.png", ""));
			if (output instanceof LinkVehicles)
			    ((LinkVehicles) output).plot_for_links(null, String.format("%sveh.png", ""));
		    }

		} catch (OTMException e) {
		    System.err.print(e);
		}
	}
}