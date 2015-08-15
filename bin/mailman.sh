#!/bin/bash

if [[ -f "/var/run/mailman/master.pid" ]]
then
    echo Mailman already running...

    exit 1
fi

function stop {
    echo Stopping mailman...
    start-stop-daemon --stop --oknodo --pidfile /var/run/mailman/master.pid
    rm /var/run/mailman/master.pid

    echo Stopping postorius...
    start-stop-daemon --stop --oknodo --pidfile /var/run/mailman/postorius.pid
    rm /var/run/mailman/postorius.pid

    echo Stopping nginx...
    nginx -s stop

    exit 0
}

trap stop EXIT

test ! -d "/var/mailman/data" && /opt/mailman/bin/mailman help > /dev/null 2>&1

if [[ ! -f "/var/mailman/data/postorius_password" ]]
then
    test -z "${MAILMAN_PASSWORD}" && export MAILMAN_PASSWORD=$(pwgen -1 12)
    echo ${MAILMAN_PASSWORD} | tee /var/mailman/data/postorius_password > /dev/null
else
    export MAILMAN_PASSWORD=$(cat /var/mailman/data/postorius_password)
fi

if [[ ! -f "/var/mailman/data/postorius_secretkey" ]]
then
    test -z "${POSTORIUS_SECRET_KEY}" && export POSTORIUS_SECRET_KEY=$(pwgen -1 24)
    echo ${POSTORIUS_SECRET_KEY} | tee /var/mailman/data/postorius_secretkey
else
    export POSTORIUS_SECRET_KEY=$(cat /var/mailman/data/postorius_secretkey)
fi

test -z "${MAILMAN_EMAIL}" && export MAILMAN_EMAIL=admin@${MAILINGLIST}
test -z "${MAILMAN_USERNAME}" && MAILMAN_USERNAME=admin

sed -i "s/mail.example.org/${MAILINGLIST}/g" /etc/nginx/conf.d/nginx-postorius.conf
sed -i "s/mail.example.org/${MAILINGLIST}/g" /opt/postorius_standalone/hyperkitty.cfg
sed -i "s/SecretArchiverAPIKey/${MAILMAN_PASSWORD}/g" /opt/postorius_standalone/hyperkitty.cfg

if [[ ! -f "/var/mailman/data/postorius_settings.py" ]]
then
    touch /var/mailman/data/postorius_settings.py
    echo "SECRET_KEY = '${POSTORIUS_SECRET_KEY}'" | tee -a /var/mailman/data/postorius_settings.py > /dev/null
    echo "MAILMAN_ARCHIVER_KEY = '${MAILMAN_PASSWORD}'" | tee -a /var/mailman/data/postorius_settings.py > /dev/null
fi

test ! -L "/opt/postorius_standalone/postorius_settings.py" -o ! -f /opt/postorius_standalone/postorius_settings.py && \
    ln -vfs /var/mailman/data/postorius_settings.py /opt/postorius_standalone/postorius_settings.py

test ! -d "/var/run/mailman" && mkdir -p /var/run/mailman

if [[ ! -f "/var/mailman/data/postorius.db" ]]
then
    /opt/postorius/bin/python /opt/postorius_standalone/manage.py syncdb --noinput
    echo "from django.contrib.auth.models import User; User.objects.create_superuser('${MAILMAN_USERNAME}', '${MAILMAN_EMAIL}', '${MAILMAN_PASSWORD}')" | /opt/postorius/bin/python /opt/postorius_standalone/manage.py shell
    echo "Created an postorius user ${MAILMAN_USERNAME} with password ${MAILMAN_PASSWORD}"
fi

if [[ ! -d "/opt/postorius_standalone/static/admin" ]]
then
    /opt/postorius/bin/python /opt/postorius_standalone/manage.py collectstatic --noinput
    /opt/postorius/bin/python /opt/postorius_standalone/manage.py compress
fi

echo Starting postorius
start-stop-daemon --start --pidfile=/var/run/mailman/postorius.pid --exec "/opt/postorius/bin/python" -- /opt/postorius_standalone/manage.py runfcgi pidfile=/var/run/mailman/postorius.pid socket=/var/run/postorius.sock method=prefork umask=000

echo Starting nginx...
nginx

echo Starting mailman...
start-stop-daemon --start --pidfile=/var/run/mailman/master.pid --exec "/opt/mailman/bin/python" -- /opt/mailman/bin/mailman -C /etc/mailman.cfg start --force

sleep infinity
