#!/bin/bash
# mountwser.sh - mountet die CIFS-Freigaben \\WSER\INDAMED und
# \\WSER\TMExport nach /mnt/wser/indamed bzw. /mnt/wser/tmexport, mit den
# Zugangsdaten aus $crw (/home/schade/.wsercredentials). Da die SMB-
# Protokollversion des Zielservers unbekannt ist, wird pro Freigabe
# absteigend über eine Liste von SMB-Versionen (3.11 über 3.02/3.0/2.1/2.0
# bis 1.0, je zweimal versucht) probiert, bis das Mounten klappt oder schon
# gemountet ist. Inhaltlich nahezu identisch zu mountvirt.sh (einziger
# Unterschied: ein Kommentar, von welchem Reserve-Host $cre vor Gebrauch per
# scp geholt werden muss - hier linux1 statt linux1ur). Aufruf ohne
# Parameter.
# zur Funktionsfaehigkeit auf den Reservesystemen: scp -p linux1:/home/schade/.wincredentials /home/schade/
blau="\033[1;34m";
dblau="\033[0;34;1;47m";
rot="\033[1;31m";
reset="\033[0m";
MUPR=$(readlink -f $0); # Mutterprogramm

# Befehlszeilenparameter auswerten
commandline() {
  verb=;
  oballe=;
	while [ $# -gt 0 ]; do
    para=${1#[-/]};
		case $para in
      a) oballe=a;;
      v) verb=v;;
		esac;
		[ "$verb" = 1 ]&&printf "Parameter: $blau-v$reset => gesprächig\n";
		shift;
	done;
	if [ "$verb" ]; then
		printf "oballe: $blau$oballe$reset\n";
	fi;
} # commandline

# $1 = Befehl, $2 = Farbe, $3=obdirekt (ohne Result, bei Befehlen z.B. wie "... && Aktv=1" oder "sh ...")
# in dem Befehl sollen zur Uebergabe erst die \ durch \\ ersetzt werden, dann die $ durch \$ und die " durch \", dann der Befehl von " eingerahmt
ausf() {
	[ "$verb" -o "$2" ]&&{ anzeige=$(echo "$2$1$reset\n"|sed 's/%/%%/'); printf "$dblau$anzeige$reset";}; # escape für %, soll kein printf-specifier sein
	if test "$3"; then 
    eval "$1"; 
  else 
    resu=$(eval "$1"); 
  fi;
  ret=$?;
  [ "$verb" ]&&{
    printf "ret: $blau$ret$reset"
    [ "$3" ]||printf ", Ergebmntvirt: \"$blau$resu$reset\"";
    printf "\n";
  }
} # ausf

commandline "$@"; # alle Befehlszeilenparameter übergeben

       for cifs in "\\\\\\\\WSER\\\\INDAMED /mnt/wser/indamed" "\\\\\\\\WSER\\\\TMExport /mnt/wser/tmexport"; do
         for vers in 3.11 3.11 3.02 3.02 3.0 3.0 2.1 2.1 2.0 2.0 1.0 1.0; do
           ret=0;
           if ! mountpoint -q $(echo $cifs|cut -d' ' -f2); then
             ausf "mount $cifs -t cifs -o nofail,vers=$vers,credentials=$crw,iocharset=utf8,file_mode=0777,dir_mode=0777,rw >/dev/null 2>&1" # $blau #  auskommentiert 24.7.22
           else
      #       printf " ${blau}$cifs$reset gemountet!\n"
             break;
           fi;
           if [ $ret/ != 0/ ]; then
             echo mounten von $cifs auf wser mit vers: $vers fehlgeschlagen.
           fi;
         done;
       done;
