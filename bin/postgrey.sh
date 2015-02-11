#!/bin/bash

/usr/sbin/postgrey \
    --unix=/var/spool/postfix/postgrey/socket \
    --whitelist-clients=/etc/postgrey/postgrey_whitelist_clients \
    --whitelist-recipients=/etc/postgrey/postgrey_whitelist_recipients \
    --delay=300