virtualmail
==============

Virtualmail on Docker.

## Requirement

-   MySQL
-   Docker 0.8 or higher

## Install

    docker build -t combro2k/virtualmail .
    sudo groupadd -g 1000 vmail
    sudo useradd -g vmail -u 1000 vmail -d /var/vmail
    sudo mkdir /var/vmail
    sudo chown vmail:vmail /var/vmail

## How to use

    docker run -d
      -e "MYSQL_PORT_3306_TCP_ADDR=172.0.0.24" \
      -e "MYSQL_PORT_3306_TCP_PORT=3306" \
      -e "POSTFIX_MYSQL_PASSWORD=postfixpassword" \
      -h 'mail.example.org' \
      -v /var/vmail:/var/vmail \
      -P \
      combro2k/virtualmail
