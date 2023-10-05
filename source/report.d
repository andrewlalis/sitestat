module report;

import utils;
import std.stdio;
import std.datetime;
import std.algorithm;
import std.array;
import d2sqlite3;
import data;
import std.json;

void makeReport(string[] sites) {
    string[] sitesToReport = sites.length == 0 ? listAllOrigins() : sites;
    if (sitesToReport.length == 0) {
        writeln("No sites to report.");
        return;
    }
    writeln("Creating report for " ~ createSiteNamesSummary(sitesToReport) ~ ".");
    foreach (site; sitesToReport) {
        writeln("Site: " ~ site);
        SiteReport report = generateReport(site, Clock.currTime(UTC()) - hours(48), Clock.currTime(UTC()));
        writeln(report.toJson().toPrettyString());
    }
}

string createSiteNamesSummary(string[] sites) {
    if (sites.length == 0) return "all sites";
    if (sites.length == 1) return "site " ~ sites[0];
    import std.array;
    auto app = appender!string();
    app ~= "sites ";
    foreach (i, site; sites) {
        app ~= site;
        if (i + 2 == sites.length) {
            app ~= ", and ";
        } else if (i + 1 < sites.length) {
            app ~= ", ";
        }
    }
    return app[];
}

struct SiteReport {
    string siteName;
    SysTime periodStart;
    SysTime periodEnd;

    ulong totalSessions;
    double meanSessionDurationSeconds;
    double meanEventsPerSession;

    JSONValue toJson() const {
        JSONValue obj = JSONValue(string[string].init);
        obj.object["siteName"] = siteName;
        obj.object["periodStart"] = periodStart.toISOExtString();
        obj.object["periodEnd"] = periodEnd.toISOExtString();
        obj.object["totalSessions"] = totalSessions;
        obj.object["meanSessionDurationSeconds"] = meanSessionDurationSeconds;
        obj.object["meanEventsPerSession"] = meanEventsPerSession;
        return obj;
    }
}

SiteReport generateReport(string site, SysTime periodStart, SysTime periodEnd) {
    SiteReport report;
    report.siteName = site;
    report.periodStart = periodStart;
    report.periodEnd = periodEnd;
    immutable string TS_START = formatSqliteTimestamp(periodStart);
    immutable string TS_END = formatSqliteTimestamp(periodEnd);
    writefln!"TS_START = %s, TS_END = %s"(TS_START, TS_END);
    Database db = getOrCreateDatabase(site);

    report.totalSessions = db.execute(q"SQL
        SELECT COUNT(id)
        FROM session
        WHERE start_timestamp >= ? AND end_timestamp <= ?
SQL",
        TS_START, TS_END
    ).oneValue!ulong();

    report.meanEventsPerSession = db.execute(q"SQL
        SELECT AVG(event_count)
        FROM session
        WHERE start_timestamp >= ? AND end_timestamp <= ?
SQL",
        TS_START, TS_END
    ).oneValue!double();

    report.meanSessionDurationSeconds = db.execute(q"SQL
        SELECT AVG((julianday(end_timestamp) - julianday(start_timestamp)) * 24 * 60 * 60)
        FROM session
        WHERE start_timestamp >= ? AND end_timestamp <= ?
SQL",
        TS_START, TS_END
    ).oneValue!double();

    return report;
}
