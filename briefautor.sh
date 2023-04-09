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
# "b.pfad rlike 'Burghardt19500327-62789-771CE407-6166-441b-96DD-E03F473E29EC' and "\

for jahr in $(seq 2004 1 $(date +%Y)); do
  #
# "(b.name RLIKE '^[^,]*(Uew|Ü[Ww]) *.{0,12}$') OR "\
# "(b.name RLIKE '[ _-]20[0-9]\{2\}[-_][0-9]\{2\}[-_][0-9]\{2\}.*\.pdf$') OR "\
# "(b.name RLIKE '20[0-9]\{12\}[^0-9]') OR "\
# "(b.name RLIKE '[ _-][0-9]\{2\}[- ][0-9]\{2\}[- ]20[0-9]\{2\}.*\.pdf$') OR "\
# "(b.name LIKE 'GDT Import Datei%') OR "\
# "(b.name LIKE '%ertifikat%') OR "\

  [ $verb -gt 0 ]&&printf "${rot}Jahr: $blau$jahr$reset\n";
  sql="SELECT  CONCAT(b.ID,'<$>',REPLACE(REPLACE(REPLACE(REPLACE(b.pfad,'\$','/DATA'),'\\\\TurboMed\\\\','/turbomed/'),'\\\\','/'),' ','°³²°'),'<$>',DATE(b.quelldatum),'<$>',REPLACE(b.name,' ','°³²°'),'<$>',COALESCE(bq.id,0)) '' "\
"FROM quelle.briefe b "\
"LEFT JOIN quelle.briefe bq ON bq.pat_id=b.pat_id AND bq.name IN (REPLACE(b.name,'.pdf','.doc'),REPLACE(b.name,'.pdf','.docx')) "\
"WHERE (true OR b.autor='') AND (true OR b.quelldatum<19840601) AND (false OR b.dokgroe<>-1) AND "\
"(($jahr=2004 AND YEAR(b.quelldatum)<$jahr) OR YEAR(b.quelldatum)=$jahr OR (YEAR(b.quelldatum)>$jahr AND $jahr=\"$(date +%Y)\")) AND "\
"b.pfad LIKE '%\.pdf' AND ("\
"(b.name LIKE 'CGM BMP gedruckt%') OR "\
"(false AND (false OR b.quelldatum <19840601)))";
  [ $verb -ge 3 ]&&printf "$blau$(echo $sql|sed 's/\\/\\\\/g;s/%/%%/g')$reset\n";

  mysql --defaults-file=~/.mysqlpwd -B -e"$sql"|while read D; do
   if [ "$D" ]; then
    [ $verb -ge 3 ]&&printf "${rot}D (${#D})$reset: $D\n";
# for D in "128072<$>/DATA/turbomed/Dokumente/Sonstiges/202106/Strasser19370517-54583-8FFF40CC-DB1F-48a0-BBFD-F323A6AC5DC9.pdf"; do
    arr=(${D//<$>/ }); # 0: id, 1: Pfad, 2: quelldatum, 3: Name 4: bq.id
    arr[1]=${arr[1]//°³²°/ };
    arr[3]=${arr[3]//°³²°/ };
    [ $verb -ge 3 ]&&printf "$nr: $blau$D$reset\n";
    nr=$((nr+1));
    if true; then
      if stat "${arr[1]}" >/dev/null 2>&1; then
#      [ $verb -ge 2 ]&&printf "${arr[2]}  $gruen${arr[3]}$reset ${arr[1]}\n";
#      if [[ ${arr[3]} =~ "CGM BMP gedruckt.*" ]]; then
        if echo ${arr[3]}|egrep -q "^CGM BMP gedruckt"; then
          [ $verb -ge 2 ]&&printf "%4s(1): ${arr[2]} $blau%60s$reset ${arr[0]} => " $nr "${arr[3]}";
          IFS=$'\n' erga=($(pdftotext ${arr[1]} - |sed -n '/^ausgedruckt von/ {n;s/Dr.med.//;s/^\([^ ]\)/ \1/;s/ \(.\)[^ ]*/\1/g;s/.*/\L&/;p};/^ausgedruckt:\? \?[^v]/{s/^[^: ]*[: ]*//;s/^am:\? //;p;q}'));
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
          mysql --defaults-file=~/.mysqlpwd -B -e"UPDATE quelle.briefe SET autor=\"-\",quelldatum=STR_TO_DATE(\""${erga}"\",\"%Y-%c-%d\") WHERE id=${arr[0]}";
        elif echo ${arr[3]}|egrep -q "20[0-9]{12}[^0-9]"; then
          erga=$(echo ${arr[3]}|sed -n "s/^.*\(20[0-9]\{12\}\)[^0-9].*$/\1/;1p");
          [ $verb -ge 2 ]&&printf "%4s(4): ${arr[2]} $blau%60s$reset ${arr[0]} => $lila${erga}$reset\n" $nr "${arr[3]}";
          mysql --defaults-file=~/.mysqlpwd -B -e"UPDATE quelle.briefe SET autor=\"-\",quelldatum=STR_TO_DATE(\""${erga}"\",\"%Y%c%d%H%i%S\") WHERE id=${arr[0]}";
        elif echo ${arr[3]}|egrep -iq "[ _-][0-9]{2}[- ][0-9]{2}[- ]20[0-9]{2}.*\.pdf$"; then
          erga=$(echo ${arr[3]}|sed -n "s/^.*[ _-]\([0-9]\{2\}[-_][0-9]\{2\}[-_]20[0-9]\{2\}\).*$/\1/;s/_/-/g;1p");
          [ $verb -ge 2 ]&&printf "%4s(5): ${arr[2]} $blau%60s$reset ${arr[0]} => $lila${erga}$reset\n" $nr "${arr[3]}";
          monat=$(echo $erga|sed "s/[0-9]\{2\}[-_]\([0-9]\{2\}\).*$/\1/");
          [ $monat -gt 12 ]&&FS="%c-%d-%Y"||FS="%d-%c-%Y";
          mysql --defaults-file=~/.mysqlpwd -B -e"UPDATE quelle.briefe SET autor=\"-\",quelldatum=STR_TO_DATE(\""${erga}"\",\""$FS"\") WHERE id=${arr[0]}";
        elif echo ${arr[3]}|egrep -q "^GDT Import Datei"; then
          [ $verb -ge 2 ]&&printf "%4s(6): ${arr[2]} $blau%60s$reset ${arr[0]} => " $nr "${arr[3]}";
          erga=$(pdftotext "${arr[1]}" - |sed -n '/^Datum:/{s/^Datum: *//;p;q}');
          [ $verb -ge 2 ]&&printf "$lila${erga}$reset\n";
          mysql --defaults-file=~/.mysqlpwd -B -e"UPDATE quelle.briefe SET autor=\"-\",quelldatum=STR_TO_DATE(\"$erga\",\"%d.%c.%Y %H:%i\") WHERE id=${arr[0]}";
        else
          [ $verb -ge 2 ]&&printf "$nr: ${arr[0]} ${arr[2]} $lila${arr[3]}$reset ${arr[1]}\n";
        fi;
      else
        printf "${arr[0]} $blau${arr[3]}$reset ${arr[1]} ${lila}nicht gefunden!$reset\n";
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
   fi; # if [ "$D" ]
  done; # for D in
done; # for jahr in 
echo Schluss

