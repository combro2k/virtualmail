#!/bin/bash
set -e

function stop {
    echo Stopping postfix
    /usr/sbin/postfix stop

    exit
}

function reload {
    echo Reloading postfix

    /usr/sbin/postfix reload
}

function start {
    # Run new aliases
    # start postfix
    /usr/sbin/postfix -c /etc/postfix start
    # avoid exiting
}

trap stop EXIT SIGTERM SIGINT
trap reload SIGHUP

start

sleep infinity