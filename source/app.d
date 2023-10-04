import server : startServer;
import report : makeReport;

void main(string[] args) {
	if (args.length <= 1) {
		startServer();
	} else if (args[1] == "report") {
		makeReport(args[2..$]);
	}
}
