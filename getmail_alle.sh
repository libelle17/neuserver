#!/bin/zsh
/usr/bin/pgrep -c -f "getmail -rbuchrc" || /usr/bin/getmail -rbuchhrc -rfreenetrc -rgmx1rc -rgmx2rc -rgmx3rc -rgmx4rc -rgmx5rc -rgmx6rc -rgmx7rc -rgooglerc -rgoogle2rc -rmnetrc -rvrwebrc -rweb_rc -rwebrc >>/var/log/getmail-Aufruf.log 2>&1

