import error.OTMException;
public class DemoRunStep {

    public static void main(String[] args) {
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
                System.out.println(time);

                otm.advance(advance_time);

                // Insert your code here -----

                time += advance_time;
            }

        } catch (OTMException e) {
            System.err.print(e);
        }
    }
}