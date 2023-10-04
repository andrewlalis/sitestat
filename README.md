# sitestat
A simple webserver and script for tracking basic, non-intrusive site statistics using a websocket.

Simply run sitestat on your server, and add `<script src="path/to/sitestat.js" async></script>` to the `<head>` of any page you'd like to track statistics on.

It will record some basic information about each user's interaction session on each page, and save those sessions into an SQLite3 database for later analysis.

## What Information is Collected?
Right now, the following information is collected from each user's session on a page monitored by sitestat:

- The time they opened the page.
- The time they closed the page (telling us how long they viewed the page).
- Their user agent (browser name and associated details).
- The exact URL they visited.
- Certain anonymized actions done by the user on the page, like mouse clicks, button presses, copy-to-clipboard, etc. From any action, we simply save the name of the action, and no other information.
