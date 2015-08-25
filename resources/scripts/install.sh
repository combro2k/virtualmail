#!/bin/bash
set -e

e () {
    errcode=$? # save the exit code as the first thing done in the trap function
    echo "error $errorcode"
    echo "the command executing at the time of the error was"
    echo "$BASH_COMMAND"
    echo "on line ${BASH_LINENO[0]}"
    tail -n 25 ${INSTALL_LOG}
    exit 1  # or use some other value or do return instead
}

trap e ERR

packages=(
	'arj'
	'bitdefender-scanner'
	'build-essential'
	'byacc'
	'cabextract'
	'cpio'
	'cron'
	'curl'
	'fcgiwrap'
	'flex'
	'intltool'
	'less'
	'libarchive-zip-perl'
	'libauthcas-perl'
	'libberkeleydb-perl'
	'libbind-dev'
	'libbsd-dev'
	'libcgi-fast-perl'
	'libcrypt-ciphersaber-perl'
	'libcrypt-openssl-x509-perl'
	'libcurl4-openssl-dev'
	'libcurlpp-dev'
	'libdata-password-perl'
	'libdb-dev'
	'libdbd-mysql-perl'
	'libdbi-perl'
	'libdist-zilla-localetextdomain-perl'
	'libencode-detect-perl'
	'libfcgi-perl'
	'libfile-copy-recursive-perl'
	'libfile-nfslock-perl'
	'libgeoip-dev'
	'libglib2.0-dev'
	'libhtml-stripscripts-parser-perl'
	'libicu-dev'
	'libintl-perl'
	'libmail-spf-perl'
	'libmail-spf-xs-perl'
	'libmilter-dev'
	'libmime-charset-perl'
	'libmime-encwords-perl'
	'libmime-lite-html-perl'
	'libmime-types-perl'
	'libmysqlclient18'
	'libmysqlclient-dev'
	'libnet-dns-perl'
	'libnet-libidn-perl'
	'libnet-netmask-perl'
	'libnet-rblclient-perl'
	'libnet-server-perl'
	'libpcre3-dev'
	'libpthread-stubs0-dev'
	'libsoap-lite-perl'
	'libspf2-dev'
	'libssl-dev'
	'libtemplate-perl'
	'libterm-progressbar-perl'
	'libunix-syslog-perl'
	'libxml-libxml-perl'
	'nano'
	'nginx'
	'nodejs'
	'nomarch'
	'npm'
	'pax'
	'pwgen'
	'python2.7-dev'
	'python3'
	'python3-setuptools'
	'python-virtualenv'
	'pyzor'
	'razor'
	'rsyslog'
	'ruby-dev'
	'ssl-cert'
	'supervisor'
	'unzip'
	'vim'
	'xz-utils'
	'zip'
)

