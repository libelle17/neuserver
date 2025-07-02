#!/bin/bash
# Sicherungsprogramm für Medical Office für ransomware, Gerald Schade 2.7.25
# dash geht nicht: --exclude={,abc/,def/} wirkt nicht
# soll alle relevanten Datenen kopieren, fuer z.B. 2 x täglichen Gebrauch
MUPR=$(readlink -f $0); # Mutterprogramm
. ${MUPR%/*}/bul1.sh # LINEINS=linux1, buhost festlegen
[ "$buhost"/ = "$LINEINS"/ ]&&ZL=||QL=$LINEINS;
. ${MUPR%/*}/bugem.sh # commandline-Parameter, $ZL aus commandline, $qssh, $zssh festlegen
[ "$buhost"/ != "$LINEINS"/ -a "$ZL" ]&&{ printf "Ziel \"$blau$ZL$reset\" wird zurückgesetzt.\n"; ZL=;ZmD=;}
[ "$buhost"/ = "$LINEINS"/ -a -z "$ZL" ]&&{ printf "${rot}Kein Ziel angegeben. Breche ab$reset.\n";exit;}

# kopiere mit Test auf ausreichenden Speicher
# kopiermt() { # mit test
  # $1 = Verzeichnis auf Quelle
  # $2 = Verzeichnis auf Ziel
  # $3 = excludes
  # $4 = Optionen 
	# $5 = Pfad zur Datei, die als Alterskriterium geprüft werden soll
	# $6 = Zahl der Sekunden Altersunterschied, ab der kopiert werden soll
  # $7 = ob ohne Platzprüfung
  # vorher müssen ggf. Quellrechner in $QL (z.Zt. nur: leer oder linux1) und Zielrechner in $ZL hinterlegt sein
  # P1obs=$(echo "$1"|sed 's/\\//g'); # Parameter 1 ohne backslashes
ssh linux1 /root/bin/mountwser.sh
# muss hier nicht aufgerufen werden, da er von linux1 aus kopiert
for uvz in tmexport indamed; do
	kopiermt /mnt/wser/$uvz /DATA/wser/ "" "" "" "" 1
done;
