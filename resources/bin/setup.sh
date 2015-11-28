#!/bin/bash

trap '{ echo -e "error ${?}\nthe command executing at the time of the error was\n${BASH_COMMAND}\non line ${BASH_LINENO[0]}" && tail -n 10 ${INSTALL_LOG} && exit $? }' ERR

export DEBIAN_FRONTEND=noninteractive
export packages=(
	'arj'
	'bitdefender-scanner'
	'build-essential'
	'byacc'
	'cabextract'
	'cpio'
	'cron'
    'cpanminus'
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
	'net-tools'
	'nginx'
	'nomarch'
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

export NVM_DIR="/opt/nvm"
export PATH="${PATH}:${NVM_DIR}/npm/bin"
export NODE_PATH="${NODE_PATH}:${NVM_DIR}/npm/lib/node_modules"

# Versions
export POSTFIX_VERSION=3.0.3
export DOVECOT_VERSION=2.2.19
export DOVECOT_PIGEONHOLE=0.4.9
export OPENDKIM_VERSION=2.10.3
export PYPOLICYD_SPF_MAIN=1.3
export PYPOLICYD_SPF_VERSION=1.3.2
export CLAMAV_VERSION=0.99-rc2
export CLAMAV_MAIN=release_candidate
export AMAVISD_NEW_VERSION=2.10.1
export AMAVISD_MILTER=1.6.1
export GREYLIST_VERSION=4.5.14
export OPENDMARC_VERSION=1.3.1

pre_install()
{
	apt-key adv --keyserver keyserver.ubuntu.com --recv-keys ABF5BD827BD9BF62 2>&1 > /dev/null
	apt-key adv --keyserver keyserver.ubuntu.com --recv-keys A373FB480EC4FE05 2>&1 > /dev/null

	echo 'deb http://download.bitdefender.com/repos/deb/ bitdefender non-free' | tee -a /etc/apt/sources.list 2>&1 > /dev/null
	echo 'deb http://nginx.org/packages/mainline/ubuntu trusty nginx' | tee -a /etc/apt/sources.list 2>&1 > /dev/null

	apt-get update -q 2>&1
	apt-get install -yq ${packages[@]} 2>&1

	easy_install3 pip 2>&1 > /dev/null

	sources=(
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

	mkdir -vp ${sources[@]} 2>&1

    return 0
}

create_users()
{
	adduser --quiet --system --group --uid 1000 --home /var/vmail --shell /usr/sbin/nologin --disabled-password vmail
	adduser --quiet --system --group --no-create-home --shell /usr/sbin/nologin --disabled-password clamav
	adduser --quiet --system --group --no-create-home --shell /usr/sbin/nologin --disabled-password amavis
	adduser --quiet --system --group --no-create-home --shell /usr/sbin/nologin --disabled-password postfix
	adduser --quiet --system --group --no-create-home --shell /usr/sbin/nologin --disabled-password postdrop
	adduser --quiet --system --group --no-create-home --shell /usr/sbin/nologin --disabled-password dovenull
	adduser --quiet --system --group --no-create-home --shell /usr/sbin/nologin --disabled-password dovecot
	adduser --quiet --system --group --no-create-home --shell /usr/sbin/nologin --disabled-password opendkim
	adduser --quiet --system --group --no-create-home --shell /usr/sbin/nologin --disabled-password opendmarc

    return 0
}

clamav()
{
	cd /usr/src/build/clamav
	adduser --quiet clamav amavis
	curl --silent -L http://www.clamav.net/downloads/${CLAMAV_MAIN}/clamav-${CLAMAV_VERSION}.tar.gz | tar zx --strip-components=1
	./configure --prefix=/usr --sysconfdir=/etc --with-working-dir=/var/lib/amavis 2>&1
	make 2>&1
	make install 2>&1
	mkdir -p /var/run/clamav /var/lib/clamav /var/log/clamav
	chown -R clamav:clamav /var/run/clamav /var/lib/clamav /var/log/clamav

    return 0
}

bitdefender()
{
	echo 'LicenseAccepted = True' >> /opt/BitDefender-scanner/etc/bdscan.conf

    return 0
}

spamassassin()
{
	cpanm -fnq install Mail::SPF::Query Mail::SpamAssassin 2>&1

	sa-update 2>&1

    return 0
}

amavisd()
{
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

    ./configure --with-working-dir=/var/lib/amavis/tmp --prefix=/usr 2>&1
	make 2>&1
	make install 2>&1

    return 0
}

postfix()
{
	cd /usr/src/build/postfix

	curl --silent -L http://de.postfix.org/ftpmirror/official/postfix-${POSTFIX_VERSION}.tar.gz | tar zx --strip-components=1 2>&1

	make -f Makefile.init \
        "CCARGS=-DHAS_MYSQL -DHAS_PCRE -I/usr/include/mysql $(pcre-config --cflags) -DUSE_SASL_AUTH -DUSE_TLS" \
        "AUXLIBS_MYSQL=-L/usr/include/mysql -lmysqlclient -lz -lm $(pcre-config --libs) -lssl -lcrypto" 2>&1

	sh ./postfix-install -non-interactive install_root=/ 2>&1

    return 0
}

postfix_configure()
{
	main=(
		'smtpd_tls_cert_file = /etc/ssl/certs/ssl-cert-snakeoil.pem'
		'smtpd_tls_key_file = /etc/ssl/private/ssl-cert-snakeoil.key'
		'smtpd_use_tls = yes'
		'smtpd_tls_session_cache_database = btree:${data_directory}/smtpd_scache'
		'smtp_tls_session_cache_database = btree:${data_directory}/smtp_scache'
		'mydestination = $myhostname'
		'relay_domains = $mydestination'
		'myhostname = mail.example.org'
		'recipient_delimiter = +'
		'mynetworks = 127.0.0.0/8 [::ffff:127.0.0.0]/104 [::1]/128'
		'mailbox_size_limit = 0'
		'inet_interfaces = all'
		'soft_bounce = no'
		'delay_warning_time = 4'
		'setgid_group = postdrop'
		'mail_owner = postfix'
		'smtpd_banner = $myhostname ESMTP $mail_name'
		'smtpd_helo_restrictions = permit_sasl_authenticated,permit_mynetworks,reject_non_fqdn_hostname,reject_invalid_hostname,permit'
		'smtpd_sender_restrictions = permit_sasl_authenticated,reject_non_fqdn_sender,reject_unknown_sender_domain'
		'smtpd_recipient_restrictions = permit_sasl_authenticated,permit_mynetworks,reject_unauth_destination,reject_non_fqdn_recipient,reject_non_fqdn_hostname,reject_unknown_recipient_domain,reject_unknown_sender_domain,reject_rbl_client zen.spamhaus.org,reject_rbl_client dul.dnsbl.sorbs.net,reject_rbl_client bl.spamcop.net,reject_rbl_client b.barracudacentral.org,reject_rbl_client psbl.surriel.com,reject_rbl_client ix.dnsbl.manitu.net,check_policy_service unix:private/policy-spf,permit'
		'smtpd_sasl_auth_enable = yes'
		'smtpd_sasl_security_options = noanonymous'
		'smtpd_sasl_local_domain = $mydomain'
		'broken_sasl_auth_clients = yes'
		'smtpd_sasl_type = dovecot'
		'smtpd_sasl_path = private/auth'
		'alias_maps = hash:/etc/aliases'
		'alias_database = hash:/etc/aliases'
		'dovecot_destination_recipient_limit = 1'
		'virtual_alias_maps = mysql:/etc/postfix/virtual/mysql-virtual-user-aliases.cf, mysql:/etc/postfix/virtual/mysql-virtual-domain-aliases.cf'
		'virtual_gid_maps = static:1000'
		'virtual_mailbox_base = /var/vmail'
		'virtual_mailbox_domains = mysql:/etc/postfix/virtual/mysql-virtual-mailbox-domains.cf'
		'virtual_mailbox_maps = mysql:/etc/postfix/virtual/mysql-virtual-mailbox-maps.cf'
		'virtual_minimum_uid = 1000'
		'virtual_transport = lmtp:unix:private/dovecot-lmtp'
		'virtual_uid_maps = static:1000'
		'policy-spf_time_limit = 3600s'
		'inet_protocols = all'
		'milter_default_action = accept'
		'milter_protocol = 6'
		'milter_mail_macros = {auth_author} {auth_type} {auth_authen}'
		'smtpd_milters = inet:[127.0.0.1]:10025'
        'lmtp_tls_mandatory_protocols = !SSLv2,!SSLv3'
        'lmtp_tls_protocols = !SSLv2,!SSLv3'
        'smtpd_tls_mandatory_protocols = !SSLv2,!SSLv3'
	)

	for m in "${main[@]}"
	do
		postconf -e "${m}" 2>&1
	done


	sed -i 's/^#submission inet n       -       n       -       -       smtpd/submission inet n       -       n       -       -       smtpd/g' /etc/postfix/master.cf 2>&1
	sed -i 's/^#smtps     inet  n       -       n       -       -       smtpd/smtps     inet  n       -       n       -       -       smtpd/g' /etc/postfix/master.cf 2>&1

	cat <<EOF >> /etc/postfix/master.cf
dovecot   unix  -       n       n       -       -       pipe
  flags=DRhu user=vmail:vmail argv=/usr/libexec/dovecot/deliver -f \${sender} -d \${recipient}
EOF

	cat <<EOF >> /etc/postfix/master.cf
policy-spf  unix  -       n       n       -       -       spawn
    user=nobody argv=/usr/bin/policyd-spf /etc/postfix-policyd-spf-python/policyd-spf.conf
EOF

	master=(
		'submission/inet/syslog_name=postfix/submission'
		'submission/inet/smtpd_tls_security_level=encrypt'
		'submission/inet/smtpd_sasl_auth_enable=yes'
		'submission/inet/smtpd_reject_unlisted_recipient=no'
		'submission/inet/smtpd_recipient_restrictions='
		'submission/inet/smtpd_relay_restrictions=permit_sasl_authenticated,reject'
		'submission/inet/milter_macro_daemon_name=ORIGINATING'
		'smtps/inet/syslog_name=postfix/smtps'
		'smtps/inet/smtpd_tls_wrappermode=yes'
		'smtps/inet/smtpd_sasl_auth_enable=yes'
		'smtps/inet/smtpd_reject_unlisted_recipient=no'
		'smtps/inet/smtpd_recipient_restrictions='
		'smtps/inet/smtpd_relay_restrictions=permit_sasl_authenticated,reject'
		'smtps/inet/milter_macro_daemon_name=ORIGINATING'
	)

	for m in "${master[@]}"
	do
		postconf -P "${m}" 2>&1
	done

    return 0
}

dovecot()
{
	cd /usr/src/build/dovecot
	IFS='.' read -ra PARSE <<< "${DOVECOT_VERSION}"
	DOVECOT_MAIN=$(echo "${PARSE[0]}.${PARSE[1]}")
	curl --silent -L \
        http://dovecot.org/releases/${DOVECOT_MAIN}/dovecot-${DOVECOT_VERSION}.tar.gz | tar zx --strip-components=1 2>&1
	./configure --prefix=/usr --sysconfdir=/etc --with-mysql --with-ssl --without-shared-libs 2>&1
	make 2>&1
    make install 2>&1

	echo '# Dovecot Sieve / ManageSieve'
	cd /usr/src/build/pigeonhole
	curl --silent -L \
        http://pigeonhole.dovecot.org/releases/${DOVECOT_MAIN}/dovecot-${DOVECOT_MAIN}-pigeonhole-${DOVECOT_PIGEONHOLE}.tar.gz | tar zx --strip-components=1 2>&1

	./configure --prefix=/usr --sysconfdir=/etc 2>&1
	make 2>&1
	make install 2>&1

    return 0
}

greylist()
{
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
		--with-delay=600 2>&1
	make 2>&1
	make install 2>&1

	mkdir -p /var/spool/postfix/milter-greylist /var/spool/postfix/greylist
	chown -R postfix:postfix /var/spool/postfix/milter-greylist /var/spool/postfix/greylist

    return 0
}

opendkim()
{
	cd /usr/src/build/opendkim

	curl --silent -L \
        http://netcologne.dl.sourceforge.net/project/opendkim/opendkim-${OPENDKIM_VERSION}.tar.gz | tar zx --strip-components=1 2>&1

	./configure --prefix=/usr 2>&1
	make 2>&1
	make install 2>&1

    return 0
}

spf()
{
	mkdir -p /etc/postfix-policyd-spf-python

	pip install \
        authres pyspf https://ipaddr-py.googlecode.com/files/ipaddr-2.1.5-py3k.tar.gz py3dns --pre 2>&1

	pip install \
        https://launchpad.net/pypolicyd-spf/${PYPOLICYD_SPF_MAIN}/${PYPOLICYD_SPF_VERSION}/+download/pypolicyd-spf-${PYPOLICYD_SPF_VERSION}.tar.gz 2>&1

	mv /usr/local/bin/policyd-spf /usr/bin/policyd-spf

    return 0
}

opendmarc()
{
	cd /usr/src/build/opendmarc
	curl --silent -L \
        http://netcologne.dl.sourceforge.net/project/opendmarc/opendmarc-${OPENDMARC_VERSION}.tar.gz | tar zx --strip-components=1 2>&1

	./configure --prefix=/usr --with-spf --with-sql-backend 2>&1
	make 2>&1
	make install 2>&1

	mkdir -p /var/run/opendmarc
	chown -R opendmarc:opendmarc /var/run/opendmarc

    return 0
}

mailman()
{
    eval load_nvm

	npm install -g less 2>&1

	mkdir -p /etc/mailman.d /var/log/mailman

	virtualenv -p python3.4 /opt/mailman 2>&1
	/opt/mailman/bin/pip install -I --pre -U \
        mailman mailman-hyperkitty 2>&1
	/opt/mailman/bin/python -c 'import pip, subprocess; [subprocess.call("/opt/mailman/bin/pip install --pre -U " + d.project_name, shell=1) for d in pip.get_installed_distributions()]' 2>&1

	virtualenv -p python2.7 /opt/postorius 2>&1
	/opt/postorius/bin/pip install -I -U \
        django==1.8.6 django-gravatar flup postorius Whoosh mock \
        beautifulsoup4 hyperkitty python-openid python-social-auth \
        django-browserid uwsgi django-uwsgi gunicorn==19.1 gevent django-xforwardedfor-middleware 2>&1
	/opt/postorius/bin/python -c 'import pip, subprocess; [subprocess.call("/opt/postorius/bin/pip install --pre -U " + d.project_name, shell=1) for d in pip.get_installed_distributions()]' 2>&1

	ln -s /usr/bin/nodejs /usr/bin/node
	rm /etc/nginx/conf.d/default.conf

    return 0
}

install_ruby_rvm()
{
    gpg --keyserver hkp://keys.gnupg.net --recv-keys D39DC0E3 > /dev/null 2>&1
	curl --silent -L \
        https://get.rvm.io | bash 2>&1

	source /etc/profile.d/rvm.sh

    rvm install 2.1.7 2>&1
	rvm use 2.1.7 2>&1
    rvm alias create default 2.1.7 2>&1
	echo 'gem: --no-document' | tee ${APP_HOME}/.gemrc 2>&1
	gem install bundler 2>&1

	return 0
}

install_node_nvm()
{
    curl --location --silent -S \
        https://raw.githubusercontent.com/creationix/nvm/master/install.sh | bash 2>&1 || return 1

    # Add variables to the default nvm loader
    echo '' >> ${NVM_DIR}/nvm.sh || return 1
    echo '# Set default variables' >> ${NVM_DIR}/nvm.sh || return 1
    echo "export PATH=\${PATH}:\${NVM_DIR}/npm/bin" >> ${NVM_DIR}/nvm.sh || return 1
    echo "export NODE_PATH=\${NODE_PATH}:\${NVM_DIR}/npm/lib/node_modules" >> ${NVM_DIR}/nvm.sh || return 1

    eval load_nvm 2>&1 || return 1

    nvm install stable 2>&1 || return 1
    nvm alias default stable 2>&1 || return 1
    nvm use stable 2>&1 || return 1

    return 0
}

milter_manager()
{
    eval load_rvm

	cd /usr/src/build/milter-manager
	curl --silent -L \
        https://github.com/milter-manager/milter-manager/archive/master.tar.gz | tar zx --strip-components=1 2>&1
	[ ! -f ./configure ] && ./autogen.sh 2>&1

	/bin/bash -l -c './configure --prefix=/usr --sysconfdir=/etc --with-package-platform=debian' 2>&1
	make 2>&1
	make install 2>&1

	return 0
}

load_rvm()
{
    if [ -f "/etc/profile.d/rvm.sh" ]
    then
        source /etc/profile.d/rvm.sh
    fi
}

load_nvm()
{
    if [ -f ${NVM_DIR}/nvm.sh ]; then
        source "${NVM_DIR}/nvm.sh" 2>&1 || return 1
    else
        echo "Could not load NVM"
        return 1
    fi

    return 0
}

post_install()
{
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

    tar --numeric-owner --create --auto-compress ${configs[@]} | gzip -9 - > /root/config.tar.gz

    /usr/bin/freshclam --config-file=/etc/clamav/freshclam.conf

    apt-get autoremove
    apt-get autoclean
    rm -fr /var/lib/apt /usr/src/build

    return 0
}

build() {
	if [ ! -f "${INSTALL_LOG}" ]
	then
		touch "${INSTALL_LOG}"
	fi

	tasks=(
		'create_users'
		'pre_install'
        'install_ruby_rvm'
        'install_node_nvm'
		'clamav'
		'bitdefender'
		'spamassassin'
		'amavisd'
		'postfix'
		'postfix_configure'
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
		${task} | tee -a "${INSTALL_LOG}" > /dev/null 2>&1 || exit 1
        #${task} | tee -a "${INSTALL_LOG}" || exit 1
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
