#!/bin/zsh
# ende.sh - setzt einen RTC-Weckalarm auf heute 13:15 Uhr und schaltet den
# Rechner sofort aus (rtcwake -m off = "poweroff", nicht Suspend). Aufruf ohne
# Parameter. Die auskommentierte Zeile war ein (verworfener) Versuch, die
# Zielzeit unter Berücksichtigung der Zeitzonenverschiebung ($(date +%z))
# relativ zu 12:23 Uhr zu berechnen, mit "-m disk" (Ruhezustand) statt Poweroff.
rtcwake -t $(date -d'today 13:15' +%s) -m off
# rtcwake -t $(($(date +%z|cut -b2-5|sed -e's/^0*//')*36+$(date -d'today 12:23' +%s))) -m disk
