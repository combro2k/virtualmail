#!/bin/bash

chown -R sympa:sympa /home/sympa

sed -i "s/mail.example.org/${HOSTNAME}/g" /etc/nginx/conf.d/sympa-nginx.conf
sed -i "s/mail.example.org/${MAILINGLIST}/g" /etc/sympa.conf
sed -i "s/__REPLACE_DATABASE_HOST__/${MYSQL_PORT_3306_TCP_ADDR}/g" /etc/sympa.conf
sed -i "s/__REPLACE_DATABASE_PASSWORD__/${SYMPA_MYSQL_PASSWORD}/g" /etc/sympa.conf

service fcgiwrap start
nginx

/usr/bin/perl /home/sympa/bin/bulk.pl
/usr/bin/perl /home/sympa/bin/archived.pl
/usr/bin/perl /home/sympa/bin/bounced.pl
/usr/bin/perl /home/sympa/bin/task_manager.pl
/usr/bin/perl /home/sympa/bin/sympa.pl --foreground