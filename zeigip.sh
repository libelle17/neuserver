#!/bin/bash
verb=;
blau="\033[1;34m";
lila="\033[1;35m";
dblau="\033[0;34;1;47m";
rot="\033[1;31m";
reset="\033[0m";
dt=zeigip_$(date +"%y%m%d_%H%M").txt

# $1 = Befehl, $2 = Farbe, $3=obdirekt (ohne Result, bei Befehlen z.B. wie "... && Aktv=1" oder "sh ...")
# in dem Befehl sollen zur Uebergabe erst die \ durch \\ ersetzt werden, dann die $ durch \$ und die " durch \", dann der Befehl von " eingerahmt
ausf() {
	[ "$verb" -o "$2" ]&&{ anzeige=$(echo "$2$1$reset"|sed 's/%/%%/'); printf "$anzeige";}; # escape für %, soll kein printf-specifier sein
  if test "$3"/ = direkt/; then
    "$1";
  elif test "$3"; then 
    echo erstens: eval "$1";
    eval "$1"; 
  else 
#    ne=$(echo "$1"|sed 's/\([\]\)/\\\\\1/g;s/\(["]\)/\\\\\1/g'); # neues Eins, alle " und \ noch ein paar Mal escapen; funzt nicht
#    printf "$rot$ne$reset";
    resu=$(eval "$1"); 
  fi;
  ret=$?;
  if [ "$verb" ]; then
    printf " -> ret: $blau$ret$reset";
    if [ "$3" ]; then printf '\n'; else printf ", resu:\n$blau"; echo "$resu"|sed -e '$ a\'; printf "$reset"; fi;
  elif [ "$2" ]; then
    printf "\n";
  fi;
} # ausf

printf "$blau$0$reset [$blau<startip[1]>$reset [$blau<endip[255]>$reset]]\n";
printf "ermittelt mit ${blau}nmap 192.168.178.{<startip>...<endip>}$reset eine Liste der PCs im LAN und schreibt sie in die Ausgabedatei: $blau$dt$reset\n";
rm -f $dt;
case "$1" in ''|*[!0-9]*) startip=1;; *) startip=$1;; esac;
case "$2" in ''|*[!0-9]*) endip=255;; *) endip=$2;; esac;
for i in $(seq $startip 1 $endip); do
  bef="nmap -sP 192.168.178.$i";
  ausf "$bef"
  printf "i: $blau%3s: " $i;

  if echo $resu|grep -q "seems down"; then
    printf " -$reset\r"; 
  else
    resu=$(echo "$resu"|sed -n "2{s/.*report for //;h};4{H;x;s/\n/, /p}");
    printf "$resu$reset\n";
    echo $resu >>$dt;
  fi;
done;
