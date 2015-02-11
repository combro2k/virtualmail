#!/bin/bash -e

chown -R opendkim:opendkim /etc/opendkim

/usr/sbin/opendkim -f -x /etc/opendkim/opendkim.conf