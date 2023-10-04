module data;

import std.file;
import std.datetime;
import std.format;
import d2sqlite3;

static immutable FS_ORIGIN = "_LOCAL_FILESYSTEM_";

struct StoredSession {
    long id;
    SysTime startTimestamp;
    SysTime endTimestamp;
    string url;
    string fullUrl;
    string userAgent;
    long eventCount;
}

void storeSession(StoredSession s) {
    string origin = extractOrigin(s.url);
    if (origin is null) {
        throw new Exception("Unable to parse origin from url: " ~ s.url);
    } else if (origin.length == 0) {
        origin = FS_ORIGIN;
    }
    Database db = getOrCreateDatabase(origin);
    Statement stmt = db.prepare(
        "INSERT INTO session " ~
        "(start_timestamp, end_timestamp, url, full_url, user_agent, event_count) " ~
        "VALUES (?, ?, ?, ?, ?, ?)"
    );
    stmt.bind(1, formatTimestamp(s.startTimestamp));
    stmt.bind(2, formatTimestamp(s.endTimestamp));
    stmt.bind(3, s.url);
    stmt.bind(4, s.fullUrl);
    stmt.bind(5, s.userAgent);
    stmt.bind(6, s.eventCount);
    stmt.execute();
}

Database getOrCreateDatabase(string origin) {
    string filename = dbPath(origin);
    if (!exists(filename)) {
        initDb(filename);
    }
    return Database(filename, SQLITE_OPEN_READWRITE);
}

private void initDb(string path) {
    if (exists(path)) std.file.remove(path);
    Database db = Database(path);
    db.run(q"SQL
        CREATE TABLE session (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            start_timestamp TEXT NOT NULL,
            end_timestamp TEXT NOT NULL,
            url TEXT NOT NULL,
            full_url TEXT NOT NULL,
            user_agent TEXT NOT NULL,
            event_count INTEGER NOT NULL
        );
SQL"
    );
}

ulong countSessions(string origin) {
    Database db = getOrCreateDatabase(origin);
    return db.execute("SELECT COUNT(id) FROM session;").oneValue!ulong;
}

private string formatTimestamp(SysTime t) {
    return format!"%04d-%02d-%02d %02d:%02d:%02d"(
        t.year, t.month, t.day,
        t.hour, t.minute, t.second
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
