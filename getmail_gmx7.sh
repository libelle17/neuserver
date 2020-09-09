#!/bin/zsh
/usr/bin/pgrep -c -f "getmail -rgmx7rc" || /usr/bin/getmail -rgmx7rc >>/var/log/getmail-Aufruf_gmx7.log 2>&1

