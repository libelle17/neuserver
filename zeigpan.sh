#!/bin/bash
# zeigt alle PraxisDB-Inhalte an
blau="\033[1;34m";
gruen="\033[1;32m";
dblau="\033[0;34;1;47m";
rot="\033[1;31m";
reset="\033[0m";

# $1 = Befehl, $2 = Farbe, $3=obdirekt (ohne Result, bei Befehlen z.B. wie "... && Aktv=1" oder "sh ...")
# in dem Befehl sollen zur Uebergabe erst die \ durch \\ ersetzt werden, dann die $ durch \$ und die " durch \", dann der Befehl von " eingerahmt
ausf() {
	[ "$verb" -o "$2" ]&&{ anzeige=$(echo "$2$1$reset\n"|sed 's/%/%%/'); printf "$anzeige";}; # escape für %, soll kein printf-specifier sein
  if test "$3"/ = direkt/; then
    "$1";
  elif test "$3"; then 
    eval "$1"; 
  else 
    resu=$(eval "$1"); 
  fi;
  ret=$?;
  [ "$verb" ]&&{
    printf "ret: $blau$ret$reset"
    [ "$3" ]||printf ", resu: \"\n$blau$resu$reset\"";
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
hosthier=$(hostname); hosthier=${hosthier%%.*};
echo hosthier: $hosthier
for p in 1 0 7; do
  case $hosthier in *$p*)tsh="sh -c";;*)tsh="ssh linux$p";;esac;
  v=$ot/$pr; 
  ausf "$tsh '[ -d $v ]'" "" ja; [ $ret/ != 0/ ]&&v=$v-res; 
  printf "p: $blau$p$reset v: $blau$v$reset\n"
  altverb=$verb;
  verb=1;
  ausf "$tsh 'ls -l $v/objects.*'" $blau
  verb=$altverb;
done;


MUPR=$(readlink -f $0); # Mutterprogramm
. ${MUPR%/*}/bul1.sh # LINEINS=linux1, buhost festlegen
for wirt in linux1 linux0 linux7; do
. ${MUPR%/*}/virtnamen.sh # legt aus $wirt fest: $gpc, $gast, $tush
 cifs=/mnt/$gpc/turbomed;
 printf "cifs: $gruen$cifs$reset\n";
 if mountpoint -q $cifs; then
   altverb=$verb;
   verb=1;
   ausf "ls -l $cifs/$pr/objects.*";
   verb=$altverb;
 else
  printf "kein Mountpoint\n";
 fi;
 echo tush: $tush, gpc: $gpc, gast: $gast
 altverb=$verb;
 verb=1;
 ausf "ssh administrator@$gpc dir 'c:\\Turbomed\\PraxisDB\\objects.*'" $dblau;
# ssh administrator@$gpc dir 'c:\Turbomed\PraxisDB';
 verb=$altverb;
done;
