#!/bin/bash

chown -R sympa:sympa /home/sympa

service fcgiwrap start
nginx

/usr/bin/perl /home/sympa/bin/bulk.pl
/usr/bin/perl /home/sympa/bin/archived.pl
/usr/bin/perl /home/sympa/bin/bounced.pl
/usr/bin/perl /home/sympa/bin/task_manager.pl
/usr/bin/perl /home/sympa/bin/sympa.pl --foreground