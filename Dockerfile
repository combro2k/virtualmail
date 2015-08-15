FROM ubuntu-debootstrap:14.04
MAINTAINER Martijn van Maurik <docker@vmaurik.nl>

# Env variables
ENV DEBIAN_FRONTEND noninteractive
ENV INSTALL_LOG /var/log/build.log
ENV AMAVISD_DB_HOME /var/lib/amavis/db

# Software versions
ENV POSTFIX_VERSION 3.0.2
ENV DOVECOT_MAIN 2.2
ENV DOVECOT_VERSION 2.2.18
ENV DOVECOT_PIGEONHOLE 0.4.8
ENV OPENDKIM_VERSION 2.10.3
ENV PYPOLICYD_SPF_MAIN 1.3
ENV PYPOLICYD_SPF_VERSION 1.3.1
ENV CLAMAV_VERSION 0.98.7
ENV AMAVISD_NEW_VERSION 2.10.1
ENV GREYLIST_VERSION 4.5.14

RUN groupadd -g 1000 vmail && useradd -g vmail -u 1000 vmail -d /var/vmail && \
    mkdir /var/vmail && chown vmail:vmail /var/vmail && \
    echo 'deb http://download.bitdefender.com/repos/deb/ bitdefender non-free' > /etc/apt/sources.list.d/bitdefender.list && \
    apt-key adv --keyserver keyserver.ubuntu.com --recv-keys ABF5BD827BD9BF62 2>&1 | tee -a ${INSTALL_LOG} && \
    apt-key adv --keyserver keyserver.ubuntu.com --recv-keys A373FB480EC4FE05 2>&1 | tee -a ${INSTALL_LOG} && \
    echo deb http://nginx.org/packages/mainline/ubuntu trusty nginx > /etc/apt/sources.list.d/nginx-stable-trusty.list && \
    apt-get update 2>&1 | tee -a ${INSTALL_LOG} && apt-get dist-upgrade -y 2>&1 | tee -a ${INSTALL_LOG} && apt-get install -y libberkeleydb-perl libnet-dns-perl libnet-server-perl \
    libnet-rblclient-perl rsyslog libdb-dev libmysqlclient-dev libmysqlclient18 cron xz-utils build-essential \
    pyzor razor libencode-detect-perl libdbi-perl libdbd-mysql-perl arj cabextract cpio nomarch pax unzip zip supervisor curl \
    libxml-libxml-perl libhtml-stripscripts-parser-perl bitdefender-scanner libfile-copy-recursive-perl libdist-zilla-localetextdomain-perl \
    libmime-charset-perl libmime-encwords-perl libmime-lite-html-perl libcurl4-openssl-dev libcurlpp-dev \
    libmime-types-perl libnet-netmask-perl libtemplate-perl flex libbind-dev libgeoip-dev libterm-progressbar-perl libintl-perl \
    libauthcas-perl libcrypt-ciphersaber-perl libcrypt-openssl-x509-perl libfcgi-perl libsoap-lite-perl libdata-password-perl libspf2-dev \
    libfile-nfslock-perl fcgiwrap nginx libcgi-fast-perl libmail-spf-perl libpthread-stubs0-dev nodejs npm \
    libmail-spf-xs-perl libmilter-dev libpcre3-dev libssl-dev libbsd-dev ssl-cert python3 python3-setuptools python2.7-dev \
    libnet-libidn-perl libunix-syslog-perl libarchive-zip-perl libglib2.0-dev intltool ruby-dev byacc libicu-dev vim nano less python-virtualenv pwgen && \
    easy_install3 pip 2>&1 | tee -a ${INSTALL_LOG}

