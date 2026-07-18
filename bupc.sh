#!/bin/bash
# bupc.sh - kopiert die Turbomed-Datenbanken (PraxisDB, StammDB, DruckDB,
# Dictionary) per rsync auf einen Windows-PC $1, der über eine CIFS-Freigabe
# "Turbomed" mit den in /root/.sturm hinterlegten Zugangsdaten erreichbar
# ist (wird bei Bedarf unter /mnt/$1/Turbomed gemountet). Aufruf: bupc.sh
# <pc>.
	blau="\033[1;34m"; # für Programmausgaben
	rot="\033[1;31m";
	lila="\033[1;35m";
	reset="\033[0m"; # Farben zurücksetzen
if [ $# -ne 1 ]; then
  printf "Programm $blau$0$reset: versucht die Turbomed-Datenbanken auf einen PC zu kopieren.\n";
  printf "  Benutzung:\n";
  printf "$blau$0 <pc>$reset\n";
  exit;
else
  mkdir -p /mnt/$1/Turbomed
  umount /mnt/$1/Turbomed
  mount //$1/Turbomed /mnt/$1/Turbomed -t cifs -o "nofail,credentials=/root/.sturm,noserverino"
  rsync -avuz /opt/turbomed/ /mnt/$1/Turbomed --progress --include='PraxisDB/***' --include='StammDB/***' --include='DruckDB/***' --include='Dictionary/***' --exclude='*'
fi;
