#!/bin/bash
set -e

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

postinstall() {
	echo '# Create archive of all default configs'
	tar --numeric-owner --create --auto-compress --file "/root/config.tar.gz" ${configs[@]}

	echo '# Initialise ClamAV'
	/usr/bin/freshclam --config-file=/etc/clamav/freshclam.conf

	echo '# Set permissions'
	chmod +x /usr/local/bin/*

	echo '# Create source archive'
	tar --numeric-owner --create --auto-compress --file "/root/build.tar.gz" --directory "/usr/src/build" --transform='s,^./,,' .

	echo '# Cleanup APT'
	apt-get clean
	rm -fr /var/lib/apt /usr/src/build
}

postinstall 2>&1 | tee -a ${INSTALL_LOG}
