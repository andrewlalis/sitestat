module report.output;

import std.stdio;
import report.gen : SiteReport;

interface ReportOutputGenerator {
    void generate(const(SiteReport[]) reports);
}

/**
 * Report output generator that outputs reports as human-readable text, without
 * any particular format.
 */
class ReportTextOutputGenerator : ReportOutputGenerator {
    void generate(const(SiteReport[]) reports) {
        foreach (report; reports) {
            writefln!"Report for site %s from %s to %s:"(
                report.siteName,
                report.period.start.toISOExtString(),
                report.period.end.toISOExtString()
            );
            writefln!"  Total sessions: %d"(report.totalSessions);
            writefln!"  Mean session duration (seconds): %.3f"(report.meanSessionDurationSeconds);
            writefln!"  Mean events per sesson: %.3f"(report.meanEventsPerSession);
            foreach (string userAgent, ulong count; report.userAgents) {
                writefln!"  User agent: %s"(userAgent);
                writefln!"    Count: %d"(count);
            }
        }
    }
}

/**
 * Report output generator that outputs reports as a JSON array of objects.
 */
class ReportJsonOutputGenerator : ReportOutputGenerator {
    import std.json;

    void generate(const(SiteReport[]) reports) {
        JSONValue jsonArray = JSONValue(string[].init);
        foreach (report; reports) {
            JSONValue obj = JSONValue(string[string].init);
            obj.object["siteName"] = report.siteName;
            obj.object["periodStart"] = report.period.start.toISOExtString();
            obj.object["periodEnd"] = report.period.end.toISOExtString();
            obj.object["totalSessions"] = report.totalSessions;
            obj.object["meanSessionDurationSeconds"] = report.meanSessionDurationSeconds;
            obj.object["meanEventsPerSession"] = report.meanEventsPerSession;
            obj.object["userAgents"] = JSONValue(string[string].init);
            foreach (string userAgent, ulong count; report.userAgents) {
                obj.object["userAgents"].object[userAgent] = count;
            }
            jsonArray.array ~= obj;
        }
        writeln(jsonArray.toPrettyString());
    }
}

/**
 * Report output generator that generates output as CSV text, grouped by each
 * site's name.
 */
class ReportCsvOutputGenerator : ReportOutputGenerator {
    void generate(const(SiteReport[]) reports) {
        writeln("site, statistic, value"); // Headers.
        foreach (report; reports) {
            writefln!"%s, periodStart, %s"(report.siteName, report.period.start.toISOExtString());
            writefln!"%s, periodEnd, %s"(report.siteName, report.period.end.toISOExtString());
            writefln!"%s, totalSessions, %d"(report.siteName, report.totalSessions);
            writefln!"%s, meanSessionDurationSeconds, %.3f"(report.siteName, report.meanSessionDurationSeconds);
            writefln!"%s, meanEventsPerSession, %.3f"(report.siteName, report.meanEventsPerSession);
        }
    }
}
