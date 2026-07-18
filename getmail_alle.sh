#!/bin/zsh
# getmail_alle.sh - ruft getmail für alle konfigurierten Postfächer ab
# (jedes "-r<name>rc" verweist auf eine eigene getmail-Konfigurationsdatei,
# üblicherweise unter ~/.getmail/<name>rc), außer wenn schon ein passender
# getmail-Prozess für "buchrc" läuft (verhindert überlappende Läufe, z.B.
# bei zu eng getakteten Cron-Aufrufen). Ausgabe wird an
# /var/log/getmail-Aufruf.log angehängt. Aufruf ohne Parameter.
# Hinweis: der pgrep-Filter sucht nach "buchrc", der tatsächliche Parameter
# unten lautet aber "-rbuchhrc" (mit doppeltem h) - als Substring passt das
# eine nicht zum anderen, die Bereits-läuft-Prüfung greift dadurch vermutlich
# nie wie beabsichtigt.
/usr/bin/pgrep -c -f "getmail -rbuchrc" || /usr/bin/getmail -rbuchhrc -rfreenetrc -rgmx1rc -rgmx2rc -rgmx3rc -rgmx4rc -rgmx5rc -rgmx6rc -rgmx7rc -rgooglerc -rgoogle2rc -rmnetrc -rweb_rc -rwebrc >>/var/log/getmail-Aufruf.log 2>&1

