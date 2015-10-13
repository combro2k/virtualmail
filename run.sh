#!/bin/bash

if ! docker ps -a --filter="name=mysql" --format='{{.Names}}' | grep -i mysql; then
    docker run -d -e MYSQL_ROOT_PASSWORD=test --name mysql mysql:latest
else
    docker start mysql
fi 2>&1 > /dev/null

if docker ps -a --filter="name=virtualmail" --format='{{.Names}}' | grep -i virtualmail; then
	docker rm virtualmail
fi 2>&1 > /dev/null

docker run -ti --rm --link mysql:mysql -e POSTFIX_MYSQL_PASSWORD=root -h mail.example.org --name virtualmail combro2k/virtualmail:enma ${@}
docker stop mysql
