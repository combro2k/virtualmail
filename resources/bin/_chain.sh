#!/bin/bash
set -e

# First cleanup all the mess!
[ -f "/var/run/rsyslogd.pid" ] && rm /var/run/rsyslogd.pid
[ -d "/var/run/dovecot" ] && [ -f "/var/run/dovecot/master.pid" ] && rm /var/run/dovecot/master.pid
[ -d "/var/run/amavis" ] && [ -f "/var/run/amavis/amavisd.pid" ] && rm /var/run/amavis/amavisd.pid

curl -L https://publicsuffix.org/list/public_suffix_list.dat -o /etc/yenma/effective_tld_names.dat

# Start the base services
supervisorctl start rsyslog 2>&1
supervisorctl start cron 2>&1
supervisorctl start filters: 2>&1
supervisorctl start mail: 2>&1

# Start mailman if the mailman variable is set
test -f "/root/.mailman_init" && supervisorctl start mailman: 2>&1
