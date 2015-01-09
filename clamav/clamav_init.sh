#!/bin/bash

mkdir /var/run/clamav/ && chown clamav:clamav /var/run/clamav
mkdir -p /var/lib/clamav/
chown -R clamav:clamav /var/lib/clamav/

supervisorctl start freshclam
supervisorctl start clamd
sleep 10