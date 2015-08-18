FROM ubuntu-debootstrap:14.04

MAINTAINER Martijn van Maurik <docker@vmaurik.nl>

# Environment variables
ENV HOME=/root \
    INSTALL_LOG=/var/log/build.log \
    AMAVISD_DB_HOME=/var/lib/amavis/db

# Software versions
ENV POSTFIX_VERSION=3.0.2 \
    DOVECOT_VERSION=2.2.18 \
    DOVECOT_PIGEONHOLE=0.4.8 \
    OPENDKIM_VERSION=2.10.3 \
    PYPOLICYD_SPF_MAIN=1.3 \
    PYPOLICYD_SPF_VERSION=1.3.1 \
    CLAMAV_VERSION=0.98.7 \
    AMAVISD_NEW_VERSION=2.10.1 \
    AMAVISD_MILTER=1.6.1 \
    GREYLIST_VERSION=4.5.14 \
    OPENDMARC_VERSION=1.3.1 \
    MILTER_MANAGER_VERSION=2.0.5

ADD ["resources/scripts/_install.sh", "resources/scripts/_postinstall.sh", "/root/"]

RUN touch ${INSTALL_LOG} && \
    chmod +x /root/_install.sh /root/_postinstall.sh && \
    /root/_install.sh 2>&1 >> ${INSTALL_LOG}

# Add resources
ADD resources/etc/ /etc/
ADD resources/opt/ /opt/
ADD resources/bin/ /usr/local/bin/

# Run the last bits and clean up
RUN /root/_postinstall.sh 2>&1 >> ${INSTALL_LOG} && \
    rm /root/_postinstall.sh /root/_install.sh

EXPOSE 25 80 110 143 465 587 993 995 4190
VOLUME ["/var/vmail", "/etc/dovecot", "/etc/postfix", "/etc/amavis" , "/etc/opendkim", "/etc/opendmarc", "/var/mailman", "/etc/mailman"]

CMD ["/usr/local/bin/run"]

