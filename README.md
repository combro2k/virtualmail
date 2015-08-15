virtualmail
==============

Virtualmail on Docker.

A summary of this container: “The virtualmail container deploys and configures everything you need to provide email hosting. The container includes software for POP3 and IMAP, spam filtering, antivirus, and email groups (via a listserv).” - Thanks @timbert for pointing it out

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

## Aditional Mailman(3) Mailinglist
    docker run -d
          -e "MYSQL_PORT_3306_TCP_ADDR=172.0.0.24" \
          -e "MYSQL_PORT_3306_TCP_PORT=3306" \
          -e "POSTFIX_MYSQL_PASSWORD=postfixpassword" \
          -e "MAILINGLIST=list.example.org" \
          -h 'mail.example.org' \
          -v /var/vmail:/var/vmail \
          -v /var/mailman:/var/mailman \
          -P \
          combro2k/virtualmail
          
## Aditional volumes:
 - /etc/dovecot # configuration for dovecot
 - /etc/postfix # configuration for postfix
 - /etc/amavis # configuration for amavis
 - /etc/opendkim # configuration for opendkim
 - /etc/opendmarc # OpenDMARC configuration
 - /var/mailman # mailman store
 
### Build env
You can extract all used source by going to /usr/src/, and untarring the source file:
- cd / && tar zxvf ~/root/build.tgz
