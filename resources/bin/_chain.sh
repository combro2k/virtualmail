#!/bin/bash
set -e

# First cleanup all the mess!

. /usr/local/bin/_cleanup.sh

filters=(
    'greylist'
    'opendkim'
    'opendmarc'
    'opendmarc'
    'spamassassin'
    'clamd'
    'milter-manager'
)

supervisorctl start rsyslog
supervisorctl start cron
supervisorctl start ${filters[@]}
supervisorctl start dovecot postfix

# Start mailman if the mailman is initialised
test -f "/root/.mailman_init" && supervisorctl start mailman