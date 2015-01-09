FROM ubuntu:14.04
MAINTAINER Martijn van Maurik <docker@vmaurik.nl>

ENV DEBIAN_FRONTEND noninteractive
RUN apt-get update
RUN apt-get dist-upgrade -yq

RUN bash -c 'debconf-set-selections <<< "postfix postfix/main_mailer_type string Internet site"'
RUN bash -c 'debconf-set-selections <<< "postfix postfix/mailname string mail.example.com"'

RUN apt-get install -yq libberkeleydb-perl libnet-dns-perl libnet-server-perl libnet-rblclient-perl
RUN apt-get install -yq postfix postfix-mysql postgrey rsyslog
RUN apt-get install -yq dovecot-core dovecot-imapd dovecot-managesieved dovecot-mysql dovecot-pop3d dovecot-sieve
RUN apt-get install -yq cron
RUN apt-get install -yq amavisd-new spamassassin clamav-daemon \
                       pyzor razor libencode-detect-perl libdbi-perl libdbd-mysql-perl \
                       arj cabextract cpio nomarch pax unzip zip
RUN apt-get install -yq supervisor
RUN apt-get install -yq opendkim opendkim-tools

RUN groupadd -g 1000 vmail && \
    useradd -g vmail -u 1000 vmail -d /var/vmail && \
    mkdir /var/vmail && \
    chown vmail:vmail /var/vmail

# ClamAV
RUN adduser clamav amavis
RUN adduser amavis clamav
RUN sed -i "s/Foreground false/Foreground true/g" /etc/clamav/clamd.conf && \
    sed -i "s/Foreground false/Foreground true/g" /etc/clamav/freshclam.conf && /usr/bin/freshclam --config-file=/etc/clamav/freshclam.conf

# Spamassassin
RUN sed -i "s/ENABLED\=0/ENABLED=1/g" /etc/default/spamassassin && \
    sed -i "s/CRON\=0/CRON=1/g" /etc/default/spamassassin && \
    echo "normalize_charset 1" >> /etc/mail/spamassassin/local.cf  && \
    echo "report_safe 0" >> /etc/mail/spamassassin/local.cf

# Amavisd-new
ADD amavisd/50-user /etc/amavis/conf.d/50-user
RUN chown root:root /etc/amavis/conf.d/50-user

# Postfix
ADD postfix/header_checks /etc/postfix/header_checks
ADD postfix/main.cf /etc/postfix/main.cf
ADD postfix/master.cf /etc/postfix/master.cf

ADD postfix/mysql-virtual-mailbox-maps.cf /etc/postfix/mysql-virtual-mailbox-maps.cf
ADD postfix/mysql-virtual-alias-maps.cf   /etc/postfix/mysql-virtual-alias-maps.cf 
ADD postfix/mysql-virtual-domains-maps.cf /etc/postfix/mysql-virtual-domains-maps.cf

# Dovecot
ADD dovecot/sieve /etc/dovecot/sieve
ADD dovecot/conf.d/10-auth.conf /etc/dovecot/conf.d/10-auth.conf
ADD dovecot/conf.d/10-master.conf /etc/dovecot/conf.d/10-master.conf
ADD dovecot/conf.d/10-ssl.conf /etc/dovecot/conf.d/10-ssl.conf
ADD dovecot/conf.d/15-lda.conf /etc/dovecot/conf.d/15-lda.conf
ADD dovecot/conf.d/15-mailboxes.conf /etc/dovecot/conf.d/15-mailboxes.conf
ADD dovecot/conf.d/20-managesieve.conf /etc/dovecot/conf.d/20-managesieve.conf
ADD dovecot/conf.d/90-sieve.conf /etc/dovecot/conf.d/90-sieve.conf
ADD dovecot/dovecot-sql.conf.ext /etc/dovecot/dovecot-sql.conf.ext
ADD supervisor/supervisord.conf /etc/supervisor/supervisord.conf

# Postgrey
RUN mkdir /var/spool/postfix/postgrey
RUN sed -i "s#^POSTGREY_OPTS\=\"--inet\=10023\"#POSTGREY_OPTS=\"--unix=/var/spool/postfix/postgrey/socket --delay=300\"#g" /etc/default/postgrey

# OpenDKIM
ADD opendkim/opendkim.conf /etc/opendkim.conf
ADD opendkim/KeyTable /etc/opendkim/KeyTable
ADD opendkim/SigningTable /etc/opendkim/SigningTable
ADD opendkim/TrustedHosts /etc/opendkim/TrustedHosts

ADD run /usr/local/bin/run
ADD postfix/bin/postfix.sh /usr/local/bin/postfix.sh
ADD clamav/clamav_init.sh /usr/local/bin/clamav_init.sh
ADD amavisd/amavisd_init.sh /usr/local/bin/amavisd_init.sh
RUN chmod +x /usr/local/bin/run
RUN chmod +x /usr/local/bin/postfix.sh
RUN chmod +x /usr/local/bin/clamav_init.sh
RUN chmod +x /usr/local/bin/amavisd_init.sh

EXPOSE 587 25 465 4190 995 993 110 143
VOLUME ["/var/vmail", "/etc/dovecot", "/etc/postfix", "/etc/amavis" , "/etc/opendkim"]

CMD ["/usr/local/bin/run"]
