#!/bin/bash
set -e

# First cleanup all the mess!

/usr/local/bin/_cleanup.sh

# Start the base services
supervisorctl start rsyslog
supervisorctl start cron
supervisorctl start filters:
supervisorctl start mail:

# Start mailman if the mailman variable is set
test -f "/root/.mailman_init" && supervisorctl start mailman:
