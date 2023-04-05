#!/bin/bash
abk=(wd gs tk)
sus=("^Dr.*D.*Wagner" "^G.*Schade" "^Dr.*Kothny" "^Dr.*A.*Hammerschmidt")
blau="\033[1;34m";
dblau="\033[0;34;1;47m";
rot="\033[1;31m";
reset="\033[0m";
# Befehlszeilenparameter auswerten
commandline() {
  verb=0;
	while [ $# -gt 0 ]; do
   case "$1" in 
     -*|/*)
      para=${1#[-/]};
      case $para in
        v|-verbose) if [ $verb/ = 0/ ]; then verb=1; else verb=2; fi;;
      esac;;
   esac;
   shift;
	done;
	if [ "$verb" ]; then
    printf "Parameter: $blau-v$reset => gesprächig\n";
	fi;
} # commandline

# hier geht's los
commandline "$@"; # alle Befehlszeilenparameter übergeben
for jahr in $(seq 2004 1 2050); do
  [ "$verb" ]&&echo $jahr
  for D in $(mysql --defaults-file=~/.mysqlpwd -B -e"SELECT  CONCAT(ID,'<$>',REPLACE(REPLACE(REPLACE(REPLACE(pfad,'\$','/DATA'),'\\\\TurboMed\\\\','/turbomed/'),'\\\\','/'),' ','°³²°'),'<$>',DATE(quelldatum),'<$>',REPLACE(name,' ','°³²°')) '' FROM quelle.briefe WHERE (autor='' OR ISNULL(autor)) AND (YEAR(quelldatum)<=$jahr or ($jahr=2050)) AND pfad LIKE '%\.pdf'"); do
# for D in "128072<$>/DATA/turbomed/Dokumente/Sonstiges/202106/Strasser19370517-54583-8FFF40CC-DB1F-48a0-BBFD-F323A6AC5DC9.pdf"; do
    arr=(${D//<$>/ });
    arr[1]=${arr[1]//°³²°/ };
    arr[3]=${arr[3]//°³²°/ };
    if stat "${arr[1]}" >/dev/null 2>&1; then
      autor=-;
      for indx in $(seq 0 1 ${#abk}); do
        if [ $indx = ${#sus} ]; then break; fi;
        [ "$verb"/ = 2/ ]&&echo $indx: ${sus[$indx]} # zu ausführlich
        if pdftotext "${arr[1]}" - 2>/dev/null|grep "${sus[$indx]}" >/dev/null; then
          autor=${abk[$indx]};
          break;
        fi;
      done;
      [ "$verb" ]&&printf "$jahr: $blau${arr[0]}$reset ${arr[3]} $blau${arr[2]}$reset: $dblau$autor$reset\n";
    else
     autor='?';
     [ "$verb" ]&&printf "$jahr: $rot${arr[0]} $blau${arr[3]} ${arr[2]}$reset: ${rot}nicht gefunden$reset\n";
    fi;
    mysql --defaults-file=~/.mysqlpwd -B -e"UPDATE quelle.briefe SET autor=\"$autor\" WHERE id=${arr[0]}";
  done; # for D in
done; # for jahr in 
