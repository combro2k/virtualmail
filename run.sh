#!/bin/bash
docker stop postfix
docker rm postfix
docker run -d --link mysql:mysql -e "POSTFIX_MYSQL_PASSWORD=postfixadmin" -h mail.combro2k.nl -v /var/vmail:/var/vmail --name postfix combro2k/postfix
