import handy_httpd;
import handy_httpd.handlers.path_delegating_handler;

void main() {
	import slf4d;
	import slf4d.default_provider;
	auto provider = new shared DefaultProvider(true, Levels.INFO);
	// provider.getLoggerFactory().setModuleLevel("live_tracker", Levels.DEBUG);
	configureLoggingProvider(provider);

	new HttpServer(prepareHandler(), prepareConfig()).start();
}

/**
 * Prepares the main request handler for the server.
 * Returns: The request handler.
 */
private HttpRequestHandler prepareHandler() {
	import live_tracker;
	PathDelegatingHandler pathHandler = new PathDelegatingHandler();

	pathHandler.addMapping(Method.GET, "/ws", new WebSocketHandler(new LiveTracker()));

	return pathHandler;
}

/**
 * Prepares the server's configuration using sensible default values that can
 * be overridded by a "sitestat.properties" file in the program's working dir.
 * Returns: The config to use.
 */
private ServerConfig prepareConfig() {
	import std.file;
	import d_properties;
	ServerConfig config = ServerConfig.defaultValues();
	config.workerPoolSize = 3;
	config.port = 8081;
	config.enableWebSockets = true;
	if (exists("sitestat.properties")) {
		Properties props = Properties("sitestat.properties");
		if (props.has("server.host")) {
			config.hostname = props.get("host");
		}
		if (props.has("server.port")) {
			config.port = props.get!ushort("server.port");
		}
		if (props.has("server.workers")) {
			config.workerPoolSize = props.get!size_t("server.workers");
		}
	}
	return config;
}
