Virtualmail container
==============

Virtualmail on Docker.

A summary of this container:

"The virtualmail container deploys and configures everything you need to provide email hosting. The container includes software for POP3 and IMAP, spam filtering, antivirus, and email groups (via a listserv)."

Thanks `@timbert` for pointing it out

### Requirements:
    - MySQL
    - Docker

### Build container
```bash
$ docker build -t combro2k/virtualmail https://github.com/combro2k/virtualmail.git
```

### How to start a container:
###### Use a linked database:
```bash
$ docker run -d \
  --link mysql:mysql \
  -e "POSTFIX_MYSQL_PASSWORD=postfixpassword" \
  -h 'mail.example.org' \
  -v /var/vmail:/var/vmail \
  -P \
  combro2k/virtualmail:latest
```

###### Add IPV6 support:
```bash
$ docker run -d \
  --link mysql:mysql \
  -e "POSTFIX_MYSQL_PASSWORD=postfixpassword" \
  -e "IP6DEV=eth1" \
  -e "IPV6ADDR=postfixpassword" \
  -e "IPV6GW=postfixpassword" \
  -h 'mail.example.org' \
  -v /var/vmail:/var/vmail \
  -P \
  combro2k/virtualmail:latest
```

###### Use a static database:
```bash
$ docker run -d \
  -e "MYSQL_PORT_3306_TCP_ADDR=172.0.0.24" \
  -e "MYSQL_PORT_3306_TCP_PORT=3306" \
  -e "POSTFIX_MYSQL_PASSWORD=postfixpassword" \
  -h 'mail.example.org' \
  -v /var/vmail:/var/vmail \
  -P \
  combro2k/virtualmail:latest
```

###### Aditional Mailman(3) Mailinglist:
```bash
$ docker run -d \
      -e "MYSQL_PORT_3306_TCP_ADDR=172.0.0.24" \
      -e "MYSQL_PORT_3306_TCP_PORT=3306" \
      -e "POSTFIX_MYSQL_PASSWORD=postfixpassword" \
      -e "MAILINGLIST=list.example.org" \
      -h 'mail.example.org' \
      -v /var/vmail:/var/vmail \
      -v /var/mailman:/var/mailman \
      -P \
      combro2k/virtualmail:latest
```

### Aditional volumes to be mount:
- */etc/dovecot* # configuration for Dovecot
- */etc/postfix* # configuration for Postfix
- */etc/amavis* # configuration for AMaViS
- */etc/opendkim* # configuration for OpenDKIM
- */etc/opendmarc* # configuration for OpenDMARC
- */etc/mailman* # configuration for Mailman
- */var/mailman* # mailman store

### Default config
You can extract all the default configs for example:

```bash
$ tar zxvf ~/root/config.tar.gz -C / /etc/mailman
```

### Build app again
You can build an specific app again by running /usr/local/bin/setup.sh [app]

```bash
$ /usr/local/bin/setup.sh postfix
```