module live_tracker;

import handy_httpd.components.websocket;
import slf4d;
import std.uuid;
import std.datetime;
import std.json;
import std.string;

/**
 * A websocket message handler that keeps track of each connected session, and
 * records information about that session's activities.
 */
class LiveTracker : WebSocketMessageHandler {
    private StatSession[UUID] sessions;
    private immutable uint minSessionDurationMillis = 1000;

    override void onConnectionEstablished(WebSocketConnection conn) {
        debugF!"Connection established: %s"(conn.getId());
        sessions[conn.getId()] = StatSession(
            conn.getId(),
            Clock.currTime(UTC())
        );
    }

    override void onTextMessage(WebSocketTextMessage msg) {
        debugF!"Got message from %s: %s"(msg.conn.getId(), msg.payload);
        StatSession* session = msg.conn.getId() in sessions;
        if (session is null) {
            warnF!"Got a websocket text message from a client without a session: %s"(msg.conn.getId());
            return;
        }
        JSONValue obj = parseJSON(msg.payload);
        immutable string msgType = obj.object["type"].str;
        if (msgType == MessageTypes.IDENT) {
            string fullUrl = obj.object["href"].str;
            session.href = fullUrl;
            ptrdiff_t paramsIdx = std.string.indexOf(fullUrl, '?');
            if (paramsIdx == -1) {
                session.url = fullUrl;
            } else {
                session.url = fullUrl[0 .. paramsIdx];
            }
            session.userAgent = obj.object["userAgent"].str;
        } else if (msgType == MessageTypes.EVENT) {
            session.events ~= EventRecord(
                Clock.currTime(UTC()),
                obj.object["event"].str
            );
        }
    }

    override void onConnectionClosed(WebSocketConnection conn) {
        debugF!"Connection closed: %s"(conn.getId());
        StatSession* session = conn.getId() in sessions;
        if (session !is null && session.isValid) {
            Duration dur = Clock.currTime(UTC()) - session.connectedAt;
            if (dur.total!"msecs" >= minSessionDurationMillis) {
                infoF!"Session lasted %d seconds, %d events."(dur.total!"seconds", session.events.length);
                infoF!"%s, %s"(session.href, session.userAgent);
            }
        }
        sessions.remove(conn.getId());
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
    EventRecord[] events;

    bool isValid() const {
        return url !is null && href !is null && userAgent !is null;
    }
}

struct EventRecord {
    SysTime timestamp;
    string eventType;
}
