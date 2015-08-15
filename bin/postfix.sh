#!/bin/bash

function stop {
    echo Stopping postfix

    /usr/sbin/postfix stop

    # stop mailman if mailinglist is enabled
    test ! -z "${MAILINGLIST}" && echo Stopping mailman && supervisorctl stop mailman

    # lets give postfix and mailman some time to stop
    sleep 5s

    exit
}

function reload {
    echo Reloading postfix
    /usr/sbin/postfix reload
}

function start {
    # Run new aliases
    test ! -f "/etc/aliases" && touch /etc/aliases
    /usr/bin/newaliases

    # start postfix
    /usr/sbin/postfix -c /etc/postfix start
    # avoid exiting

    # lets give postfix some time to start
    sleep 5s

    # start mailman if mailinglist is enabled
    test ! -z "${MAILINGLIST}" && supervisorctl start mailman
}

trap stop EXIT SIGTERM SIGINT
trap reload SIGHUP

start

sleep infinity