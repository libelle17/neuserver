#!/bin/zsh
# getmail_gmx7.sh - ruft getmail nur für das Postfach "gmx7" ab (eigene
# Konfiguration ~/.getmail/gmx7rc), außer es läuft schon ein passender
# getmail-Prozess für "gmx7rc" (verhindert überlappende Läufe). Ausgabe wird
# an /var/log/getmail-Aufruf_gmx7.log angehängt. Aufruf ohne Parameter.
/usr/bin/pgrep -c -f "getmail -rgmx7rc" || /usr/bin/getmail -rgmx7rc >>/var/log/getmail-Aufruf_gmx7.log 2>&1

