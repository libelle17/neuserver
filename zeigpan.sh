#!/bin/bash
# zeigt alle PraxisDB-Inhalte an
blau="\033[1;34m";
gruen="\033[1;32m";
dblau="\033[0;34;1;47m";
rot="\033[1;31m";
lila="\033[1;35m";
reset="\033[0m";

# $1 = Befehl, $2 = Farbe, $3=obdirekt (ohne Result, bei Befehlen z.B. wie "... && Aktv=1" oder "sh ..."), $4=obstumm
# in dem Befehl sollen zur Uebergabe erst die \ durch \\ ersetzt werden, dann die $ durch \$ und die " durch \", dann der Befehl von " eingerahmt
ausf() {
	[ "$verb" -o "$2" ]&&{ anzeige=$(echo "$2$1$reset"|sed 's/%/%%/'); printf "$anzeige";}; # escape für %, soll kein printf-specifier sein
  if test "$3"/ = direkt/; then
    "$1";
  elif test "$3"; then 
    eval "$1"; 
  else 
    resu=$(eval "$1"); 
  fi;
  ret=$?;
  [ "$verb" ]&&{
    printf " -> ret: $blau$ret$reset"
    [ "$3" ]||printf ", resu: \n$blau$resu$reset";
    printf "\n";
  }
} # ausf

# Befehlszeilenparameter auswerten
commandlhier() {
  verb=;
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
pr=PraxisDB;
echo "Virtuelle Windows-Server:"
MUPR=$(readlink -f $0); # Mutterprogramm
. ${MUPR%/*}/bul1.sh # LINEINS=linux1, buhost festlegen
for nr in 1 0 3 7 8; do
  wirt=linux$nr;
  if ping -c1 -W1 $wirt >/dev/null 2>&1; then
. ${MUPR%/*}/virtnamen.sh # legt aus $wirt fest: $gpc, $gast, $tush
   cifs=/mnt/$gpc/turbomed;
   printf "$lila$gpc$reset, wirt: $lila$wirt$reset: " # , cifs: $lila$cifs$reset:\n";
   for vers in 3.11 3.11 3.02 3.02 3.0 3.0 2.1 2.1 2.0 2.0 1.0 1.0; do
     if ! mountpoint -q $cifs; then
       printf "\n";
       ausf "mount //$gpc/Turbomed $cifs -t cifs -o nofail,vers=$vers,credentials=/home/schade/.wincredentials" $blau
       printf "\n";
     else
#       printf " ${blau}$cifs$reset gemountet!\n"
       break;
     fi;
   done;
   if mountpoint -q $cifs; then
     altverb=$verb;
     verb=1;
     ausf "ls -l $cifs/$pr/objects.*" $dblau;
     verb=$altverb;
   else
    printf "kein Mountpoint\n";
   fi;
   [ $verb ]&&printf "tush: $blau$tush$reset, gpc: $blau$gpc$reset, gast: $blau$gast$reset\n";
   altverb=$verb;
   verb=1;
   printf " ";
   ausf "ssh administrator@$gpc dir 'c:\\Turbomed\\PraxisDB\\objects.*|findstr objects'" $schwarz;
  # ssh administrator@$gpc dir 'c:\Turbomed\PraxisDB';
   verb=$altverb;
 fi;
done;

printf "\nLinux-Server:\n"
ot=/opt/turbomed;
hosthier=$(hostname); hosthier=${hosthier%%.*};
[ $verb ]&&printf "hosthier: $blau$hosthier$reset\n";
for nr in 1 0 3 7 8; do
  printf "${lila}linux$nr$reset: ";
  if ping -c1 -W1 linux$nr >/dev/null; then
    case $hosthier in *$nr*)tsh="sh -c";;*)tsh="ssh linux$nr";;esac;
    v=$ot/$pr; 
    ausf "$tsh '[ -d $v ]'" "" ja; [ $ret/ != 0/ ]&&v=$v-res; 
    [ $verb ]&&printf "=> Verzeichnis: $blau$v$reset\n"
    altverb=$verb;
    verb=1;
    ausf "$tsh 'ls -l $v/objects.*'" $schwarz
    verb=$altverb;
  else
    printf " nicht erreichbar (mit ping -cl -W1 linux$nr)\n";
  fi;
done;

