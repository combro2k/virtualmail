#!/bin/bash

if [[ -d "/var/run/amavis" ]] && [[ -f "/var/run/amavis/amavisd.pid" ]]
then
    rm /var/run/amavis/amavisd.pid
fi

supervisorctl start amavisd
sleep 5
supervisorctl start amavisd-milter
sleep infinity
