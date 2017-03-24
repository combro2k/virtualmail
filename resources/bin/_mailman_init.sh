#!/bin/bash

set -e

files=(
    '/etc/nginx/conf.d/nginx-postorius.conf'
    '/opt/postorius_standalone/hyperkitty.cfg'
)

echo "Initializing the mailman in the container..."

if [ ! -d /var/run/mailman ]; then
    mkdir -p /var/run/mailman
fi
if ! ls -A /etc/mailman > /dev/null 2>&1; then
    tar xzf "/root/config.tar.gz" -C / etc/mailman
fi
if [ ! -d /var/mailman ]; then
    mkdir -p /var/mailman
fi
if ! ls -A /var/mailman > /dev/null 2>&1; then
    /opt/mailman/bin/mailman --config /etc/mailman/mailman.cfg help > /dev/null 2>&1
fi

if [ -f /var/mailman/data/postorius_password ]; then
    export MAILMAN_PASSWORD=$(cat /var/mailman/data/postorius_password)
elif [ ! -f /var/mailman/data/postorius_password ] && [ -z ${MAILMAN_PASSWORD} ]; then
    export MAILMAN_PASSWORD=$(pwgen -1 12)
    echo "${MAILMAN_PASSWORD}" > /var/mailman/data/postorius_password
elif [ ! -f /var/mailman/data/postorius_password ] && [ ! -z ${MAILMAN_PASSWORD} ]; then
    echo "${MAILMAN_PASSWORD}" > /var/mailman/data/postorius_password
fi

if [ -f /var/mailman/data/postorius_secretkey ]; then
    export MAILMAN_PASSWORD=$(cat /var/mailman/data/postorius_secretkey)
elif [ ! -f /var/mailman/data/postorius_secretkey ] && [ -z "${POSTORIUS_SECRET_KEY}" ]; then
    export POSTORIUS_SECRET_KEY=$(pwgen -1 12)
    echo "${POSTORIUS_SECRET_KEY}" > /var/mailman/data/postorius_password
elif [ ! -f /var/mailman/data/postorius_secretkey ] && [ ! -z "${POSTORIUS_SECRET_KEY}" ]; then
    echo "${POSTORIUS_SECRET_KEY}" > /var/mailman/data/postorius_password
fi

if [ -z ${MAILMAN_EMAIL} ]; then
    export MAILMAN_EMAIL=admin@${MAILINGLIST}
fi
if [ -z ${MAILMAN_USERNAME} ]; then
    export MAILMAN_USERNAME=admin
fi

for file in ${files[@]}; do
    if [ ! -z ${MAILINGLIST} ]; then
        sed -i "s/mail.example.org/${MAILINGLIST}/g" ${file}
    fi
    if [ ! -z ${MAILMAN_PASSWORD} ]; then
        sed -i "s/SecretArchiverAPIKey/${MAILMAN_PASSWORD}/g" ${file}
    fi
done

if [ ! -f /var/mailman/data/postorius_settings.py ]; then
    echo -e "SECRET_KEY = '${POSTORIUS_SECRET_KEY}'\nMAILMAN_ARCHIVER_KEY = '${MAILMAN_PASSWORD}'" > /var/mailman/data/postorius_settings.py
fi

if [ ! -L /opt/postorius_standalone/postorius_settings.py ] || [ ! -f /opt/postorius_standalone/postorius_settings.py ]; then
    ln -vfs /var/mailman/data/postorius_settings.py /opt/postorius_standalone/postorius_settings.py
fi

if [ ! -f /var/mailman/data/postorius.db ]; then
    /opt/postorius_standalone/manage.py syncdb --noinput
    /opt/postorius_standalone/manage.py shell <<< "from django.contrib.auth.models import User; User.objects.create_superuser('${MAILMAN_USERNAME}', '${MAILMAN_EMAIL}', '${MAILMAN_PASSWORD}')"
    echo "Created an postorius user ${MAILMAN_USERNAME} with password ${MAILMAN_PASSWORD}"
fi

if [ ! -d /opt/postorius_standalone/static/admin ]; then
    /opt/postorius_standalone/manage.py collectstatic --noinput
    /opt/postorius_standalone/manage.py compress
fi

postconf 'relay_domains = $mydestination, hash:/var/mailman/data/postfix_domains'
postconf 'transport_maps = hash:/var/mailman/data/postfix_lmtp'
postconf 'local_recipient_maps = hash:/var/mailman/data/postfix_lmtp'

touch /root/.mailman_init