# ClamAV
ADD resources/cron.d /etc/cron.d
RUN addgroup --quiet clamav && addgroup --quiet amavis && \
    adduser --system --ingroup clamav --home /var/lib/clamav --quiet --shell /bin/sh --disabled-password clamav && \
    adduser --system --ingroup amavis --home /var/lib/amavis --quiet --shell /bin/sh --disabled-password amavis && \
    adduser --quiet clamav amavis && adduser --quiet amavis clamav && \
    mkdir -p /var/run/clamav /var/lib/clamav /var/log/clamav && \
    chown -R clamav:clamav /var/run/clamav /var/lib/clamav /var/log/clamav && \
    mkdir -p /usr/src/build/clamav && cd /usr/src/build/clamav && \
    curl -L http://sourceforge.net/projects/clamav/files/clamav/${CLAMAV_VERSION}/clamav-${CLAMAV_VERSION}.tar.gz/download | tar zx --strip-components=1 && \
    ./configure --prefix=/usr --sysconfdir=/etc --with-working-dir=/var/lib/amavis 2>&1 | tee -a ${INSTALL_LOG} && make 2>&1 | tee -a ${INSTALL_LOG} && make install 2>&1 | tee -a ${INSTALL_LOG}

# Bitdefender
RUN echo 'LicenseAccepted = True' >> /opt/BitDefender-scanner/etc/bdscan.conf

ADD resources/clamav /etc/clamav
RUN /usr/bin/freshclam --config-file=/etc/clamav/freshclam.conf 2>&1 | tee -a ${INSTALL_LOG}

# Spamassassin
ADD resources/spamassassin /etc/spamassassin
RUN cpan -f install Mail::SPF::Query 2>&1 | tee -a ${INSTALL_LOG} && cpan -f install Mail::SpamAssassin 2>&1 | tee -a ${INSTALL_LOG} && \
    sa-update 2>&1 | tee -a ${INSTALL_LOG}

# Amavisd-new
RUN mkdir -p /var/run/amavis /var/lib/amavis/tmp /var/lib/amavis/db /var/lib/amavis/virusmails && \
    chown -R amavis:amavis /var/run/amavis /var/lib/amavis && \
    chmod -R 770 /var/lib/amavis && chown -R 770 /var/lib/amavis/tmp && \
    mkdir -p /usr/src/build/amavisd-new && cd /usr/src/build/amavisd-new && \
    curl http://mirror.omroep.nl/amavisd-new/amavisd-new-${AMAVISD_NEW_VERSION}.tar.xz | tar Jxv --strip-components=1 2>&1 | tee -a ${INSTALL_LOG} && \
    cp amavisd /usr/sbin/amavisd-new && chown root:root /usr/sbin/amavisd-new && chmod 755 /usr/sbin/amavisd-new && \
    cp amavisd-nanny /usr/sbin/amavisd-nanny && chown root:root /usr/sbin/amavisd-nanny && chmod 755 /usr/sbin/amavisd-nanny && \
    cp amavisd-release /usr/sbin/amavisd-release && chown root:root /usr/sbin/amavisd-release && chmod 755 /usr/sbin/amavisd-release && \
    sed -i 's#/var/amavis/amavisd.sock#/var/lib/amavis/amavisd.sock#g' /usr/sbin/amavisd-release && \
    cp amavisd-submit /usr/sbin/amavisd-submit && chown root:root /usr/sbin/amavisd-submit && chmod 755 /usr/sbin/amavisd-submit

ADD resources/amavis /etc/amavis
RUN chown root:root /etc/amavis -R

# Amavisd-milter
RUN mkdir -p /usr/src/build/amavisd-milter && cd /usr/src/build/amavisd-milter && \
    curl -L http://sourceforge.net/projects/amavisd-milter/files/latest/download | tar zx --strip-components=1 && \
    ./configure --with-working-dir=/var/lib/amavis/tmp --prefix=/usr 2>&1 | tee -a ${INSTALL_LOG} && make 2>&1 | tee -a ${INSTALL_LOG} && make install 2>&1 | tee -a ${INSTALL_LOG}

# Postfix 3.0.2
RUN mkdir -p /usr/src/build/postfix && cd /usr/src/build/postfix && \
    useradd postfix && useradd postdrop && \
    curl -L http://mirror.lhsolutions.nl/postfix-release/official/postfix-${POSTFIX_VERSION}.tar.gz | tar zx --strip-components=1 && \
    make -f Makefile.init "CCARGS=-DHAS_MYSQL -DHAS_PCRE -I/usr/include/mysql $(pcre-config --cflags) -DUSE_SASL_AUTH -DUSE_TLS" "AUXLIBS_MYSQL=-L/usr/include/mysql -lmysqlclient -lz -lm $(pcre-config --libs) -lssl -lcrypto" 2>&1 | tee -a ${INSTALL_LOG} && \
    sh ./postfix-install -non-interactive install_root=/ 2>&1 | tee -a ${INSTALL_LOG}

