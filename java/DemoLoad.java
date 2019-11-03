import api.OTM;
public class DemoLoad {
	public static void main(String[] args)  {
		try {
            api.OTM otm = new api.OTM("../configs/line.xml");
            System.out.println(otm==null ? "Failure" : "Success");
        } catch (Exception e) {
            System.err.print(e.getMessage());
        }
	}        
}