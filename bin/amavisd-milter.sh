#!/bin/bash

su  - amavis -c \
    '/usr/sbin/amavisd-milter -f -S /var/lib/amavis/amavisd.sock  -s /var/lib/amavis/amavisd-milter.sock -p /var/run/amavis/amavisd-milter.pid'