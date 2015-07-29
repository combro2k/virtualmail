#!/bin/bash

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

sed -i "s/mail.example.org/${HOSTNAME}/g" /etc/nginx/conf.d/default.conf

if [[ ! -d "/var/run/mailman" ]]
then
    mkdir -p /var/run/mailman
fi

if [[ ! -f "/var/mailman/postorius.db" ]]
then
    if [[ -z "${MAILMAN_PASSWORD}" ]]
    then
        MAILMAN_PASSWORD=$(pwgen -1 12)
    fi

    echo ${MAILMAN_PASSWORD} > /var/mailman/.postorius_password

    if [[ -z "${MAILMAN_EMAIL}" ]]
    then
        MAILMAN_EMAIL=admin@${MAILINGLIST}
    fi

    if [[ -z "${MAILMAN_USERNAME}" ]]
    then
        MAILMAN_USERNAME=admin
    fi

    /opt/postorius/bin/python /opt/postorius_standalone/manage.py syncdb --noinput
    /opt/postorius/bin/python /opt/postorius_standalone/manage.py collectstatic --noinput
    echo "from django.contrib.auth.models import User; User.objects.create_superuser('admin', '${MAILMAN_EMAIL}', '${MAILMAN_PASSWORD}')" \
        | /opt/postorius/bin/python /opt/postorius_standalone/manage.py shell
fi

echo Starting postorius...
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
start-stop-daemon --start --pidfile=/var/run/mailman/master.pid --exec "/opt/mailman/bin/python" -- /opt/mailman/bin/mailman -C /etc/mailman.cfg start

sleep infinity