#!/bin/bash
set -e

[ -f "/var/run/rsyslogd.pid" ] && rm /var/run/rsyslogd.pid
[ -d "/var/run/dovecot" ] && [ -f "/var/run/dovecot/master.pid" ] && rm /var/run/dovecot/master.pid
[ -d "/var/run/amavis" ] && [ -f "/var/run/amavis/amavisd.pid" ] && rm /var/run/amavis/amavisd.pid