ADD resources/postfix /etc/postfix
ADD resources/mailname /etc/mailname
RUN chmod 640 /etc/postfix -R

# Dovecot
RUN useradd dovenull && useradd dovecot && \
    mkdir -p /usr/src/build/dovecot && cd /usr/src/build/dovecot && \
    curl -L http://dovecot.org/releases/2.2/dovecot-${DOVECOT_VERSION}.tar.gz | tar zx --strip-components=1 && \
    ./configure --prefix=/usr --sysconfdir=/etc --with-mysql --with-ssl --without-shared-libs 2>&1 | tee -a ${INSTALL_LOG} && make 2>&1 | tee -a ${INSTALL_LOG} && make install 2>&1 | tee -a ${INSTALL_LOG}

# Dovecot Sieve / ManageSieve
RUN mkdir -p /usr/src/build/pigeonhole && cd /usr/src/build/pigeonhole && \
    curl -L http://pigeonhole.dovecot.org/releases/${DOVECOT_MAIN}/dovecot-${DOVECOT_MAIN}-pigeonhole-${DOVECOT_PIGEONHOLE}.tar.gz | tar zx --strip-components=1 && \
    ./configure --prefix=/usr --sysconfdir=/etc 2>&1 | tee -a ${INSTALL_LOG} && make 2>&1 | tee -a ${INSTALL_LOG} && make install 2>&1 | tee -a ${INSTALL_LOG}

ADD resources/dovecot /etc/dovecot
RUN chown -R vmail:vmail /etc/dovecot/sieve

# Supervisor
ADD resources/supervisor/supervisord.conf /etc/supervisor/supervisord.conf

# Greylist
RUN mkdir -p /usr/src/build/greylist && cd /usr/src/build/greylist && \
    curl ftp://ftp.espci.fr/pub/milter-greylist/milter-greylist-${GREYLIST_VERSION}.tgz | tar zx --strip-components=1 && \
    LDFLAGS="-L/usr/lib/libmilter" CFLAGS="-I/usr/include/libmilter" \
    ./configure \
        --enable-dnsrbl \
        --prefix=/usr \
        --enable-postfix \
        --with-user=postfix \
        --with-conffile=/etc/greylist/greylist.conf \
        --with-dumpfile=/etc/greylist/greylist.db \
        --with-libcurl \
        --with-libspf2 \
        --enable-spamassassin \
        --enable-p0f \
        --with-delay=600 2>&1 | tee -a ${INSTALL_LOG} && \
    make 2>&1 | tee -a ${INSTALL_LOG} && make install 2>&1 | tee -a ${INSTALL_LOG} && \
    mkdir -p /var/spool/postfix/milter-greylist/ && chown -R postfix:postfix /var/spool/postfix/milter-greylist/ && \
    mkdir -p /var/spool/postfix/greylist && chown -R postfix:postfix /var/spool/postfix/greylist

ADD resources/greylist /etc/greylist

# OpenDKIM
RUN useradd opendkim && \
    mkdir -p /usr/src/build/opendkim && cd /usr/src/build/opendkim && \
    curl -L http://sourceforge.net/projects/opendkim/files/opendkim-${OPENDKIM_VERSION}.tar.gz/download | tar zx --strip-components=1 && \
    ./configure --prefix=/usr 2>&1 | tee -a ${INSTALL_LOG} && make 2>&1 | tee -a ${INSTALL_LOG} && make install 2>&1 | tee -a ${INSTALL_LOG}

ADD resources/opendkim /etc/opendkim

# SPF Policyd
RUN mkdir -p /etc/postfix-policyd-spf-python && \
    pip install authres pyspf https://ipaddr-py.googlecode.com/files/ipaddr-2.1.5-py3k.tar.gz py3dns --pre 2>&1 | tee -a ${INSTALL_LOG} && \
    pip install https://launchpad.net/pypolicyd-spf/${PYPOLICYD_SPF_MAIN}/${PYPOLICYD_SPF_VERSION}/+download/pypolicyd-spf-${PYPOLICYD_SPF_VERSION}.tar.gz 2>&1 | tee -a ${INSTALL_LOG} && \
    mv /usr/local/bin/policyd-spf /usr/bin/policyd-spf

ADD resources/policy-spf/policyd-spf.conf /etc/postfix-policyd-spf-python/policyd-spf.conf

# OpenDMARC
RUN mkdir -p /usr/src/build/opendmarc && cd /usr/src/build/opendmarc && \
    curl -L http://sourceforge.net/projects/opendmarc/files/latest/download | tar zx --strip-components=1 && \
    ./configure --prefix=/usr --with-spf --with-sql-backend 2>&1 | tee -a ${INSTALL_LOG} && make 2>&1 | tee -a ${INSTALL_LOG} && make install 2>&1 | tee -a ${INSTALL_LOG} && \
    useradd opendmarc && \
    mkdir -p /var/run/opendmarc && \
    chown -R opendmarc:opendmarc /var/run/opendmarc

ADD resources/opendmarc /etc/opendmarc

# Mailman
RUN ln -s /usr/bin/nodejs /usr/bin/node && \
    npm install -g less 2>&1 | tee -a ${INSTALL_LOG} && \
    mkdir -p /etc/mailman.d /var/log/mailman && \
    virtualenv --system-site-packages -p python3.4 /opt/mailman 2>&1 | tee -a ${INSTALL_LOG} && \
    /opt/mailman/bin/pip install --pre -U mailman mailman-hyperkitty 2>&1 | tee -a ${INSTALL_LOG} && \
    /opt/mailman/bin/python -c 'import pip, subprocess; [subprocess.call("/opt/mailman/bin/pip install --pre -U " + d.project_name, shell=1) for d in pip.get_installed_distributions()]' 2>&1 | tee -a ${INSTALL_LOG} && \
    virtualenv --system-site-packages -p python2.7 /opt/postorius 2>&1 | tee -a ${INSTALL_LOG} && \
    /opt/postorius/bin/pip install -U --pre django-gravatar flup postorius Whoosh mock beautifulsoup4 hyperkitty python-openid python-social-auth django-browserid 2>&1 | tee -a ${INSTALL_LOG} && \
    rm /etc/nginx/conf.d/default.conf

ADD resources/postorius_standalone /opt/postorius_standalone
ADD resources/nginx/nginx.conf /etc/nginx/nginx.conf
ADD resources/nginx/nginx-postorius.conf /etc/nginx/conf.d/nginx-postorius.conf
ADD resources/mailman3/mailman.cfg /etc/mailman.cfg
ADD resources/mailman3/mailman.d/* /etc/mailman.d/

# Milter Manager
RUN mkdir -p /usr/src/build/milter-manager && cd /usr/src/build/milter-manager && \
    curl -L http://sourceforge.net/projects/milter-manager/files/milter%20manager/2.0.5/milter-manager-2.0.5.tar.gz/download | tar zv --strip-components=1 && \
    ./configure --prefix=/usr --sysconfdir=/etc 2>&1 | tee -a ${INSTALL_LOG} && make 2>&1 | tee -a ${INSTALL_LOG} && make install 2>&1 | tee -a ${INSTALL_LOG} && \
    rm -fr /etc/milter-manager

ADD resources/milter-manager /etc/milter-manager

ADD bin/* /usr/local/bin/

RUN chmod +x /usr/local/bin/*

# Cleanup build env
RUN tar czf /root/build.tgz /usr/src/build --remove-files && \
    apt-get clean 2>&1 | tee -a ${INSTALL_LOG} && \
    rm -fr /var/lib/apt

EXPOSE 587 25 465 4190 995 993 110 143
VOLUME ["/var/vmail", "/etc/dovecot", "/etc/postfix", "/etc/amavis" , "/etc/opendkim", "/etc/opendmarc", "/var/mailman"]

WORKDIR /

CMD ["/usr/local/bin/run"]
