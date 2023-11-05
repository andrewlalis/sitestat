module server;

import std.file;
import handy_httpd;
import handy_httpd.handlers.path_handler;
import d_properties;
import slf4d;

void startServer() {
	Properties props;
	if (exists("sitestat.properties")) {
		props = Properties("sitestat.properties");
	} else {
		warn("No sitestat.properties file was found. Using defaults!");
	}
	new HttpServer(prepareHandler(props), prepareConfig(props)).start();
}

/**
 * Prepares the main request handler for the server.
 * Returns: The request handler.
 */
private HttpRequestHandler prepareHandler(Properties props) {
	import live_tracker;
	PathHandler pathHandler = new PathHandler();
	pathHandler.addMapping(
		Method.GET,
		"/ws",
		new WebSocketHandler(new LiveTracker(props.get!uint(
			"minSessionDurationMillis",
			LiveTracker.DEFAULT_MIN_SESSION_DURATION
		)))
	);
	return pathHandler;
}

/**
 * Prepares the server's configuration using sensible default values that can
 * be overridded by a "sitestat.properties" file in the program's working dir.
 * Returns: The config to use.
 */
private ServerConfig prepareConfig(Properties props) {
	ServerConfig config = ServerConfig.defaultValues();
	config.workerPoolSize = 3;
	config.port = 8081;
	config.enableWebSockets = true;
	if (props.has("server.host")) {
		config.hostname = props.get("host");
	}
	if (props.has("server.port")) {
		config.port = props.get!ushort("server.port");
	}
	if (props.has("server.workers")) {
		config.workerPoolSize = props.get!size_t("server.workers");
	}
	config.defaultHeaders["Access-Control-Allow-Origin"] = "*";
	config.defaultHeaders["Access-Control-Allow-Methods"] = "*";
	config.defaultHeaders["Access-Control-Allow-Headers"] = "*";
	return config;
}