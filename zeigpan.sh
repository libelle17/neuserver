#!/bin/bash
blau="\033[1;34m";
dblau="\033[0;34;1;47m";
rot="\033[1;31m";
reset="\033[0m";

# $1 = Befehl, $2 = Farbe, $3=obdirekt (ohne Result, bei Befehlen z.B. wie "... && Aktv=1" oder "sh ...")
# in dem Befehl sollen zur Uebergabe erst die \ durch \\ ersetzt werden, dann die $ durch \$ und die " durch \", dann der Befehl von " eingerahmt
ausf() {
	[ "$verb" -o "$2" ]&&{ anzeige=$(echo "$2$1$reset\n"|sed 's/%/%%/'); printf "$anzeige";}; # escape für %, soll kein printf-specifier sein
	if test "$3"; then 
    eval "$1"; 
  else 
    resu=$(eval "$1"); 
  fi;
  ret=$?;
  [ "$verb" ]&&{
    printf "ret: $blau$ret$reset"
    [ "$3" ]||printf ", resu: \"$blau$resu$reset\"";
    printf "\n";
  }
} # ausf

# Befehlszeilenparameter auswerten
commandlhier() {
	while [ $# -gt 0 ]; do
   case "$1" in 
     -*|/*)
      para=${1#[-/]};
      case $para in
        v|-verbose) verb=1;;
      esac;;
   esac;
   shift;
	done;
	if [ "$verb" ]; then
    printf "Parameter: $blau-v$reset => gesprächig\n";
	fi;
} # commandlhier

commandlhier "$@"; # alle Befehlszeilenparameter übergeben, ZL aus commandline festlegen
ot=/opt/turbomed;
pr=PraxisDB;
for p in "" 0 7; do
  case $p in "")tsh="sh -c";;*)tsh="ssh linux$p";;esac;
  v=$ot/$pr; 
  ausf "$tsh '[ -d $v ]'"; [ $ret/ != 0/ ]&&v=$v-res;
  printf "p: $blau$p$reset v: $blau$v$reset\n"
  altverb=$verb;
  verb=1;
  ausf "$tsh 'ls -l $v'";
  verb=$altverb;
done;


MUPR=$(readlink -f $0); # Mutterprogramm
. ${MUPR%/*}/bul1.sh # LINEINS=linux1, buhost festlegen
for wirt in 1 0 7; do
. ${MUPR%/*}/virtnamen.sh # legt aus $wirt fest: $gpc, $gast sowie aus $buhost: tush
 cifs=/mnt/$gpc/turbomed;
 printf "cifs: $blau$cifs$reset\n";
 if mountpoint -q $cifs; then
   ls -l $cifs/$pr;
 else
  printf "kein Mountpoint\n";
 fi;
done;
