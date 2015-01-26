FROM ubuntu:14.04
MAINTAINER Martijn van Maurik <docker@vmaurik.nl>

ENV DEBIAN_FRONTEND noninteractive

RUN apt-key adv --keyserver keyserver.ubuntu.com --recv-keys ABF5BD827BD9BF62 && \
    echo deb http://nginx.org/packages/mainline/ubuntu trusty nginx > /etc/apt/sources.list.d/nginx-stable-trusty.list

RUN apt-get update && apt-get dist-upgrade -yq

RUN bash -c 'debconf-set-selections <<< "postfix postfix/main_mailer_type string Internet site"' && \
    bash -c 'debconf-set-selections <<< "postfix postfix/mailname string mail.example.com"'

RUN apt-get install -yq \
    libberkeleydb-perl libnet-dns-perl libnet-server-perl libnet-rblclient-perl \
    postfix postfix-mysql postgrey rsyslog \
    dovecot-core dovecot-imapd dovecot-managesieved dovecot-mysql dovecot-pop3d dovecot-sieve \
    cron amavisd-new spamassassin clamav-daemon \
    pyzor razor libencode-detect-perl libdbi-perl libdbd-mysql-perl \
    arj cabextract cpio nomarch pax unzip zip \
    supervisor opendkim opendkim-tools curl \
    libxml-libxml-perl libhtml-stripscripts-parser-perl \
    libfile-copy-recursive-perl libdist-zilla-localetextdomain-perl \
    libmime-charset-perl libmime-encwords-perl libmime-lite-html-perl \
    libmime-types-perl libnet-netmask-perl libtemplate-perl \
    libterm-progressbar-perl libintl-perl libauthcas-perl libcrypt-ciphersaber-perl \
    libcrypt-openssl-x509-perl libfcgi-perl libsoap-lite-perl libdata-password-perl \
    libfile-nfslock-perl fcgiwrap nginx libcgi-fast-perl

RUN groupadd -g 1000 vmail && \
    useradd -g vmail -u 1000 vmail -d /var/vmail && \
    mkdir /var/vmail && \
    chown vmail:vmail /var/vmail

# ClamAV
RUN adduser clamav amavis && \
    adduser amavis clamav && \
    sed -i "s/Foreground false/Foreground true/g" /etc/clamav/clamd.conf && \
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
RUN chown -R vmail:vmail /etc/dovecot/sieve

# Postgrey
RUN mkdir /var/spool/postfix/postgrey
RUN sed -i "s#^POSTGREY_OPTS\=\"--inet\=10023\"#POSTGREY_OPTS=\"--unix=/var/spool/postfix/postgrey/socket --delay=300\"#g" /etc/default/postgrey

# OpenDKIM
ADD opendkim/opendkim.conf /etc/opendkim.conf
ADD opendkim/KeyTable /etc/opendkim/KeyTable
ADD opendkim/SigningTable /etc/opendkim/SigningTable
ADD opendkim/TrustedHosts /etc/opendkim/TrustedHosts

# Sympa
RUN mkdir -p /usr/src/sympa && \
    cd /usr/src/sympa && \
    curl http://www.sympa.org/distribution/sympa-6.1.24.tar.gz | tar zxv --strip-components=1 && \
    ./configure && make && make install && \
    cpan -f install MHonArc::UTF8 Template::Stash::XS Text::LineFold && \
    useradd sympa && chown -R sympa:sympa /home/sympa && \
    locale-gen en_US en_US.UTF-8 nl_NL nl_NL.UTF-8 && \
    sed -i 's#www-data#sympa#g' /etc/init.d/fcgiwrap && \
    sed -i 's#user  nginx;#user  sympa;#g' /etc/nginx/nginx.conf && \
    rm /etc/nginx/conf.d/*.conf

ADD sympa/sympa-nginx.conf /etc/nginx/conf.d/sympa-nginx.conf

ADD run /usr/local/bin/run
ADD postfix/bin/postfix.sh /usr/local/bin/postfix.sh
ADD clamav/clamav_init.sh /usr/local/bin/clamav_init.sh
ADD amavisd/amavisd_init.sh /usr/local/bin/amavisd_init.sh
ADD opendkim/opendkim.sh /usr/local/bin/opendkim.sh
ADD sympa/sympa.sh /usr/local/bin/sympa.sh

RUN chmod +x /usr/local/bin/run /usr/local/bin/postfix.sh /usr/local/bin/clamav_init.sh /usr/local/bin/amavisd_init.sh /usr/local/bin/opendkim.sh /usr/local/bin/sympa.sh

EXPOSE 587 25 465 4190 995 993 110 143
VOLUME ["/var/vmail", "/etc/dovecot", "/etc/postfix", "/etc/amavis" , "/etc/opendkim", "/etc/sympa.conf", "/home/sympa/list_data", "/home/sympa/arc", "/etc/wwsympa.conf"]

CMD ["/usr/local/bin/run"]
