#!/bin/bash

set -e

echo "Initializing the container..."

postconf "myhostname = ${HOSTNAME}"
echo ${HOSTNAME} > /etc/mailname

# Create directories if they aren't created
if [ ! -f /etc/aliases ]; then
    touch /etc/aliases
    /usr/bin/newaliases
fi

if [ ! -d /var/run/clamav ]; then
    mkdir -p /var/run/clamav/
    chown clamav:clamav /var/run/clamav
fi

if [ ! -d /var/lib/clamav ]; then
    mkdir -p /var/lib/clamav/
    chown -R clamav:clamav /var/lib/clamav/
fi

if [ ! -d /var/run/dovecot ]; then
    mkdir -p /var/run/dovecot/
    chown dovecot:dovecot /var/run/clamav
fi

if [ ! -d /etc/dovecot/sieve ]; then
    mkdir -p /etc/dovecot/sieve/global
    touch /etc/dovecot/sieve/default.sieve
    chown -R vmail:vmail /etc/dovecot/sieve
fi

# Initialise freshclam
/usr/bin/freshclam --quiet --config-file=/etc/clamav/freshclam.conf

touch /root/.init
