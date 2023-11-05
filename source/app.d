import server : startServer;
import report.gen : makeReport;

int main(string[] args) {
	import slf4d;
	import slf4d.default_provider;
	auto provider = new shared DefaultProvider(false, Levels.INFO);
	provider.getLoggerFactory().setModuleLevelPrefix("handy_httpd", Levels.WARN);
	// provider.getLoggerFactory().setModuleLevel("live_tracker", Levels.DEBUG);
	configureLoggingProvider(provider);

	if (args.length <= 1) {
		startServer();
		return 0;
	} else if (args[1] == "report") {
		return makeReport(args[2..$]);
	} else {
		import std.stdio;
		writeln("Invalid command. Expected no-args to start server, or \"report\" for report generation.");
		return 1;
	}
}
