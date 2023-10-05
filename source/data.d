module data;

import utils;
import std.file;
import std.datetime;
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
    stmt.bind(1, formatSqliteTimestamp(s.startTimestamp));
    stmt.bind(2, formatSqliteTimestamp(s.endTimestamp));
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
