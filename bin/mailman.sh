#!/bin/bash
# call "mailman stop" when exiting
trap "{ echo Stopping Mailman; /usr/local/bin/mailman stop; exit 0; }" EXIT

# start postfix
/usr/local/bin/mailman start
# avoid exiting

sleep infinity