install() {
    trap e ERR
    echo '# Setup virtualmail user'
    adduser --system --group --uid 1000 --home /var/vmail --disabled-password vmail

    echo '# Creating source directories'
    source=(
        '/usr/src/build/amavisd-milter'
        '/usr/src/build/amavisd-new'
        '/usr/src/build/clamav'
        '/usr/src/build/dovecot'
        '/usr/src/build/greylist'
        '/usr/src/build/milter-manager'
        '/usr/src/build/opendkim'
        '/usr/src/build/opendmarc'
        '/usr/src/build/pigeonhole'
        '/usr/src/build/postfix'
    )
    mkdir -vp ${source[@]}

    echo '# APT keys'
    DEBIAN_FRONTEND=noninteractive apt-key adv --keyserver keyserver.ubuntu.com --recv-keys ABF5BD827BD9BF62
    DEBIAN_FRONTEND=noninteractive apt-key adv --keyserver keyserver.ubuntu.com --recv-keys A373FB480EC4FE05

    echo 'deb http://download.bitdefender.com/repos/deb/ bitdefender non-free' > /etc/apt/sources.list.d/bitdefender.list
    echo 'deb http://nginx.org/packages/mainline/ubuntu trusty nginx' > /etc/apt/sources.list.d/nginx-stable-trusty.list

    echo '# APT update, upgrade and install packages'
    DEBIAN_FRONTEND=noninteractive apt-get update
    DEBIAN_FRONTEND=noninteractive apt-get install -yqq ${packages[@]}

    echo '# System global pip'
    easy_install3 pip

    echo '# ClamAV'
    cd /usr/src/build/clamav
    addgroup --quiet clamav && addgroup --quiet amavis
    adduser --system --ingroup clamav --home /var/lib/clamav --quiet --shell /bin/sh --disabled-password clamav
    adduser --system --ingroup amavis --home /var/lib/amavis --quiet --shell /bin/sh --disabled-password amavis
    adduser --quiet clamav amavis
    adduser --quiet amavis clamav
    curl -sL http://netcologne.dl.sourceforge.net/project/clamav/clamav/${CLAMAV_VERSION}/clamav-${CLAMAV_VERSION}.tar.gz | tar zx --strip-components=1
    ./configure --prefix=/usr --sysconfdir=/etc --with-working-dir=/var/lib/amavis
    make && make install
    mkdir -p /var/run/clamav /var/lib/clamav /var/log/clamav
    chown -R clamav:clamav /var/run/clamav /var/lib/clamav /var/log/clamav

    echo '# Bitdefender'
    echo 'LicenseAccepted = True' >> /opt/BitDefender-scanner/etc/bdscan.conf

    echo '# Spamassassin'
    cpan -f install Mail::SPF::Query
    cpan -f install Mail::SpamAssassin
    sa-update

    echo '# Amavisd-new'
    cd /usr/src/build/amavisd-new
    mkdir -p /var/run/amavis /var/lib/amavis/tmp /var/lib/amavis/db /var/lib/amavis/virusmails
    chown -R amavis:amavis /var/run/amavis /var/lib/amavis
    chmod -R 770 /var/lib/amavis
    curl -sL http://mirror.omroep.nl/amavisd-new/amavisd-new-${AMAVISD_NEW_VERSION}.tar.xz | tar Jx --strip-components=1
    cp amavisd /usr/sbin/amavisd-new
    cp amavisd-nanny /usr/sbin/amavisd-nanny
    cp amavisd-release /usr/sbin/amavisd-release
    cp amavisd-submit /usr/sbin/amavisd-submit
    chown root:root /usr/sbin/amavisd-nanny /usr/sbin/amavisd-release /usr/sbin/amavisd-new /usr/sbin/amavisd-submit
    chmod 755 /usr/sbin/amavisd-nanny /usr/sbin/amavisd-release /usr/sbin/amavisd-new /usr/sbin/amavisd-submit
    sed -i 's#/var/amavis/amavisd.sock#/var/lib/amavis/amavisd.sock#g' /usr/sbin/amavisd-release

    echo '# Amavisd-milter'
    cd /usr/src/build/amavisd-milter
    curl -sL http://netcologne.dl.sourceforge.net/project/amavisd-milter/amavisd-milter/amavisd-milter-${AMAVISD_MILTER}/amavisd-milter-${AMAVISD_MILTER}.tar.gz | tar zx --strip-components=1
    ./configure --with-working-dir=/var/lib/amavis/tmp --prefix=/usr
    make && make install

    echo '# Postfix 3.0.2'
    cd /usr/src/build/postfix
    useradd postfix
    useradd postdrop
    curl -sL http://de.postfix.org/ftpmirror/official/postfix-${POSTFIX_VERSION}.tar.gz | tar zx --strip-components=1
    make -f Makefile.init "CCARGS=-DHAS_MYSQL -DHAS_PCRE -I/usr/include/mysql $(pcre-config --cflags) -DUSE_SASL_AUTH -DUSE_TLS" "AUXLIBS_MYSQL=-L/usr/include/mysql -lmysqlclient -lz -lm $(pcre-config --libs) -lssl -lcrypto"
    sh ./postfix-install -non-interactive install_root=/

    echo '# Dovecot'
    cd /usr/src/build/dovecot
    useradd dovenull
    useradd dovecot
    IFS='.' read -ra PARSE <<< "${DOVECOT_VERSION}"
    DOVECOT_MAIN=$(echo "${PARSE[0]}.${PARSE[1]}")
    curl -sL http://dovecot.org/releases/${DOVECOT_MAIN}/dovecot-${DOVECOT_VERSION}.tar.gz | tar zx --strip-components=1
    ./configure --prefix=/usr --sysconfdir=/etc --with-mysql --with-ssl --without-shared-libs
    make && make install

    echo '# Dovecot Sieve / ManageSieve'
    cd /usr/src/build/pigeonhole
    curl -sL http://pigeonhole.dovecot.org/releases/${DOVECOT_MAIN}/dovecot-${DOVECOT_MAIN}-pigeonhole-${DOVECOT_PIGEONHOLE}.tar.gz | tar zx --strip-components=1
    ./configure --prefix=/usr --sysconfdir=/etc
    make && make install

    echo '# Greylist'
    cd /usr/src/build/greylist
    curl -sL ftp://ftp.espci.fr/pub/milter-greylist/milter-greylist-${GREYLIST_VERSION}.tgz | tar zx --strip-components=1 -C /usr/src/build/greylist
    LDFLAGS="-L/usr/lib/libmilter" CFLAGS="-I/usr/include/libmilter" ./configure \
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
        --with-delay=600
    make && make install
    mkdir -p /var/spool/postfix/{milter-greylist,greylist}
    chown -R postfix:postfix /var/spool/postfix/{milter-greylist,greylist}

    echo '# OpenDKIM'
    cd /usr/src/build/opendkim
    useradd opendkim
    curl -sL http://netcologne.dl.sourceforge.net/project/opendkim/opendkim-${OPENDKIM_VERSION}.tar.gz | tar zx --strip-components=1
    ./configure --prefix=/usr
    make && make install

    echo '# SPF Policyd'
    mkdir -p /etc/postfix-policyd-spf-python
    pip install authres pyspf https://ipaddr-py.googlecode.com/files/ipaddr-2.1.5-py3k.tar.gz py3dns --pre
    pip install https://launchpad.net/pypolicyd-spf/${PYPOLICYD_SPF_MAIN}/${PYPOLICYD_SPF_VERSION}/+download/pypolicyd-spf-${PYPOLICYD_SPF_VERSION}.tar.gz
    mv /usr/local/bin/policyd-spf /usr/bin/policyd-spf

    echo '# OpenDMARC'
    cd /usr/src/build/opendmarc
    useradd opendmarc
    curl -sL http://netcologne.dl.sourceforge.net/project/opendmarc/opendmarc-${OPENDMARC_VERSION}.tar.gz | tar zx --strip-components=1
    ./configure --prefix=/usr --with-spf --with-sql-backend
    make && make install
    mkdir -p /var/run/opendmarc
    chown -R opendmarc:opendmarc /var/run/opendmarc

    echo '# Mailman'
    npm install -g less
    mkdir -p /etc/mailman.d /var/log/mailman
    virtualenv --system-site-packages -p python3.4 /opt/mailman
    /opt/mailman/bin/pip install --pre -U mailman mailman-hyperkitty
    /opt/mailman/bin/python -c 'import pip, subprocess; [subprocess.call("/opt/mailman/bin/pip install --pre -U " + d.project_name, shell=1) for d in pip.get_installed_distributions()]'
    virtualenv --system-site-packages -p python2.7 /opt/postorius
    /opt/postorius/bin/pip install -U --pre django-gravatar flup postorius Whoosh mock beautifulsoup4 hyperkitty python-openid python-social-auth django-browserid
    /opt/postorius/bin/python -c 'import pip, subprocess; [subprocess.call("/opt/postorius/bin/pip install --pre -U " + d.project_name, shell=1) for d in pip.get_installed_distributions()]'
    ln -s /usr/bin/nodejs /usr/bin/node
    rm /etc/nginx/conf.d/default.conf

    echo '# Milter Manager'
    cd /usr/src/build/milter-manager
    curl -sL https://github.com/milter-manager/milter-manager/archive/master.tar.gz | tar zx --strip-components=1
    [ ! -f ./configure ] && ./autogen.sh
    ./configure --prefix=/usr --sysconfdir=/etc --with-package-platform=debian
    make
    make install
}

install  
#> ${INSTALL_LOG} 2>&1
