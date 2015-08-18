#!/bin/bash
set -e

files=(
    '/etc/nginx/conf.d/nginx-postorius.conf'
    '/opt/postorius_standalone/hyperkitty.cfg'
)

echo "Initializing the mailman in the container..."

[ ! -d "/var/run/mailman" ] && mkdir -p /var/run/mailman
[ ! "$(ls -A /etc/mailman)" ] && tar xzf "/root/config.tar.gz" -C / etc/mailman
[ ! "$(ls -A /var/mailman)" ] && /opt/mailman/bin/mailman --config /etc/mailman/mailman.cfg help 2>&1 > /dev/null

[ -f "/var/mailman/data/postorius_password" ] && export MAILMAN_PASSWORD=$(cat /var/mailman/data/postorius_password)
[ ! -f "/var/mailman/data/postorius_password" ] && [ -z "${MAILMAN_PASSWORD}" ] && export MAILMAN_PASSWORD=$(pwgen -1 12)
[ ! -f "/var/mailman/data/postorius_password" ] && [ ! -z "${MAILMAN_PASSWORD}" ] && echo "${MAILMAN_PASSWORD}" > /var/mailman/data/postorius_password

[ -f "/var/mailman/data/postorius_secretkey" ] && export MAILMAN_PASSWORD=$(cat /var/mailman/data/postorius_secretkey)
[  ! -f "/var/mailman/data/postorius_secretkey" ] && [ -z "${POSTORIUS_SECRET_KEY}" ] && export POSTORIUS_SECRET_KEY=$(pwgen -1 12)
[  ! -f "/var/mailman/data/postorius_secretkey" ] && [ ! -z "${POSTORIUS_SECRET_KEY}" ] && echo "${POSTORIUS_SECRET_KEY}" > /var/mailman/data/postorius_password

[ -z "${MAILMAN_EMAIL}" ] && export MAILMAN_EMAIL=admin@${MAILINGLIST}
[ -z "${MAILMAN_USERNAME}" ] && export MAILMAN_USERNAME=admin

for file in ${files[@]}
do
     [ ! -z "${MAILINGLIST}" ] && sed -i "s/mail.example.org/${MAILINGLIST}/g" ${file}
     [ ! -z "${MAILMAN_PASSWORD}" ] && sed -i "s/SecretArchiverAPIKey/${MAILMAN_PASSWORD}/g" ${file}
done

if [ ! -f "/var/mailman/data/postorius_settings.py" ]
then
    echo -e "SECRET_KEY = '${POSTORIUS_SECRET_KEY}'\nMAILMAN_ARCHIVER_KEY = '${MAILMAN_PASSWORD}'" > /var/mailman/data/postorius_settings.py
fi

if [ ! -L "/opt/postorius_standalone/postorius_settings.py" ] || [ ! -f "/opt/postorius_standalone/postorius_settings.py" ]
then
    ln -vfs /var/mailman/data/postorius_settings.py /opt/postorius_standalone/postorius_settings.py
fi

if [ ! -f "/var/mailman/data/postorius.db" ]
then
    /opt/postorius_standalone/manage.py syncdb --noinput
    echo "from django.contrib.auth.models import User; User.objects.create_superuser('${MAILMAN_USERNAME}', '${MAILMAN_EMAIL}', '${MAILMAN_PASSWORD}')" | /opt/postorius_standalone/manage.py shell
    echo "Created an postorius user ${MAILMAN_USERNAME} with password ${MAILMAN_PASSWORD}"
fi

if [ ! -d "/opt/postorius_standalone/static/admin" ]
then
    /opt/postorius_standalone/manage.py collectstatic --noinput
    /opt/postorius_standalone/manage.py compress
fi

touch /root/.mailman_init