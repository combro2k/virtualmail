#!/bin/bash

trap "{ echo Stopping opendmarc; kill $(pidof /usr/sbin/opendmarc); sleep 3; exit 0; }" EXIT

/usr/sbin/opendmarc -c /etc/opendmarc/opendmarc.conf -u opendmarc -P /var/run/opendmarc/opendmarc.pid -f -l