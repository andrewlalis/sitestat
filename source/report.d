module report;

import std.stdio;
import std.datetime;
import std.algorithm;
import std.array;
import data;

void makeReport(string[] sites) {
    string[] sitesToReport = sites.length == 0 ? listAllOrigins() : sites;
    writeln("Creating report for " ~ createSiteNamesSummary(sitesToReport) ~ ".");
    foreach (site; sitesToReport) {
        writeln("Site: " ~ site);
        writefln!"\nTotal sessions recorded: %d"(countSessions(site));
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

    ulong totalVisitors;
}
