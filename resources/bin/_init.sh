#!/bin/bash
set -e

files=(
    '/etc/postfix/mysql-virtual-alias-maps.cf'
    '/etc/postfix/mysql-virtual-domains-maps.cf'
    '/etc/postfix/mysql-virtual-mailbox-maps.cf'
    '/etc/amavis/amavis.conf'
    '/etc/dovecot/dovecot-sql.conf.ext'
    '/etc/spamassassin/sql.cf'
    '/etc/postfix/main.cf'
    '/etc/postfix-policyd-spf-python/policyd-spf.conf'
    '/etc/opendmarc/opendmarc.conf'
    '/etc/opendkim/opendkim.conf'
    '/etc/mailname'
)

echo "Initializing the container..."

for file in ${files[@]}
do
    sed -i "s/__REPLACE_DATABASE_HOST__/${MYSQL_PORT_3306_TCP_ADDR}/g" ${file}
    sed -i "s/__REPLACE_DATABASE_PORT__/${MYSQL_PORT_3306_TCP_PORT}/g" ${file}
    sed -i "s/__REPLACE_DATABASE_PASSWORD__/${POSTFIX_MYSQL_PASSWORD}/g" ${file}
    sed -i "s/mail.example.org/${HOSTNAME}/g" ${file}
done

# Create directories if they aren't created
[ ! -f "/etc/aliases" ] && touch /etc/aliases && /usr/bin/newaliases
[ ! -d "/var/run/clamav/" ] && mkdir -p /var/run/clamav/ && chown clamav:clamav /var/run/clamav
[ ! -d "/var/lib/clamav/" ] && mkdir -p /var/lib/clamav/ && chown -R clamav:clamav /var/lib/clamav/ &&
[ ! -d "/var/run/dovecot/" ] && mkdir -p /var/run/dovecot/ && chown dovecot:dovecot /var/run/clamav
[ ! -d "/etc/dovecot/sieve" ] && mkdir -p /etc/dovecot/sieve/global && touch /etc/dovecot/sieve/default.sieve && chown -R vmail:vmail /etc/dovecot/sieve

# Initialise freshclam
/usr/bin/freshclam --quiet --config-file=/etc/clamav/freshclam.conf

# Fix permissions etc
[ "$(stat -c '%U:%G' /etc/opendkim)" != "opendkim:opendkim" ] && chown -R opendkim:opendkim /etc/opendkim
([ ! -G "/etc/amavis/*.*" ] || [ ! -G "/etc/amavis/*/*" ]) && chown root:root /etc/amavis -R
[ "$(stat -c %U:%G /etc/postfix)" != "root:root" ] && chown root:root /etc/postfix -R
[ "$(stat -c %a /etc/postfix)" -ne "640" ] && chmod 640 /etc/postfix -R

touch /root/.init