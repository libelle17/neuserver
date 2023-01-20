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
for nr in 1 0 3 7; do
  wirt=linux$nr;
. ${MUPR%/*}/virtnamen.sh # legt aus $wirt fest: $gpc, $gast, $tush
# ./virtnamen.sh;
## for wirt in "$auswahl"; do
# case $wirt in *0*) gpc=virtwin0; gast=Win10;;
#               *1*) gpc=virtwin;  gast=Win10;;
#               *3*) gpc=virtwin3;  gast=Win10;;
#               *7*) gpc=virtwin7; gast=Win10;;
#               *8*) gpc=virtwin8; gast=Win10;;
# esac;
# case $wirt in $LINEINS)tush="sh -c ";;*)tush="ssh $wirt ";;esac
  HOST=$(hostname);HOST=${HOST%%.*}; # linux1 usw.
  [ linux$nr = $HOST ]&&tush=||tush="ssh $wirt ";
  if ! ping -c1 -W1 $wirt >/dev/null 2>&1; then
    printf "$blau$wirt$reset nicht anpingbar, lasse $blau$gpc$reset aus.\n";
  else
   if [ "$gpc" ]; then
     if ping -c1 -W1 "$gpc" >/dev/null 2>&1; then ok=1; else
      ok=;
      printf "$blau$wirt$reset zwar anpingbar, $blau$gpc$reset aber nicht, versuche ihn zu starten\n";
      ausf "${tush}mountpoint -q /DATA"
      [ $ret != 0 ]&&{ 
        ausf "${tush}mount /DATA"
        [ $ret != 0 ]&&{ 
          ausf "${tush}pkill -9 fsck"
          ausf "${tush}mount /DATA"
        }
      }
      # ausf "ssh linux3 VBoxManage list vms|grep -q \"Win10\""
      # echo $ret
      ausf "${tush}VBoxManage startvm $gast --type headless";      
      for iru in $(seq 1 1 120); do 
        if ping -c1 -W1 "$gpc" >/dev/null 2>&1; then ok=1; break; fi;
      done;
      [ "$ok" ]&&printf "brauchte $blau$iru$reset Durchläufe;\n";
     fi;
     if [ ! "$ok" ]; then
      printf "$blau$gpc$reset immer noch nicht anpingbar, überspringe ihn\n";
     else
       cifs=/amnt/$gpc/turbomed;
       printf "$lila$gpc$reset, wirt: $lila$wirt$reset: " # , cifs: $lila$cifs$reset:\n";
       for vers in 3.11 3.11 3.02 3.02 3.0 3.0 2.1 2.1 2.0 2.0 1.0 1.0; do
         if ! mountpoint -q $cifs; then
           printf "\n";
           ausf "mount //$gpc/Turbomed $cifs -t cifs -o nofail,vers=$vers,credentials=/home/schade/.wincredentials >/dev/null 2>&1 " $blau
           printf "\n";
         else
    #       printf " ${blau}$cifs$reset gemountet!\n"
           break;
         fi;
       done;
     fi; # ping
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
   fi; # if [ "$gpc" ]; then
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
printf "\n${blau}Mysql:$reset\n";
for nr in 1 0 3 7 8; do
  printf "Mysql auf ${blau}linux$nr$reset:\n"
  ssh linux$nr "mysql --defaults-extra-file=~/.mysqlpwd quelle -e\"select (select count(0) from namen) PatZahl, (select max(zeitpunkt) from eintraege) zuletzt\""
done;
