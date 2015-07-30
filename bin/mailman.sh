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

if [[ -z "${MAILMAN_PASSWORD}" ]]
then
    export MAILMAN_PASSWORD=$(pwgen -1 12)
fi

echo ${MAILMAN_PASSWORD} > /var/mailman/.postorius_password

if [[ -z "${MAILMAN_EMAIL}" ]]
then
    export MAILMAN_EMAIL=admin@${MAILINGLIST}
fi

if [[ -z "${MAILMAN_USERNAME}" ]]
then
    MAILMAN_USERNAME=admin
fi

sed -i "s/mail.example.org/${MAILINGLIST}/g" /etc/nginx/conf.d/nginx-postorius.conf
sed -i "s/__MAILMAN_EMAIL__/${MAILMAN_EMAIL}/g" /etc/nginx/conf.d/nginx-postorius.conf

if [[ ! -d "/var/run/mailman" ]]
then
    mkdir -p /var/run/mailman
fi

if [[ ! -f "/var/mailman/data/postorius.db" ]]
then
    /opt/postorius/bin/python /opt/postorius_standalone/manage.py syncdb --noinput
    echo "from django.contrib.auth.models import User; User.objects.create_superuser('admin', '${MAILMAN_EMAIL}', '${MAILMAN_PASSWORD}')" \
        | /opt/postorius/bin/python /opt/postorius_standalone/manage.py shell
fi

if [[ ! -d "/opt/postorius_standalone/static/admin" ]]
then
    /opt/postorius/bin/python /opt/postorius_standalone/manage.py collectstatic --noinput
    /opt/postorius/bin/python /opt/postorius_standalone/manage.py compress
fi

echo Starting postorius
start-stop-daemon --start --pidfile=/var/run/mailman/postorius.pid --exec \
    "/opt/postorius/bin/python" -- \
    /opt/postorius_standalone/manage.py runfcgi \
        pidfile=/var/run/mailman/postorius.pid \
        socket=/var/run/postorius.sock \
        method=prefork \
        umask=000

echo Starting nginx...
nginx

echo Starting mailman...
start-stop-daemon --start --pidfile=/var/run/mailman/master.pid --exec "/opt/mailman/bin/python" -- /opt/mailman/bin/mailman -C /etc/mailman.cfg start --force

sleep infinity