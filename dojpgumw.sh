#!/bin/zsh
# dojpgumw.sh - startet jpgumw.sh nur, wenn nicht schon eine Instanz davon
# läuft (verhindert doppelte parallele Läufe, z.B. bei Aufruf per Cron in
# kurzen Abständen). Aufruf: dojpgumw.sh [Parameter für jpgumw.sh] - alle
# Argumente werden per "$@" durchgereicht.
D=jpgumw.sh;
ps h -C $D >/dev/null||eval $D "$@";
