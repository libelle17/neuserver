#!/bin/zsh
# hier der neuere Kommentar und noch neuer
rot="\033[31m"
blau="\033[34m"
schwarz="\033[0m"
if [ $# -lt 1 ]; then
 echo "$blau$0$schwarz: Ruft Programm mit Parametern auf und verhindert gleichzeitigen Doppelaufruf"
 echo "Syntax: $blau$0$schwarz <parameter>"
else
 if /usr/bin/ps -Alf | /usr/bin/grep "$*" | /usr/bin/grep -v grep | /usr/bin/grep -v $0 >/dev/null; then
  echo "$blau\"$@\"$rot laeuft schon. Rufe es nicht auf.$schwarz"
 else
  echo "${rot}Rufe auf: $blau$@$schwarz"
  $@
 fi
fi
