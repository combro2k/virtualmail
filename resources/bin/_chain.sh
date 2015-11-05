#!/bin/bash

set -e

# First cleanup all the mess!
[ -f "/var/run/rsyslogd.pid" ] && rm /var/run/rsyslogd.pid
[ -d "/var/run/dovecot" ] && [ -f "/var/run/dovecot/master.pid" ] && rm /var/run/dovecot/master.pid
[ -d "/var/run/amavis" ] && [ -f "/var/run/amavis/amavisd.pid" ] && rm /var/run/amavis/amavisd.pid

# SSL setup !
if [ -f /data/ssl/ssl.pem ]; then
    postconf 'smtpd_tls_key_file=/data/ssl/ssl.pem'
    postconf 'smtpd_tls_cert_file=/data/ssl/ssl.pem'

    sed -i '/^ssl_cert =.*/d' /etc/dovecot/conf.d/10-ssl.conf
    sed -i '/^ssl_key =.*/d' /etc/dovecot/conf.d/10-ssl.conf

    cat >> /etc/dovecot/conf.d/10-ssl.conf <<< 'ssl_cert = </data/ssl/ssl.pem'
    cat >> /etc/dovecot/conf.d/10-ssl.conf <<< 'ssl_key = </data/ssl/ssl.pem'
elif [ -f /data/ssl/ssl.key ] && [ -f /data/ssl/ssl.crt ]; then
    postconf 'smtpd_tls_key_file=/data/ssl/ssl.key'
    postconf 'smtpd_tls_cert_file=/data/ssl/ssl.crt'

    sed -i '/^ssl_cert =.*/d' /etc/dovecot/conf.d/10-ssl.conf
    sed -i '/^ssl_key =.*/d' /etc/dovecot/conf.d/10-ssl.conf

    cat >> /etc/dovecot/conf.d/10-ssl.conf <<< 'ssl_cert = </data/ssl/ssl.key'
    cat >> /etc/dovecot/conf.d/10-ssl.conf <<< 'ssl_key = </data/ssl/ssl.crt'
fi

# Start the base services
supervisorctl start rsyslog
supervisorctl start cron
supervisorctl start filters:
supervisorctl start mail:

# Start mailman if the mailman variable is set
test -f "/root/.mailman_init" && supervisorctl start mailman:
