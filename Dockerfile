FROM ubuntu-debootstrap:14.04
MAINTAINER Martijn van Maurik <docker@vmaurik.nl>

# Env variables
ENV HOME=/root \
    INSTALL_LOG=/var/log/build.log \
    AMAVISD_DB_HOME=/var/lib/amavis/db

# Software versions
ENV POSTFIX_VERSION=3.0.2 \
    DOVECOT_MAIN=2.2 \
    DOVECOT_VERSION=2.2.18 \
    DOVECOT_PIGEONHOLE=0.4.8 \
    OPENDKIM_VERSION=2.10.3 \
    PYPOLICYD_SPF_MAIN=1.3 \
    PYPOLICYD_SPF_VERSION=1.3.1 \
    CLAMAV_VERSION=0.98.7 \
    AMAVISD_NEW_VERSION=2.10.1 \
    GREYLIST_VERSION=4.5.14

RUN \
    echo '# Main' | tee -a ${INSTALL_LOG} > /dev/null && \
    export DEBIAN_FRONTEND=noninteractive && \
    touch ${INSTALL_LOG} && \
    groupadd -g 1000 vmail && useradd -g vmail -u 1000 vmail -d /var/vmail && \
    mkdir /var/vmail && chown vmail:vmail /var/vmail && \
    echo 'deb http://download.bitdefender.com/repos/deb/ bitdefender non-free' > /etc/apt/sources.list.d/bitdefender.list && \
    apt-key adv --keyserver keyserver.ubuntu.com --recv-keys ABF5BD827BD9BF62 2>&1 | tee -a ${INSTALL_LOG} > /dev/null && \
    apt-key adv --keyserver keyserver.ubuntu.com --recv-keys A373FB480EC4FE05 2>&1 | tee -a ${INSTALL_LOG} > /dev/null && \
    echo deb http://nginx.org/packages/mainline/ubuntu trusty nginx > /etc/apt/sources.list.d/nginx-stable-trusty.list && \
    apt-get update 2>&1 | tee -a ${INSTALL_LOG} > /dev/null && apt-get dist-upgrade -y 2>&1 | tee -a ${INSTALL_LOG} > /dev/null && \
    apt-get install -y libberkeleydb-perl libnet-dns-perl libnet-server-perl \
    libnet-rblclient-perl rsyslog libdb-dev libmysqlclient-dev libmysqlclient18 \
    cron xz-utils build-essential pyzor razor libencode-detect-perl libdbi-perl \
    libdbd-mysql-perl arj cabextract cpio nomarch pax unzip zip supervisor curl \
    libxml-libxml-perl libhtml-stripscripts-parser-perl bitdefender-scanner \
    libfile-copy-recursive-perl libdist-zilla-localetextdomain-perl libmime-charset-perl \
    libmime-encwords-perl libmime-lite-html-perl libcurl4-openssl-dev libcurlpp-dev \
    libmime-types-perl libnet-netmask-perl libtemplate-perl flex libbind-dev libgeoip-dev \
    libterm-progressbar-perl libintl-perl libauthcas-perl libcrypt-ciphersaber-perl \
    libcrypt-openssl-x509-perl libfcgi-perl libsoap-lite-perl libdata-password-perl libspf2-dev \
    libfile-nfslock-perl fcgiwrap nginx libcgi-fast-perl libmail-spf-perl libpthread-stubs0-dev \
    nodejs npm libmail-spf-xs-perl libmilter-dev libpcre3-dev libssl-dev libbsd-dev \
    ssl-cert python3 python3-setuptools python2.7-dev libnet-libidn-perl libunix-syslog-perl \
    libarchive-zip-perl libglib2.0-dev intltool ruby-dev byacc libicu-dev vim nano \
    less python-virtualenv pwgen && \
    easy_install3 pip 2>&1 | tee -a ${INSTALL_LOG} > /dev/null && \
echo '# ClamAV' | tee -a ${INSTALL_LOG} > /dev/null && \
    addgroup --quiet clamav && addgroup --quiet amavis && \
    adduser --system --ingroup clamav --home /var/lib/clamav --quiet --shell /bin/sh --disabled-password clamav && \
    adduser --system --ingroup amavis --home /var/lib/amavis --quiet --shell /bin/sh --disabled-password amavis && \
    adduser --quiet clamav amavis && adduser --quiet amavis clamav && \
    mkdir -p /var/run/clamav /var/lib/clamav /var/log/clamav && \
    chown -R clamav:clamav /var/run/clamav /var/lib/clamav /var/log/clamav && \
    mkdir -p /usr/src/build/clamav && cd /usr/src/build/clamav && \
    curl -sL http://sourceforge.net/projects/clamav/files/clamav/${CLAMAV_VERSION}/clamav-${CLAMAV_VERSION}.tar.gz/download | tar zx --strip-components=1 && \
    ./configure --prefix=/usr --sysconfdir=/etc --with-working-dir=/var/lib/amavis 2>&1 | tee -a ${INSTALL_LOG} > /dev/null && \
    make 2>&1 | tee -a ${INSTALL_LOG} > /dev/null && make install 2>&1 | tee -a ${INSTALL_LOG} > /dev/null && \
echo '# Bitdefender' | tee -a ${INSTALL_LOG} > /dev/null && \
    echo 'LicenseAccepted = True' >> /opt/BitDefender-scanner/etc/bdscan.conf && \
echo '# Spamassassin' | tee -a ${INSTALL_LOG} > /dev/null && \
    cpan -f install Mail::SPF::Query 2>&1 | tee -a ${INSTALL_LOG} > /dev/null && \
    cpan -f install Mail::SpamAssassin 2>&1 | tee -a ${INSTALL_LOG} > /dev/null && \
    sa-update 2>&1 | tee -a ${INSTALL_LOG} > /dev/null && \
echo '# Amavisd-new' | tee -a ${INSTALL_LOG} > /dev/null && \
    mkdir -p /var/run/amavis /var/lib/amavis/tmp /var/lib/amavis/db /var/lib/amavis/virusmails && \
    chown -R amavis:amavis /var/run/amavis /var/lib/amavis && \
    chmod -R 770 /var/lib/amavis && chown -R 770 /var/lib/amavis/tmp && \
    mkdir -p /usr/src/build/amavisd-new && cd /usr/src/build/amavisd-new && \
    curl -sL http://mirror.omroep.nl/amavisd-new/amavisd-new-${AMAVISD_NEW_VERSION}.tar.xz | tar Jx --strip-components=1 && \
    cp amavisd /usr/sbin/amavisd-new && chown root:root /usr/sbin/amavisd-new && chmod 755 /usr/sbin/amavisd-new && \
    cp amavisd-nanny /usr/sbin/amavisd-nanny && chown root:root /usr/sbin/amavisd-nanny && chmod 755 /usr/sbin/amavisd-nanny && \
    cp amavisd-release /usr/sbin/amavisd-release && chown root:root /usr/sbin/amavisd-release && chmod 755 /usr/sbin/amavisd-release && \
    sed -i 's#/var/amavis/amavisd.sock#/var/lib/amavis/amavisd.sock#g' /usr/sbin/amavisd-release && \
    cp amavisd-submit /usr/sbin/amavisd-submit && chown root:root /usr/sbin/amavisd-submit && chmod 755 /usr/sbin/amavisd-submit && \
echo '# Amavisd-milter' | tee -a ${INSTALL_LOG} > /dev/null && \
    mkdir -p /usr/src/build/amavisd-milter && cd /usr/src/build/amavisd-milter && \
    curl -sL http://sourceforge.net/projects/amavisd-milter/files/latest/download | tar zx --strip-components=1 && \
    ./configure --with-working-dir=/var/lib/amavis/tmp --prefix=/usr 2>&1 | tee -a ${INSTALL_LOG} > /dev/null && make 2>&1 | tee -a ${INSTALL_LOG} > /dev/null && \
    make install 2>&1 | tee -a ${INSTALL_LOG} > /dev/null && \
echo '# Postfix 3.0.2' | tee -a ${INSTALL_LOG} > /dev/null && \
    mkdir -p /usr/src/build/postfix && cd /usr/src/build/postfix && \
    useradd postfix && useradd postdrop && \
    curl -sL http://mirror.lhsolutions.nl/postfix-release/official/postfix-${POSTFIX_VERSION}.tar.gz | tar zx --strip-components=1 && \ make -f Makefile.init \
        "CCARGS=-DHAS_MYSQL -DHAS_PCRE -I/usr/include/mysql $(pcre-config --cflags) -DUSE_SASL_AUTH -DUSE_TLS" \
        "AUXLIBS_MYSQL=-L/usr/include/mysql -lmysqlclient -lz -lm $(pcre-config --libs) -lssl -lcrypto" 2>&1 | tee -a ${INSTALL_LOG} > /dev/null && \
    sh ./postfix-install -non-interactive install_root=/ 2>&1 | tee -a ${INSTALL_LOG} > /dev/null && \
echo '# Dovecot' | tee -a ${INSTALL_LOG} > /dev/null && \
    useradd dovenull && useradd dovecot && \
    mkdir -p /usr/src/build/dovecot && cd /usr/src/build/dovecot && \
    curl -sL http://dovecot.org/releases/2.2/dovecot-${DOVECOT_VERSION}.tar.gz | tar zx --strip-components=1 && \
    ./configure --prefix=/usr --sysconfdir=/etc --with-mysql --with-ssl --without-shared-libs 2>&1 | tee -a ${INSTALL_LOG} > /dev/null && \
    make 2>&1 | tee -a ${INSTALL_LOG} > /dev/null && make install 2>&1 | tee -a ${INSTALL_LOG} > /dev/null && \
echo '# Dovecot Sieve / ManageSieve' | tee -a ${INSTALL_LOG} > /dev/null && \
    mkdir -p /usr/src/build/pigeonhole && cd /usr/src/build/pigeonhole && \
    curl -sL http://pigeonhole.dovecot.org/releases/${DOVECOT_MAIN}/dovecot-${DOVECOT_MAIN}-pigeonhole-${DOVECOT_PIGEONHOLE}.tar.gz | tar zx --strip-components=1 && \
    ./configure --prefix=/usr --sysconfdir=/etc 2>&1 | tee -a ${INSTALL_LOG} > /dev/null && make 2>&1 | tee -a ${INSTALL_LOG} > /dev/null && \
    make install 2>&1 | tee -a ${INSTALL_LOG} > /dev/null && \
echo '# Greylist' | tee -a ${INSTALL_LOG} > /dev/null && \
    mkdir -p /usr/src/build/greylist && cd /usr/src/build/greylist && \
    curl -sL ftp://ftp.espci.fr/pub/milter-greylist/milter-greylist-${GREYLIST_VERSION}.tgz | tar zx --strip-components=1 -C /usr/src/build/greylist && \
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
        --with-delay=600 2>&1 | tee -a ${INSTALL_LOG} > /dev/null && \
    make 2>&1 | tee -a ${INSTALL_LOG} > /dev/null && make install 2>&1 | tee -a ${INSTALL_LOG} > /dev/null && \
    mkdir -p /var/spool/postfix/milter-greylist/ && chown -R postfix:postfix /var/spool/postfix/milter-greylist/ && \
    mkdir -p /var/spool/postfix/greylist && chown -R postfix:postfix /var/spool/postfix/greylist && \
echo '# OpenDKIM' | tee -a ${INSTALL_LOG} > /dev/null && \
    useradd opendkim && \
    mkdir -p /usr/src/build/opendkim && cd /usr/src/build/opendkim && \
    curl -sL http://sourceforge.net/projects/opendkim/files/opendkim-${OPENDKIM_VERSION}.tar.gz/download | tar zx --strip-components=1 && \
    ./configure --prefix=/usr 2>&1 | tee -a ${INSTALL_LOG} > /dev/null && make 2>&1 | tee -a ${INSTALL_LOG} > /dev/null && make install 2>&1 | tee -a ${INSTALL_LOG} > /dev/null && \
echo '# SPF Policyd' | tee -a ${INSTALL_LOG} > /dev/null && \
    mkdir -p /etc/postfix-policyd-spf-python && \
    pip install authres pyspf https://ipaddr-py.googlecode.com/files/ipaddr-2.1.5-py3k.tar.gz py3dns --pre 2>&1 | tee -a ${INSTALL_LOG} > /dev/null && \
    pip install https://launchpad.net/pypolicyd-spf/${PYPOLICYD_SPF_MAIN}/${PYPOLICYD_SPF_VERSION}/+download/pypolicyd-spf-${PYPOLICYD_SPF_VERSION}.tar.gz 2>&1 | tee -a ${INSTALL_LOG} > /dev/null && \
    mv /usr/local/bin/policyd-spf /usr/bin/policyd-spf && \
echo '# OpenDMARC' | tee -a ${INSTALL_LOG} > /dev/null && \
    mkdir -p /usr/src/build/opendmarc && cd /usr/src/build/opendmarc && \
    curl -sL http://sourceforge.net/projects/opendmarc/files/latest/download | tar zx --strip-components=1 && \
    ./configure \
        --prefix=/usr \
        --with-spf \
        --with-sql-backend 2>&1 | tee -a ${INSTALL_LOG} > /dev/null && \
    make 2>&1 | tee -a ${INSTALL_LOG} > /dev/null && make install 2>&1 | tee -a ${INSTALL_LOG} > /dev/null && \
    useradd opendmarc && \
    mkdir -p /var/run/opendmarc && \
    chown -R opendmarc:opendmarc /var/run/opendmarc && \
echo '# Mailman' | tee -a ${INSTALL_LOG} > /dev/null && \
    ln -s /usr/bin/nodejs /usr/bin/node && \
    npm install -g less 2>&1 | tee -a ${INSTALL_LOG} > /dev/null && \
    mkdir -p /etc/mailman.d /var/log/mailman && \
    virtualenv --system-site-packages -p python3.4 /opt/mailman 2>&1 | tee -a ${INSTALL_LOG} > /dev/null && \
    /opt/mailman/bin/pip install --pre -U mailman mailman-hyperkitty 2>&1 | tee -a ${INSTALL_LOG} > /dev/null && \
    /opt/mailman/bin/python -c \
        'import pip, subprocess; [subprocess.call("/opt/mailman/bin/pip install --pre -U " + d.project_name, shell=1) for d in pip.get_installed_distributions()]' 2>&1 | tee -a ${INSTALL_LOG} > /dev/null && \
    virtualenv --system-site-packages -p python2.7 /opt/postorius 2>&1 | tee -a ${INSTALL_LOG} > /dev/null && \
    /opt/postorius/bin/pip install -U --pre \
        django-gravatar flup postorius Whoosh mock beautifulsoup4 hyperkitty python-openid python-social-auth django-browserid 2>&1 | tee -a ${INSTALL_LOG} > /dev/null && \
    /opt/postorius/bin/pip -c \
        'import pip, subprocess; [subprocess.call("/opt/mailman/bin/pip install --pre -U " + d.project_name, shell=1) for d in pip.get_installed_distributions()]' 2>&1 | tee -a ${INSTALL_LOG} > /dev/null && \
    rm /etc/nginx/conf.d/default.conf && \
echo '# Milter Manager' | tee -a ${INSTALL_LOG} > /dev/null && \
    mkdir -p /usr/src/build/milter-manager && cd /usr/src/build/milter-manager && \
    curl -sL http://sourceforge.net/projects/milter-manager/files/milter%20manager/2.0.5/milter-manager-2.0.5.tar.gz/download | tar zx --strip-components=1 && \
    ./configure --prefix=/usr --sysconfdir=/etc 2>&1 | tee -a ${INSTALL_LOG} > /dev/null && make 2>&1 | tee -a ${INSTALL_LOG} > /dev/null && make install 2>&1 | tee -a ${INSTALL_LOG} > /dev/null

# Add resources
ADD resources/etc/ /etc/
ADD resources/opt/ /opt/
ADD resources/bin/ /usr/local/bin/

# Run the last bits and clean up
RUN chmod +x /usr/local/bin/* && \
    /usr/bin/freshclam --config-file=/etc/clamav/freshclam.conf 2>&1 | tee -a ${INSTALL_LOG} > /dev/null && \
    tar czf /root/build.tgz /usr/src/build 2>&1 | tee -a ${INSTALL_LOG} > /dev/null && \
    apt-get clean 2>&1 | tee -a ${INSTALL_LOG} > /dev/null && \
    rm -fr /var/lib/apt /usr/src/build

EXPOSE 25 80 110 143 465 587 993 995 4190
VOLUME ["/var/vmail", "/etc/dovecot", "/etc/postfix", "/etc/amavis" , "/etc/opendkim", "/etc/opendmarc", "/var/mailman"]

CMD ["/usr/local/bin/run"]

