#!/bin/bash
# call "postfix stop" when exiting
trap "{ echo Stopping postfix; /usr/sbin/postfix stop; exit 0; }" EXIT

# start postfix
/usr/sbin/postfix -c /etc/postfix start
# avoid exiting

if [[ ! -z "${MAILINGLIST}" ]]
then
    supervisorctl start mailman
fi

sleep infinity   
