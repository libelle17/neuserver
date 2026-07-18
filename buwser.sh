#!/bin/bash
# buwser.sh - Sicherungsprogramm für Medical Office für ransomware, Gerald
# Schade 2.7.25 (dash geht nicht: --exclude={,abc/,def/} wirkt nicht,
# deshalb bash). Soll alle relevanten Daten kopieren, fuer z.B. 2 x
# täglichen Gebrauch: mountet zunächst die WSER-Freigaben (per
# mountwser.sh) und kopiert dann per kopiermt() (aus bugem.sh) sowohl
# tmexport als auch indamed von /mnt/wser/<uvz> nach /DATA/wser/, mit
# Prüfung, ob die Quelle mindestens 1 Sekunde neuer ist (letzter
# kopiermt-Parameter). Läuft nur auf linux1 (Kommentar: "muss hier nicht
# aufgerufen werden, da er von linux1 aus kopiert" - für andere Rechner
# ist dieses Skript nicht vorgesehen). Aufruf: buwser.sh
# [bugem.sh-Parameter, u.a. -e].
MUPR=$(readlink -f $0); # Mutterprogramm
. ${MUPR%/*}/bul1.sh # LINEINS=linux1, buhost festlegen
[ "$buhost"/ = "$LINEINS"/ ]&&ZL=||QL=$LINEINS;
QL=;
ZL=;
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
/root/bin/mountwser.sh
# muss hier nicht aufgerufen werden, da er von linux1 aus kopiert
for uvz in tmexport indamed; do
	kopiermt /mnt/wser/$uvz /DATA/wser/ "" "" "" "" 1
done;
