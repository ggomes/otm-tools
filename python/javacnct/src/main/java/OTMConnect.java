import py4j.GatewayServer;
import utils.OTMUtils;

import java.io.IOException;
import java.io.InputStream;
import java.util.Properties;

public class OTMConnect {

	public api.OTM otm;

	public OTMConnect() {
		otm = new api.OTM();
	}

	public api.OTM get(){
		return otm;
	}

	public static void main(String[] args) throws Exception {

		GatewayServer gatewayServer=null;
		try{

			// special case no command line arguments:
			if(args.length==0) {
				gatewayServer = new GatewayServer(new OTMConnect());
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
					gatewayServer = new GatewayServer(new OTMConnect(), Integer.parseInt(args[1]));
					gatewayServer.start();
					System.out.println("OTM connected on port " + gatewayServer.getPort());
					return;
				}

				// version
				else if (cmd.equals("-version")){
					System.out.println("otm-base: " + OTMUtils.getBaseGitHash());
					System.out.println("otm-sim: " + api.OTM.get_version());
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
			throw new Exception("Could not initialize Java Gateway");
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
