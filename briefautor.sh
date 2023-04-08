#!/bin/bash
abk=(wd gs tk ah)
sus=("^Dr.*D.*Wagner" "^G.*Schade" "^Dr.*Kothny" "^Dr.*A.*Hammerschmidt")
blau="\033[1;34m";
dblau="\033[0;34;1;47m";
rot="\033[1;31m";
gruen="\033[1;32m";
lila="\033[1;35m";
reset="\033[0m";
verb=0;

# Befehlszeilenparameter auswerten
commandline() {
  verb=0;
	while [ $# -gt 0 ]; do
   case "$1" in 
     -*|/*)
      para=${1#[-/]};
      case $para in
        v|-verbose) verb=$((verb+1));;
      esac;;
   esac;
   shift;
	done;
	if [ $verb -gt 0 ]; then
    printf "Parameter: $blau-v$reset => gesprächig, Tiefe: $verb\n";
	fi;
} # commandline

# hier geht's los
commandline "$@"; # alle Befehlszeilenparameter übergeben
nr=0;
for jahr in $(seq 2004 1 $(date +%Y)); do
  [ $verb -gt 0 ]&&printf "${rot}Jahr: $blau$jahr$reset\n";
  for D in $(mysql --defaults-file=~/.mysqlpwd -B -e"SELECT  CONCAT(ID,'<$>',REPLACE(REPLACE(REPLACE(REPLACE(pfad,'\$','/DATA'),'\\\\TurboMed\\\\','/turbomed/'),'\\\\','/'),' ','°³²°'),'<$>',DATE(quelldatum),'<$>',REPLACE(name,' ','°³²°')) '' FROM quelle.briefe "\
"WHERE (autor='' OR ISNULL(autor) OR false) AND (dokgroe<>-1 OR false) AND "\
"(($jahr=2004 AND YEAR(quelldatum)<$jahr) OR YEAR(quelldatum)=$jahr OR (YEAR(quelldatum)>$jahr AND $jahr="$(date +%Y)")) AND "\
"pfad LIKE '%\.pdf' AND ("\
"(name LIKE 'CGM BMP gedruckt%') OR "\
"(name RLIKE '^[^,]*(Uew|Ü[Ww]) *.{0,12}$') OR "\
"(name RLIKE '[ _-]20[0-9]\{2\}[-_][0-9]\{2\}[-_][0-9]\{2\}.*\.pdf$') OR "\
"(name RLIKE '20[0-9]\{12\}[^0-9]') OR "\
"(name RLIKE '[ _-][0-9]\{2\}[- ][0-9]\{2\}[- ]20[0-9]\{2\}.*\.pdf$') OR "\
"(true AND (quelldatum <19840601)))"); do
# for D in "128072<$>/DATA/turbomed/Dokumente/Sonstiges/202106/Strasser19370517-54583-8FFF40CC-DB1F-48a0-BBFD-F323A6AC5DC9.pdf"; do
    arr=(${D//<$>/ }); # 0: id, 1: Pfad, 2: quelldatum, 3: Name
    arr[1]=${arr[1]//°³²°/ };
    arr[3]=${arr[3]//°³²°/ };
#    [ $verb -gt 0 ]&&printf "$nr: $blau$D$reset\n";
    nr=$((nr+1));
    if true; then
      if stat "${arr[1]}" >/dev/null 2>&1; then
#      [ $verb -ge 2 ]&&printf "${arr[2]}  $gruen${arr[3]}$reset ${arr[1]}\n";
#      if [[ ${arr[3]} =~ "CGM BMP gedruckt.*" ]]; then
        if echo ${arr[3]}|egrep -q "^CGM BMP gedruckt"; then
          [ $verb -ge 2 ]&&printf "%4s(1): ${arr[2]} $blau%60s$reset ${arr[0]} => " $nr "${arr[3]}";
          IFS=$'\n' erga=($(pdftotext ${arr[1]} - |sed -n '/^ausgedruckt von/ {n;s/Dr.med.//;s/^\([^ ]\)/ \1/;s/ \(.\)[^ ]*/\1/g;s/.*/\L&/;p};/^ausgedruckt:\?[^v]/{s/[^:]*://;s/[^ ]* \(.*\)/\1/p;q}'));
          IFS=$' ';
          [ $verb -ge 2 ]&&printf "$lila${erga[1]} ${erga[0]}$reset\n";
          mysql --defaults-file=~/.mysqlpwd -B -e"UPDATE quelle.briefe SET autor=\"${erga[0]}\",quelldatum=STR_TO_DATE(\"${erga[1]}\",\"%d.%c.%Y %H:%i:%S\") WHERE id=${arr[0]}";
  #        mysql --defaults-file=~/.mysqlpwd -B -e"SELECT id,autor,quelldatum FROM quelle.briefe WHERE id=${arr[0]}";
        elif echo ${arr[3]}|egrep -iq "^[^,]*(Uew|ÜW)[ -]*.{0,12}$"; then
          [ $verb -ge 2 ]&&printf "%4s(2): ${arr[2]} $blau%60s$reset ${arr[0]} => " $nr "${arr[3]}";
          printf "$lila$(echo ${arr[3]}|sed 's/.*ÜW[ -]*//gi;s/\(^[0-9-]*\).*/\1/;s/^1/01.01./;s/^2/01.04./;s/^3/01.07./;s/^4/01.10./;s/-//')$reset\n";
          mysql --defaults-file=~/.mysqlpwd -B -e"UPDATE quelle.briefe SET autor=\"-\",quelldatum=STR_TO_DATE(\""$(echo ${arr[3]}|sed 's/.*ÜW[ -]*//gi;s/\(^[0-9-]*\).*/\1/;s/^1/01.01./;s/^2/01.04./;s/^3/01.07./;s/^4/01.10./;s/-//')"\",\"%d.%c.%Y\") WHERE id=${arr[0]}";
        elif echo ${arr[3]}|egrep -iq "[ _-]20[0-9]{2}[-_][0-9]{2}[-_][0-9]{2}.*\.pdf$"; then
          erga=$(echo ${arr[3]}|sed -n "s/^.*[ _-]\(20[0-9]\{2\}[-_][0-9]\{2\}[-_][0-9]\{2\}\).*$/\1/;s/_/-/g;1p");
          [ $verb -ge 2 ]&&printf "%4s(3): ${arr[2]} $blau%60s$reset ${arr[0]} => $lila${erga}$reset\n" $nr "${arr[3]}";
          mysql --defaults-file=~/.mysqlpwd -B -e"UPDATE quelle.briefe SET autor=\"-\",quelldatum=STR_TO_DATE(\""${erga}\"",\"%Y-%c-%d\") WHERE id=${arr[0]}";
        elif echo ${arr[3]}|egrep -q "20[0-9]{12}[^0-9]"; then
          erga=$(echo ${arr[3]}|sed -n "s/^.*\(20[0-9]\{12\}\)[^0-9].*$/\1/;1p");
          [ $verb -ge 2 ]&&printf "%4s(4): ${arr[2]} $blau%60s$reset ${arr[0]} => $lila${erga}$reset\n" $nr "${arr[3]}";
          mysql --defaults-file=~/.mysqlpwd -B -e"UPDATE quelle.briefe SET autor=\"-\",quelldatum=STR_TO_DATE(\""${erga}\"",\"%Y%c%d%H%i%S\") WHERE id=${arr[0]}";
        elif echo ${arr[3]}|egrep -iq "[ _-][0-9]{2}[- ][0-9]{2}[- ]20[0-9]{2}.*\.pdf$"; then
          erga=$(echo ${arr[3]}|sed -n "s/^.*[ _-]\([0-9]\{2\}[-_][0-9]\{2\}[-_]20[0-9]\{2\}\).*$/\1/;s/_/-/g;1p");
          [ $verb -ge 2 ]&&printf "%4s(5): ${arr[2]} $blau%60s$reset ${arr[0]} => $lila${erga}$reset\n" $nr "${arr[3]}";
          mysql --defaults-file=~/.mysqlpwd -B -e"UPDATE quelle.briefe SET autor=\"-\",quelldatum=STR_TO_DATE(\""${erga}\"",\"%d-%c-%Y\") WHERE id=${arr[0]}";
        else
          [ $verb -ge 2 ]&&printf "$nr: ${arr[0]} ${arr[2]} $lila${arr[3]}$reset ${arr[1]}\n";
        fi;
      else
        printf "${arr[0]} $blau${arr[3]}$reset ${arr[1]} ${rot}nicht gefunden!$reset\n";
        mysql --defaults-file=~/.mysqlpwd -B -e"UPDATE quelle.briefe SET dokgroe=-1 WHERE id=${arr[0]}";
      fi;
    else
      if stat "${arr[1]}" >/dev/null 2>&1; then
        [ $verb -gt 1 ]&&printf "$blau${arr[1]}$reset\n";
        autor=-;
        for indx in $(seq 0 1 ${#abk}); do
          if [ $indx = ${#sus} ]; then break; fi;
          [ $verb -ge 2 ]&&echo $indx: ${sus[$indx]} # zu ausführlich
          if pdftotext "${arr[1]}" - 2>/dev/null|grep "${sus[$indx]}" >/dev/null; then
            autor=${abk[$indx]};
            [ $verb -ge 2 ]&&printf "  ${dblau}Autor: $blau$autor$reset\n";
            break;
          fi;
        done;
        [ $verb -gt 0 ]&&printf "$jahr: $blau${arr[0]}$reset ${arr[3]} $blau${arr[2]}$reset: $dblau$autor$reset\n";
      else
       [ $verb -gt 1 ]&&printf "$rot${arr[1]}$reset\n";
       autor='?';
       [ $verb -gt 0 ]&&printf "$jahr: $rot${arr[0]} $blau${arr[3]} ${arr[2]}$reset: ${rot}nicht gefunden$reset\n";
      fi;
      mysql --defaults-file=~/.mysqlpwd -B -e"UPDATE quelle.briefe SET autor=\"$autor\" WHERE id=${arr[0]}";
    fi;
  done; # for D in
done; # for jahr in 
echo Schluss

