#!/bin/bash
if ! docker ps -a --filter="name=mariadb" --format='{{.Names}}' | grep -i mariadb; then
    docker run -d -e MYSQL_ROOT_PASSWORD=test --name  mariadb -v /tmp/mariadb:/var/lib/mysql mariadb:latest
else
    docker start mariadb
fi 2>&1 > /dev/null

if docker ps -a --filter="name=virtualmail" --format='{{.Names}}' | grep -i virtualmail; then
    docker rm virtualmail
fi 2>&1 > /dev/null

docker run \
    -ti \
    --rm \
    --name \
    --link mariadb:mysql \
    -e 'POSTFIX_MYSQL_DATABASE=posty' \
    -e 'POSTFIX_MYSQL_USER=root' \
    -e 'POSTFIX_MYSQL_PASSWORD=test' \
    -h 'mail.hexxie.com' \
    -e "MAILINGLIST=list.hexxie.com" \
    virtualmail \
    combro2k/virtualmail:latest ${@}
