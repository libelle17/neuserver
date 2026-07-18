#!/bin/bash
# ping.sh - überwacht dauerhaft (Endlosschleife, 1x pro Sekunde) die
# Erreichbarkeit der Fritzbox per Ping und protokolliert bei jedem Versuch
# Zeitstempel + Erfolg/"nein" nach /var/log/ping.log. Aufruf ohne Parameter;
# läuft dauerhaft im Vordergrund (z.B. in einer eigenen Terminal-/Screen-
# Sitzung starten, nicht als kurzlebiger Cron-Job).
while true; do
 Z=/var/ping.log
 ping -c 1 fritz.box >/dev/null 2>&1 && date +"%F %T" >> $Z || date +"%F %T nein" >> $Z
 sleep 1
done;

