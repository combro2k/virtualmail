#!/bin/bash
set -e

test -d "/var/run/dovecot" -a -f "/var/run/dovecot/master.pid" && rm /var/run/dovecot/master.pid
test -f "/var/run/rsyslogd.pid" && rm /var/run/rsyslogd.pid
test -d "/var/run/amavis" -a -f "/var/run/amavis/amavisd.pid" && rm /var/run/amavis/amavisd.pid

# Fix permissions etc
chown -R opendkim:opendkim /etc/opendkim
