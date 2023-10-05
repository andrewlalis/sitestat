module utils;

import std.datetime : SysTime;

string formatSqliteTimestamp(SysTime t) {
    import std.format : format;
    return format!"%04d-%02d-%02d %02d:%02d:%02d.%03d"(
        t.year, t.month, t.day,
        t.hour, t.minute, t.second, t.fracSecs.total!"msecs"
    );
}

string extractOrigin(string url) {
    import std.algorithm : countUntil, startsWith;
    ptrdiff_t idx = countUntil(url, "://");
    if (idx == -1) return null;
    string origin = url[idx + 3 .. $];
    ptrdiff_t trailingSlashIdx = countUntil(origin, "/");
    if (trailingSlashIdx != -1) {
        origin = origin[0 .. trailingSlashIdx];
    }
    if (startsWith(origin, "www.")) {
        origin = origin[4 .. $];
    }
    return origin;
}

unittest {
    assert(extractOrigin("https://www.google.com/search") == "google.com");
    assert(extractOrigin("https://litelist.andrewlalis.com") == "litelist.andrewlalis.com");
}

string dbPath(string origin) {
    return "sitestat-db_" ~ origin ~ ".sqlite";
}

string originFromDbPath(string path) {
    import std.algorithm : countUntil;
    ptrdiff_t idx = countUntil(path, "sitestat-db_");
    if (idx == -1) return null;
    return path[(idx + 12)..$-7];
}

unittest {
    assert(originFromDbPath("sitestat-db__LOCAL_FILESYSTEM_.sqlite") == "_LOCAL_FILESYSTEM_");
}

string[] listAllOrigins(string dir = ".") {
    import std.file;
    import std.array;
    auto app = appender!(string[]);
    foreach (DirEntry entry; dirEntries(dir, SpanMode.shallow, false)) {
        string origin = originFromDbPath(entry.name);
        if (origin !is null) {
            app ~= origin;
        }
    }
    return app[];
}