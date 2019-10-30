package otm.demos;

import error.OTMException;
import output.AbstractOutput;
import output.LinkFlow;
import output.LinkVehicles;

import java.util.Set;

public class Main {

    public static void main(String[] args) {
        load_one();
        run_one();
        run_step_by_step();
    }

    public static void load_one() {
        try {
            api.OTM otm = new api.OTM("../configs/line.xml");
            System.out.println(otm==null ? "Failure" : "Success");
        } catch (OTMException e) {
            System.err.print(e.getMessage());
        }
    }

    public static void run_one() {
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

    public static void run_step_by_step() {
        try {

            float start_time = 0f;
            float duration = 3600f;
            float advance_time = 300f;

            // load the scenario
            api.OTM otm = new api.OTM("../configs/line.xml");

            // initialize (prepare/rewind the simulation)
            otm.initialize(start_time);

            // run step-by-step using the 'advance' method
            float time = start_time;
            float end_time = start_time+duration;
            while(time<end_time){
                otm.advance(advance_time);

                // Insert your code here -----

                time += advance_time;
            }

        } catch (OTMException e) {
            System.err.print(e);
        }
    }

}
