import error.OTMException;
import py4j.GatewayServer;

public class OTMGateway {

	public core.OTM otm;

	public OTMGateway() {
	}

	public core.OTM get(String configfile, boolean validate_pre_init){
		try {
			return new core.OTM(configfile,validate_pre_init);
		} catch (OTMException e) {
			e.printStackTrace();
		}
		return null;
	}

	public static void main(String[] args) throws Exception {

		GatewayServer gatewayServer=null;
		try{

			// special case no command line arguments:
			if(args.length==0) {
				gatewayServer = new GatewayServer(new OTMGateway());
				gatewayServer.start();
				System.out.println("OTM connected on port " + gatewayServer.getPort());
				return;
			}
			else {

				String cmd = args[0];
				String[] arguments = new String[args.length - 1];
				System.arraycopy(args, 1, arguments, 0, args.length - 1);

				// specified port
				if (cmd.equals("-port")) {
					gatewayServer = new GatewayServer(new OTMGateway(), Integer.parseInt(args[1]));
					gatewayServer.start();
					System.out.println("OTM connected on port " + gatewayServer.getPort());
					return;
				}

				// version
				else if (cmd.equals("-version")){
					System.out.println("otm-sim: " + core.OTM.get_version());
					return;
				}

				// help
				else if (cmd.equals("-help")){
					System.out.println(get_usage());
					return;
				}

				else {
					System.out.println(get_usage());
					return;
				}
			}

		} catch(Exception e){
			if(gatewayServer!=null)
				gatewayServer.shutdown();
			throw new Exception(e);
		}

	}

	private static String get_usage(){
		String str =
				"Usage: [-port|-version|-help]\n" +
						"\t-port\tSpecify the port. (Default is 25333)\n" +
						"\t-version\tDisplay version information.\n" +
						"\t-help\tDisplay this message.\n";
		return str;
	}

}
