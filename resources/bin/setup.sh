#!/bin/bash
set -Ea

trap '{ echo -e "error ${?}\nthe command executing at the time of the error was\n${BASH_COMMAND}\non line ${BASH_LINENO[0]}" && tail -n 10 ${INSTALL_LOG} && exit $? }' ERR

DEBIAN_FRONTEND=noninteractive
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
    'git'
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
    'libtool'
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
    'ssl-cert'
    'supervisor'
    'unzip'
    'vim'
    'xz-utils'
    'zip'
)

pre_install() {
	apt-key adv --keyserver keyserver.ubuntu.com --recv-keys ABF5BD827BD9BF62 2>&1 > /dev/null
	apt-key adv --keyserver keyserver.ubuntu.com --recv-keys A373FB480EC4FE05 2>&1 > /dev/null

	echo 'deb http://download.bitdefender.com/repos/deb/ bitdefender non-free' | tee -a /etc/apt/sources.list 2>&1 > /dev/null
	echo 'deb http://nginx.org/packages/mainline/ubuntu trusty nginx' | tee -a /etc/apt/sources.list 2>&1 > /dev/null

	apt-get update -q
	apt-get install -yq ${packages[@]}
	easy_install3 pip
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
}

post_install() {
	configs=(
		'/etc/amavis'
		'/etc/clamav'
		'/etc/cron.d'
		'/etc/dovecot'
		'/etc/greylist'
		'/etc/mailman'
		'/etc/milter-manager'
		'/etc/nginx'
		'/etc/opendkim'
		'/etc/postfix'
		'/etc/postfix-policyd-spf-python'
		'/etc/spamassassin'
		'/etc/supervisor'
		'/etc/mailname'
	)

	tar --numeric-owner --create --auto-compress --file "/root/config.tar.gz" ${configs[@]}

	/usr/bin/freshclam --config-file=/etc/clamav/freshclam.conf

	chmod +x /usr/local/bin/*

	tar --numeric-owner --create --auto-compress --file "/root/build.tar.gz" --directory "/usr/src/build" --transform='s,^./,,' .

	apt-get clean
	rm -fr /var/lib/apt /usr/src/build
}

create_users() {
	adduser --quiet --system --group --comment 'Virtualmail User' --uid 1000 --home /var/vmail --shell /usr/sbin/nologin --disabled-password vmail
	adduser --quiet --system --group --comment 'Clamav Daemon User' --no-create-home --shell /usr/sbin/nologin --disabled-password clamav
	adduser --quiet --system --group --comment 'Amavisd Daemon User' --no-create-home --shell /usr/sbin/nologin --disabled-password amavis
	adduser --quiet --system --group --comment 'Postfix Daemon User' --no-create-home --shell /usr/sbin/nologin --disabled-password postfix
	adduser --quiet --system --group --comment 'Postfix Daemon Helper' --no-create-home --shell /usr/sbin/nologin --disabled-password postdrop
	adduser --quiet --system --group --comment 'Dovecot Daemon Helper' --no-create-home --shell /usr/sbin/nologin --disabled-password dovenull
	adduser --quiet --system --group --comment 'Dovecot Daemon User' --no-create-home --shell /usr/sbin/nologin --disabled-password dovecot
	adduser --quiet --system --group --comment 'OpenDKIM Daemon User' --no-create-home --shell /usr/sbin/nologin --disabled-password opendkim
	adduser --quiet --system --group --comment 'OpenDMARC Daemon User' --no-create-home --shell /usr/sbin/nologin --disabled-password opendmarc
}

clamav() {
	cd /usr/src/build/clamav
	adduser --quiet clamav amavis
	curl --silent -L http://netcologne.dl.sourceforge.net/project/clamav/clamav/${CLAMAV_VERSION}/clamav-${CLAMAV_VERSION}.tar.gz | tar zx --strip-components=1
	./configure --prefix=/usr --sysconfdir=/etc --with-working-dir=/var/lib/amavis
	make && make install
	mkdir -p /var/run/clamav /var/lib/clamav /var/log/clamav && chown -R clamav:clamav /var/run/clamav /var/lib/clamav /var/log/clamav
}

bitdefender() {
	echo 'LicenseAccepted = True' >> /opt/BitDefender-scanner/etc/bdscan.conf
}

spamassassin() {
	cpan -f install Mail::SPF::Query
	cpan -f install Mail::SpamAssassin
	sa-update
}

amavisd() {
	cd /usr/src/build/amavisd-new
	adduser --quiet amavis clamav
	mkdir -p /var/run/amavis /var/lib/amavis/tmp /var/lib/amavis/db /var/lib/amavis/virusmails
	chown -R amavis:amavis /var/run/amavis /var/lib/amavis
	chmod -R 770 /var/lib/amavis
	curl --silent -L http://mirror.omroep.nl/amavisd-new/amavisd-new-${AMAVISD_NEW_VERSION}.tar.xz | tar Jx --strip-components=1
	cp amavisd /usr/sbin/amavisd-new
	cp amavisd-nanny /usr/sbin/amavisd-nanny
	cp amavisd-release /usr/sbin/amavisd-release
	cp amavisd-submit /usr/sbin/amavisd-submit
	chown root:root /usr/sbin/amavisd-nanny /usr/sbin/amavisd-release /usr/sbin/amavisd-new /usr/sbin/amavisd-submit
	chmod 755 /usr/sbin/amavisd-nanny /usr/sbin/amavisd-release /usr/sbin/amavisd-new /usr/sbin/amavisd-submit
	sed -i 's#/var/amavis/amavisd.sock#/var/lib/amavis/amavisd.sock#g' /usr/sbin/amavisd-release

	cd /usr/src/build/amavisd-milter
	curl --silent -L http://netcologne.dl.sourceforge.net/project/amavisd-milter/amavisd-milter/amavisd-milter-${AMAVISD_MILTER}/amavisd-milter-${AMAVISD_MILTER}.tar.gz | tar zx --strip-components=1
	./configure --with-working-dir=/var/lib/amavis/tmp --prefix=/usr
	make && make install
}

postfix() {
	cd /usr/src/build/postfix

	curl --silent -L http://de.postfix.org/ftpmirror/official/postfix-${POSTFIX_VERSION}.tar.gz | tar zx --strip-components=1
	make -f Makefile.init "CCARGS=-DHAS_MYSQL -DHAS_PCRE -I/usr/include/mysql $(pcre-config --cflags) -DUSE_SASL_AUTH -DUSE_TLS" "AUXLIBS_MYSQL=-L/usr/include/mysql -lmysqlclient -lz -lm $(pcre-config --libs) -lssl -lcrypto"
	sh ./postfix-install -non-interactive install_root=/
}

dovecot() {
	cd /usr/src/build/dovecot
	IFS='.' read -ra PARSE <<< "${DOVECOT_VERSION}"
	DOVECOT_MAIN=$(echo "${PARSE[0]}.${PARSE[1]}")
	curl --silent -L http://dovecot.org/releases/${DOVECOT_MAIN}/dovecot-${DOVECOT_VERSION}.tar.gz | tar zx --strip-components=1
	./configure --prefix=/usr --sysconfdir=/etc --with-mysql --with-ssl --without-shared-libs
	make && make install

	echo '# Dovecot Sieve / ManageSieve'
	cd /usr/src/build/pigeonhole
	curl --silent -L http://pigeonhole.dovecot.org/releases/${DOVECOT_MAIN}/dovecot-${DOVECOT_MAIN}-pigeonhole-${DOVECOT_PIGEONHOLE}.tar.gz | tar zx --strip-components=1
	./configure --prefix=/usr --sysconfdir=/etc
	make && make install
}

greylist() {
	cd /usr/src/build/greylist
	curl --silent -L ftp://ftp.espci.fr/pub/milter-greylist/milter-greylist-${GREYLIST_VERSION}.tgz | tar zx --strip-components=1 -C /usr/src/build/greylist
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
}

opendkim() {
	cd /usr/src/build/opendkim
	curl --silent -L http://netcologne.dl.sourceforge.net/project/opendkim/opendkim-${OPENDKIM_VERSION}.tar.gz | tar zx --strip-components=1
	./configure --prefix=/usr
	make && make install
}

spf() {
	mkdir -p /etc/postfix-policyd-spf-python
	pip install authres pyspf https://ipaddr-py.googlecode.com/files/ipaddr-2.1.5-py3k.tar.gz py3dns --pre
	pip install https://launchpad.net/pypolicyd-spf/${PYPOLICYD_SPF_MAIN}/${PYPOLICYD_SPF_VERSION}/+download/pypolicyd-spf-${PYPOLICYD_SPF_VERSION}.tar.gz
	mv /usr/local/bin/policyd-spf /usr/bin/policyd-spf
}

opendmarc() {
	cd /usr/src/build/opendmarc
	curl --silent -L http://netcologne.dl.sourceforge.net/project/opendmarc/opendmarc-${OPENDMARC_VERSION}.tar.gz | tar zx --strip-components=1
	./configure --prefix=/usr --with-spf --with-sql-backend
	make && make install
	mkdir -p /var/run/opendmarc
	chown -R opendmarc:opendmarc /var/run/opendmarc
}

mailman() {
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
}

milter_manager() {
	gpg --keyserver hkp://keys.gnupg.net --recv-keys D39DC0E3 2>&1 > /dev/null
	curl --silent -L https://get.rvm.io | bash

	if [ -f "/usr/local/rvm/scripts/rvm" ]
	then
		source /usr/local/rvm/scripts/rvm
	fi

	rvm install 2.1.7 && rvm use 2.1.7
	echo 'gem: --no-document' | tee ${APP_HOME}/.gemrc
	gem install bundler

	cd /usr/src/build/milter-manager
	curl --silent -L https://github.com/milter-manager/milter-manager/archive/master.tar.gz | tar zx --strip-components=1
	[ ! -f ./configure ] && ./autogen.sh
	./configure --prefix=/usr --sysconfdir=/etc --with-package-platform=debian
	make
	make install
}

build() {
	if [ ! -f "${INSTALL_LOG}" ]
	then
		touch "${INSTALL_LOG}"
	fi

	tasks=(
		'pre_install'
		'create_users'
		'clamav'
		'bitdefender'
		'spamassassin'
		'amavisd'
		'postfix'
		'dovecot'
		'greylist'
		'opendkim'
		'spf'
		'opendmarc'
		'mailman'
		'milter_manager'
	)

	for task in ${tasks[@]}
	do
		echo "Running build task ${task}..."
		${task} | tee -a "${INSTALL_LOG}" 2>&1 > /dev/null || exit 1
	done
}

if [ $# -eq 0 ]
then
	echo "No parameters given! (${@})"
	echo "Available functions:"
	echo

	compgen -A function

	exit 1
else
	for task in ${@}
	do
		echo "Running ${task}..."
		${task} || exit 1
	done
fi
