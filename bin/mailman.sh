#!/bin/bash
# call "mailman stop" when exiting
trap "{ echo Stopping Mailman; /opt/mailman/bin/mailman stop; nginx -s stop; exit 0; }" EXIT

service fcgiwrap start
nginx

# start postfix
/opt/mailman/bin/mailman start
# avoid exiting

sleep infinity
