#!/bin/bash
# call "mailman stop" when exiting
trap "{ echo Stopping Mailman; /opt/mailman/bin/mailman stop; kill `cat /var/mailman/mailman3.pid`; rm /var/mailman/mailman3.pid; nginx -s stop; exit 0; }" EXIT

sed -i "s/mail.example.org/${HOSTNAME}/g" /etc/nginx/conf.d/postorius-nginx.conf

if [[ -f "/opt/postorius_standalone/postorius.db" ]]
then
    /opt/postorius/bin/python /opt/postorius_standalone/manage.py syncdb --noinput
fi

/opt/postorius/bin/python /opt/postorius_standalone/manage.py runfcgi socket=/var/mailman/mailman3.sock method=prefork pidfile=/var/mailman/mailman3.pid umask=000
nginx

# start postfix
/opt/mailman/bin/mailman -C /etc/mailman.cfg start --force
# avoid exiting

sleep infinity
