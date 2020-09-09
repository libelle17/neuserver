#!/bin/zsh
ROT_="\033[31m"
BLAU_="\033[34m"
SCHWARZ_="\033[0m"
if [ $# -lt 1 ]; then
 echo "$BLAU_$0$SCHWARZ_: Ruft Programm mit Parametern auf und verhindert gleichzeitigen Doppelaufruf"
 echo "Syntax: $BLAU_$0$SCHWARZ_ <parameter>"
else
 if /usr/bin/ps -Alf | /usr/bin/grep "$*" | /usr/bin/grep -v grep | /usr/bin/grep -v $0 >/dev/null; then
  echo "$BLAU_\"$@\"$ROT_ laeuft schon. Rufe es nicht auf.$SCHWARZ_"
 else
  echo "${ROT_}Rufe auf: $BLAU_$@$SCHWARZ_"
  $@
 fi
fi
