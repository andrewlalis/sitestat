/*
sitestat.js is meant to be included in the <head> like so:

<script src="path/to/sitestat.js" async></script>

See test-site/index.html for an example.
*/

/**
 * The global websocket singleton. It's initialized at the bottom of this script.
 * @type {WebSocket | null}
 */
let WS = null;

/**
 * Sends some JSON object to sitestat.
 * @param {object} data The data to send.
 */
function sendStat(data) {
    if (WS.readyState === WebSocket.OPEN) {
        WS.send(JSON.stringify(data));
    } else {
        console.warn("Couldn't send data because websocket is not open: ", data);
    }
}

/**
 * Handles any event encountered, and sends a small message to sitestat about it.
 * @param {Event} event The event that occurred.
 */
function handleEvent(event) {
    sendStat({
        type: "event",
        event: event.type
    });
}

/**
 * Gets the remote URL that sitestat is running at, from the query params of
 * the script's `src` attribute. Throws an error if such a URL could not be
 * found.
 * @returns {string} The remote URL to connect to.
 */
function getRemoteUrl() {
    const scriptUrl = document.currentScript.src;
    const paramsIdx = scriptUrl.indexOf("?");
    if (paramsIdx !== -1) {
        const paramsStr = scriptUrl.substring(paramsIdx);
        const params = new URLSearchParams(paramsStr);
        const remoteUrl = params.get("remote-url");
        if (remoteUrl !== null) {
            return remoteUrl;
        }
    }
    throw new Error("Missing `remote-url=...` query parameter on script src attribute.")
}



// The main script starts below:
if (window.navigator.webdriver) {
    throw new Error("sitestat disabled for automated user agents.");
}
const remoteUrl = getRemoteUrl();
WS = new WebSocket(`ws://${remoteUrl}/ws`);
WS.onopen = () => {
    // As soon as the connection is established, send some basic information
    // about the current browsing session.
    console.info(
        "📈 Established a connection to %csitestat%c for %cnon-intrusive, non-identifiable%csite analytics. Learn more here: https://github.com/andrewlalis/sitestat",
        "font-weight: bold; font-style: italic; font-size: large; color: #32a852; background-color: #2e2e2e; padding: 5px;",
        "",
        "font-style: italic;"
    );
    sendStat({
        type: "ident",
        href: window.location.href,
        userAgent: window.navigator.userAgent,
        viewport: {
            width: window.innerWidth,
            height: window.innerHeight
        }
    });
}
WS.onerror = console.error;

// Register various event listeners.
const events = ["click", "keyup", "keydown", "scroll", "copy"];
for (let i = 0; i < events.length; i++) {
    document.addEventListener(events[i], handleEvent);
}
