import server : startServer;
import report : makeReport;

void main(string[] args) {
	import slf4d;
	import slf4d.default_provider;
	auto provider = new shared DefaultProvider(false, Levels.INFO);
	provider.getLoggerFactory().setModuleLevelPrefix("handy_httpd", Levels.WARN);
	// provider.getLoggerFactory().setModuleLevel("live_tracker", Levels.DEBUG);
	configureLoggingProvider(provider);

	if (args.length <= 1) {
		startServer();
	} else if (args[1] == "report") {
		makeReport(args[2..$]);
	}
}
