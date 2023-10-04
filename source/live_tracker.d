module live_tracker;

import data;
import handy_httpd.components.websocket.handler;
import slf4d;
import std.uuid;
import std.datetime;
import std.json;
import std.string;
import std.parallelism;
import core.sync.rwmutex;

/**
 * A websocket message handler that keeps track of each connected session, and
 * records information about that session's activities.
 */
class LiveTracker : WebSocketMessageHandler {
    private StatSession[UUID] sessions;
    static immutable uint DEFAULT_MIN_SESSION_DURATION = 1000;
    private immutable uint minSessionDurationMillis;
    private TaskPool sessionPersistencePool;
    private ReadWriteMutex sessionsMutex;

    this(uint minSessionDurationMillis = DEFAULT_MIN_SESSION_DURATION) {
        this.minSessionDurationMillis = minSessionDurationMillis;
        this.sessionPersistencePool = new TaskPool(1);
        this.sessionsMutex = new ReadWriteMutex();
    }

    override void onConnectionEstablished(WebSocketConnection conn) {
        debugF!"Connection established: %s"(conn.id);
        synchronized(sessionsMutex.writer) {
            sessions[conn.id] = StatSession(
                conn.id,
                Clock.currTime(UTC())
            );
        }
        infoF!"Started tracking session %s"(conn.id);
    }

    override void onTextMessage(WebSocketTextMessage msg) {
        StatSession* session;
        synchronized(sessionsMutex.reader) {
            session = msg.conn.id in sessions;
        }
        if (session is null) {
            warnF!"Got a websocket text message from a client without a session: %s"(msg.conn.id);
            return;
        }
        JSONValue obj = parseJSON(msg.payload);
        immutable string msgType = obj.object["type"].str;
        if (msgType == MessageTypes.IDENT) {
            handleIdent(obj, session);
        } else if (msgType == MessageTypes.EVENT) {
            session.eventCount++;
            // session.events ~= EventRecord(
            //     Clock.currTime(UTC()),
            //     obj.object["event"].str
            // );
        }
    }

    override void onConnectionClosed(WebSocketConnection conn) {
        StatSession* session;
        synchronized(sessionsMutex.reader) {
            session = conn.id in sessions;
        }
        if (session !is null && session.isValid) {
            SysTime endTimestamp = Clock.currTime(UTC());
            Duration dur = endTimestamp - session.connectedAt;
            if (dur.total!"msecs" >= minSessionDurationMillis) {
                infoF!"Session lasted %d seconds, %d events."(dur.total!"seconds", session.eventCount);
            }
            immutable storedSession = StoredSession(
                -1,
                session.connectedAt,
                endTimestamp,
                session.url,
                session.href,
                session.userAgent,
                session.eventCount
            );
            this.sessionPersistencePool.put(task!storeSession(storedSession));
        }
        synchronized(sessionsMutex.writer) {
            sessions.remove(conn.id);
        }
    }

    private void handleIdent(JSONValue msg, StatSession* session) {
        string fullUrl = msg.object["href"].str;
        session.href = fullUrl;
        ptrdiff_t paramsIdx = std.string.indexOf(fullUrl, '?');
        if (paramsIdx == -1) {
            session.url = fullUrl;
        } else {
            session.url = fullUrl[0 .. paramsIdx];
        }
        session.userAgent = msg.object["userAgent"].str;
    }
}

private enum MessageTypes : string {
    IDENT = "ident",
    EVENT = "event"
}

struct StatSession {
    UUID id;
    SysTime connectedAt;
    string url = null;
    string href = null;
    string userAgent = null;
    uint eventCount = 0;

    bool isValid() const {
        return url !is null && href !is null && userAgent !is null;
    }
}

struct EventRecord {
    SysTime timestamp;
    string eventType;
}
