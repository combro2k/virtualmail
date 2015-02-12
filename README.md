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

## Aditional Sympa Mailinglist
    docker run -d
          -e "MYSQL_PORT_3306_TCP_ADDR=172.0.0.24" \
          -e "MYSQL_PORT_3306_TCP_PORT=3306" \
          -e "POSTFIX_MYSQL_PASSWORD=postfixpassword" \
          -e "SYMPA_MYSQL_PASSWORD=mysympapassword" \
          -e "MAILINGLIST=list.example.org" \
          -h 'mail.example.org' \
          -v /var/vmail:/var/vmail \
          -P \
          combro2k/virtualmail
          
## Aditional volumes:
 - /etc/dovecot # configuration for dovecot
 - /etc/postfix # configuration for postfix
 - /etc/amavis # configuration for amavis
 - /etc/opendkim # configuration for opendkim
 - /home/sympa/list_data # data storage for sympa mailinglist
 - /home/sympa/arc # archives for sympa mailinglist
 - /etc/sympa.conf # configuration for sympa
 - /etc/opendmarc # OpenDMARC configuration
 
### Build env
You can extract all used source by going to /usr/src/, and untarring the source file:
- cd /usr/src && tar zxvf build.tgz --strip-components=2
