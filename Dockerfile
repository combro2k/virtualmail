FROM ubuntu:14.04
MAINTAINER Martijn van Maurik <docker@vmaurik.nl>

ENV DEBIAN_FRONTEND noninteractive

# Install all required packages and do some cleanup!

RUN apt-get update && \
    apt-get dist-upgrade -yq && \
    bash -c 'debconf-set-selections <<< "postfix postfix/main_mailer_type string Internet site"' && \
    bash -c 'debconf-set-selections <<< "postfix postfix/mailname string mail.example.com"' && \
    apt-get install -yq libberkeleydb-perl libnet-dns-perl libnet-server-perl libnet-rblclient-perl \
        postfix postfix-mysql postgrey rsyslog dovecot-core dovecot-imapd dovecot-managesieved \
        dovecot-mysql dovecot-pop3d dovecot-sieve cron amavisd-new spamassassin clamav-daemon \
        pyzor razor libencode-detect-perl libdbi-perl libdbd-mysql-perl arj cabextract cpio nomarch \
        pax unzip zip supervisor opendkim opendkim-tools

# Add all the files to the container
ADD amavisd/* /etc/amavis/conf.d/
ADD postfix/* /etc/postfix/
ADD dovecot/* /etc/dovecot/
ADD supervisor/* /etc/supervisor/
ADD opendkim/opendkim.conf /etc/opendkim.conf
ADD opendkim/opendkim/* /etc/opendkim/
ADD bin/* /usr/local/bin/

RUN groupadd -g 1000 vmail && \
    useradd -g vmail -u 1000 vmail -d /var/vmail && \
    mkdir /var/vmail && \
    chown vmail:vmail /var/vmail && \
    adduser clamav amavis && \
    adduser amavis clamav && \
    sed -i "s/Foreground false/Foreground true/g" /etc/clamav/clamd.conf && \
    sed -i "s/Foreground false/Foreground true/g" /etc/clamav/freshclam.conf && /usr/bin/freshclam --config-file=/etc/clamav/freshclam.conf && \
    sed -i "s/ENABLED\=0/ENABLED=1/g" /etc/default/spamassassin && \
    sed -i "s/CRON\=0/CRON=1/g" /etc/default/spamassassin && \
    echo "normalize_charset 1" >> /etc/mail/spamassassin/local.cf  && \
    echo "report_safe 0" >> /etc/mail/spamassassin/local.cf && \
    chown root:root /etc/amavis/conf.d/50-user && \
    mkdir /var/spool/postfix/postgrey && \
    sed -i "s#^POSTGREY_OPTS\=\"--inet\=10023\"#POSTGREY_OPTS=\"--unix=/var/spool/postfix/postgrey/socket --delay=300\"#g" /etc/default/postgrey && \
    chmod +x /usr/local/bin/*

EXPOSE 587 25 465 4190 995 993 110 143

VOLUME ["/var/vmail", "/etc/dovecot", "/etc/postfix", "/etc/amavis" , "/etc/opendkim"]

CMD ["/usr/local/bin/run"]
