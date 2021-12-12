#!/bin/bash
# Befehlszeilenparameter auswerten
commandline() {
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
} # commandline

# hier geht's los
abk=(wd gs tk)
sus=("^Dr.*D.*Wagner" "^G.*Schade" "^Dr.*Kothny")
commandline "$@"; # alle Befehlszeilenparameter übergeben
for D in $(mysql --defaults-file=~/.mysqlpwd -B -e"SELECT  concat(ID,'<$>',REPLACE(REPLACE(REPLACE(pfad,'\$','/DATA'),'\\\\TurboMed\\\\','/turbomed/'),'\\\\','/')) '' FROM quelle.briefe where isnull(autor) and pfad like '%%' and pfad like '%\.pdf'"); do
# for D in "128072<$>/DATA/turbomed/Dokumente/Sonstiges/202106/Strasser19370517-54583-8FFF40CC-DB1F-48a0-BBFD-F323A6AC5DC9.pdf"; do
  arr=(${D//<$>/ })
  if stat "${arr[1]}" >/dev/null 2>&1; then
    autor=-;
    for indx in $(seq 0 1 ${#abk}); do
      if [ $indx = ${#sus} ]; then break; fi;
      [ "$verb" ]&&echo $indx: ${sus[$indx]}
      if pdftotext "${arr[1]}" - 2>/dev/null|grep "${sus[$indx]}" >/dev/null; then
        autor=${abk[$indx]};
        [ "$verb" ]&&echo ${arr[0]} ${arr[1]}: ${abk[$indx]} ja;
        break;
      fi;
    done;
    mysql --defaults-file=~/.mysqlpwd -B -e"UPDATE quelle.briefe SET autor=\"$autor\" WHERE id=${arr[0]}";
  else
    [ "$verb" ]&&echo  \"${arr[1]}\" nicht gefunden
  fi;
done;
