#!/bin/bash
# call "mailman stop" when exiting
trap "{ echo Stopping Mailman; /opt/mailman/bin/mailman stop; exit 0; }" EXIT

# start postfix
/opt/mailman/bin/mailman start
# avoid exiting

sleep infinity
