#!/bin/bash
abk=(wd gs tk ah)
blau="\033[1;34m";
dblau="\033[0;34;1;47m";
rot="\033[1;31m";
gruen="\033[1;32m";
lila="\033[1;35m";
reset="\033[0m";
verb=0;
nurauflisten=;
autoren=$(sed -n '/Const artSpez\(\xc4rzte\|Berat\|MA\)/{s/.*\xc4//;s/.* "//;s/['\''"]//g;H};${x;s/[\n\r]/,/g;s/,\+/,/g;s/^,//;s/,$//;s/,/|/g;p}' /DATA/eigene\ Dateien/Programmierung/Dateilesen/ZielDBFunktionen.bas);

# Befehlszeilenparameter auswerten
commandline() {
  verb=0;
	while [ $# -gt 0 ]; do
   case "$1" in 
     -*|/*)
      para=${1#[-/]};
      case $para in
        v|-verbose) verb=$((verb+1));;
        l|-list) nurauflisten=1;
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

  [ $verb -gt 0 ]&&printf "${rot}Jahr: $blau$jahr$reset\n";
  sql="SELECT  CONCAT(b.ID,'<$>',REPLACE(REPLACE(REPLACE(REPLACE(b.pfad,'\$','/DATA'),'\\\\TurboMed\\\\','/turbomed/'),'\\\\','/'),' ','°³²°'),'<$>',DATE(b.quelldatum),'<$>',REPLACE(b.name,' ','°³²°'),'<$>',COALESCE(bq.id,0),'<$>',b.autor,'<$>',b.dokgroe) '' "\
"FROM quelle.briefe b "\
"LEFT JOIN quelle.briefe bq ON bq.pat_id=b.pat_id AND bq.name IN (REPLACE(b.name,'.pdf','.doc'),REPLACE(b.name,'.pdf','.docx')) "\
"WHERE (true OR b.autor='') AND (true OR b.quelldatum<19840601) AND (false OR b.autor='' OR b.quelldatum<19840601) AND (true OR b.dokgroe<>-1) AND "\
"(($jahr=2004 AND YEAR(b.quelldatum)<$jahr) OR YEAR(b.quelldatum)=$jahr OR (YEAR(b.quelldatum)>$jahr AND $jahr=\"$(date +%Y)\")) AND "\
"b.pfad LIKE '%\.pdf' AND ("\
"(bq.name IS NOT NULL) OR "\
"(b.name LIKE 'CGM BMP gedruckt%') OR "\
"(LCASE(b.name) RLIKE '^[^,]*(uew|üw) *.{0,12}$') OR "\
"(b.name RLIKE '[ _-]20[0-9]\{2\}[-_][0-9]\{2\}[-_][0-9]\{2\}.*\.pdf$') OR "\
"(b.name RLIKE '20[0-9]\{12\}[^0-9]') OR "\
"(b.name RLIKE '[ _-][0-9]\{2\}[- ][0-9]\{2\}[- ]20[0-9]\{2\}.*\.pdf$') OR "\
"(b.name LIKE 'GDT Import Datei%') OR "\
"(b.name RLIKE '^COVID-19 (Impf|Genesenen)zertifikat') OR "\
"(b.name RLIKE '.* ("$autoren").pdf') OR "\
"(false))";
  [ $verb -ge 3 ]&&printf "$blau$(echo $sql|sed 's/\\/\\\\/g;s/%/%%/g')$reset\n";

  mysql --defaults-file=~/.mysqlpwd -B -e"$sql"|while read D; do
   if [ "$D" ]; then
# for D in "128072<$>/DATA/turbomed/Dokumente/Sonstiges/202106/Strasser19370517-54583-8FFF40CC-DB1F-48a0-BBFD-F323A6AC5DC9.pdf"; do
    arr=(${D//<$>/ }); # 0: id, 1: Pfad, 2: quelldatum, 3: Name, 4: bq.id, 5: Autor, 6: dokgroe
    arr[1]=${arr[1]//°³²°/ };
    arr[3]=${arr[3]//°³²°/ };
    [ $verb -ge 4 ]&&printf "$rot$nr (${#D})$reset: $blau$D$reset\n";
    nr=$((nr+1));
    if [ ! $nurauflisten ]; then
     stat "${arr[1]}" >/dev/null 2>&1 &&dte=1||dte=;
     gefu=;
     if true; then
        # autor und quelldatum zusammen
        if echo ${arr[3]}|egrep -q "^CGM BMP gedruckt"; then    # if [[ ${arr[3]} =~ "CGM BMP gedruckt.*" ]]; then
          gefu=1;
          if [ $dte ]; then
            IFS=$'\n' erga=($(pdftotext ${arr[1]} - |sed -n '/^ausgedruckt von/ {n;s/Dr.med.//;s/^\([^ ]\)/ \1/;s/ \(.\)[^ ]*/\1/g;s/.*/\L&/;p};/^ausgedruckt:\? \?[^v]/{s/^[^: ]*[: ]*//;s/^am:\? //;p;q}'));
            IFS=$' ';
            if [ "${erga[1]:0:10}" != "$(date -d"${arr[2]}" +%d.%m.%Y)" -o "${arr[5]}" != "${erga[0]}" ]; then
             [ $verb -ge 2 ]&&printf "%4s(1): $blau%3s$reset ${arr[2]} $blau%60s$reset ${arr[0]} => $lila${erga[1]} ${erga[0]}$reset\n" $nr "${arr[5]}" "${arr[3]}";
              mysql --defaults-file=~/.mysqlpwd -B -e"UPDATE quelle.briefe SET autor=\"${erga[0]}\",quelldatum=STR_TO_DATE(\"${erga[1]}\",\"%d.%c.%Y %H:%i:%S\") WHERE id=${arr[0]}";
            fi; 
          fi; # if [ $dte ]
        elif echo ${arr[3]}|egrep -q "^COVID-19 (Impf|Genesenen)zertifikat"; then
          gefu=1;
          if [ $dte ]; then
            erga=$(pdftotext ${arr[1]} - 2>/dev/null|sed '/^[0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}$/{x;/1/be;s/^$/1/;x;d;:e;x;q};d');
            if [ "$erga" != "${arr[2]}" -o "${arr[5]}" != - ]; then
              [ $verb -ge 2 ]&&printf "%4s(2): $blau%3s$reset ${arr[2]} $blau%60s$reset ${arr[0]} => $lila${erga}$reset\n" $nr "${arr[5]}" "${arr[3]}";
              [ "$erga" ]&&mysql --defaults-file=~/.mysqlpwd -B -e"UPDATE quelle.briefe SET autor=\"-\",quelldatum=STR_TO_DATE(\"${erga}\",\"%Y-%c-%d\") WHERE id=${arr[0]}";
            fi;
          fi; # if [ $dte ]
        elif echo ${arr[3]}|egrep -q "^GDT Import Datei"; then
          gefu=1;
          if [ $dte ]; then
            erga=$(pdftotext "${arr[1]}" - |sed -n '/^Datum:/{s/^Datum: *//;p;q}');
            if [ "$(date -d"${arr[2]}" +%d.%m.%Y)" != "${erga:0:10}" -o "${arr[5]}" != - ]; then
              [ $verb -ge 2 ]&&printf "%4s(7): $blau%3s$reset ${arr[2]} $blau%60s$reset ${arr[0]} => $lila$erga$reset\n" $nr "${arr[5]}" "${arr[3]}";
              mysql --defaults-file=~/.mysqlpwd -B -e"UPDATE quelle.briefe SET autor=\"-\",quelldatum=STR_TO_DATE(\"$erga\",\"%d.%c.%Y %H:%i\") WHERE id=${arr[0]}";
            fi;
          fi; # if [ $dte ]
        elif [ "${arr[4]}" -ne 0 ]; then # wenn es eine gleichnamige *.doc-Datei gibt
          gefu=1;
          if [ $dte ]; then
            IFS=$'\n' erga=($(pdftotext "${arr[1]}" -|sed -n '/^__/{n;/^[0-9]\{1,2\}\./p};5,${/^Dr.*Kothny/{s/^.*$/tk/;ba};/^G.*Schade/{s/^.*$/gs/;ba};/^Dr.*D.*Wagner/{s/^.*$/wd/;ba};/^Dr.*A.*Hammerschmidt/{s/^.*$/ah/;ba};d;:a;p;q}'));
            IFS=$' ';
            if [ "${erga[0]}" ]; then # wenn autor oder quelldatum enthalten
              [ "${erga[1]}" ]||case "${erga[0]}" in [0-9]*)erga[1]="-";; *)erga[1]=${erga[0]};erga[0]="30.12.1899";; esac;
              erga[0]=$(echo ${erga[0]}|sed 's:^[^/]*/::');
              if [ "$(date -d"${arr[2]}" +%d.%m.%Y)" != "${erga[0]}" -o "${arr[5]}" != "${erga[1]}" ]; then
                [ $verb -ge 2 ]&&{
                  printf "%4s(8): $blau%3s$reset ${arr[2]} $blau%60s$reset ${arr[0]} => $lila${erga[0]} ${erga[1]}$reset\n" $nr "${arr[5]}" "${arr[3]}";
                  [ $verb -ge 4 ]&&printf "${arr[1]}\n";
                }
#                printf "$lila UPDATE quelle.briefe SET autor=\"${erga[1]}\",quelldatum=STR_TO_DATE(\"${erga[0]}\",\"%%d.%%c.%%Y\") WHERE id=${arr[0]}$reset\n";
                mysql --defaults-file=~/.mysqlpwd -B -e"UPDATE quelle.briefe SET autor=\"${erga[1]}\",quelldatum=STR_TO_DATE(\"${erga[0]}\",\"%d.%c.%Y\") WHERE id=${arr[0]}";
              fi;
            fi; # if [ "${erga[0]}" ]; then
          fi; # if [ $dte ]
        else # autor und quelldatum zusammen else
        # quelldatum einzeln        
         if echo ${arr[3]}|egrep -iq "^[^,]*(Uew|ÜW)[ -]*.{0,12}$"; then
          gefu=1;
          erga=$(echo ${arr[3]}|sed 's/.*ÜW[ -]*//gi;s/\(^[0-9-]*\).*/\1/;s/^1/01.01./;s/^2/01.04./;s/^3/01.07./;s/^4/01.10./;s/-//');
          if [ "$(date -d"${arr[2]}" +%d.%m.%y)" != "$erga" ]; then
            [ $verb -ge 2 ]&&printf "%4s(3): $blau%3s$reset ${arr[2]} $blau%60s$reset ${arr[0]} => $lila$erga$reset\n" $nr "${arr[5]}" "${arr[3]}";
            mysql --defaults-file=~/.mysqlpwd -B -e"UPDATE quelle.briefe SET quelldatum=STR_TO_DATE(\""$erga"\",\"%d.%c.%Y\") WHERE id=${arr[0]}";
          fi;
         elif echo ${arr[3]}|egrep -iq "[ _-]20[0-9]{2}[-_][0-9]{2}[-_][0-9]{2}.*\.pdf$"; then
          gefu=1;
          erga=$(echo ${arr[3]}|sed -n "s/^.*[ _-]\(20[0-9]\{2\}[-_][0-9]\{2\}[-_][0-9]\{2\}\).*$/\1/;s/_/-/g;1p");
          if [ "${arr[2]}" != "$erga" ]; then
            [ $verb -ge 2 ]&&printf "%4s(4): $blau%3s$reset ${arr[2]} $blau%60s$reset ${arr[0]} => $lila$erga$reset\n" $nr "${arr[5]}" "${arr[3]}";
            mysql --defaults-file=~/.mysqlpwd -B -e"UPDATE quelle.briefe SET quelldatum=STR_TO_DATE(\""${erga}"\",\"%Y-%c-%d\") WHERE id=${arr[0]}";
          fi;
         elif echo ${arr[3]}|egrep -q "20[0-9]{12}[^0-9]"; then
          gefu=1;
          erga=$(echo ${arr[3]}|sed -n "s/^.*\(20[0-9]\{12\}\)[^0-9].*$/\1/;1p");
          if [ "${arr[2]}" != "$(date -d"${erga:0:8}" +%Y-%m-%d)" ]; then
            [ $verb -ge 2 ]&&printf "%4s(5): $blau%3s$reset ${arr[2]} $blau%60s$reset ${arr[0]} => $lila$erga$reset\n" $nr "${arr[5]}" "${arr[3]}";
            mysql --defaults-file=~/.mysqlpwd -B -e"UPDATE quelle.briefe SET quelldatum=STR_TO_DATE(\""${erga}"\",\"%Y%c%d%H%i%S\") WHERE id=${arr[0]}";
          fi;
         elif echo ${arr[3]}|egrep -iq "[ _-][0-9]{2}[- ][0-9]{2}[- ]20[0-9]{2}.*\.pdf$"; then
          gefu=1;
          erga=$(echo ${arr[3]}|sed -n "s/^.*[ _-]\([0-9]\{2\}[-_][0-9]\{2\}[-_]20[0-9]\{2\}\).*$/\1/;s/_/-/g;1p");
          monat=$(echo $erga|sed "s/[0-9]\{2\}[-_]\([0-9]\{2\}\).*$/\1/");
          [ $monat -gt 12 ]&&FS="%c-%d-%Y"||FS="%d-%c-%Y";
          if [ "$(date -d"${arr[2]}" +"${FS//c/m}")" != $erga ]; then
            [ $verb -ge 2 ]&&printf "%4s(6): $blau%3s$reset ${arr[2]} $blau%60s$reset ${arr[0]} => $lila${erga}$reset\n" $nr "${arr[5]}" "${arr[3]}";
            mysql --defaults-file=~/.mysqlpwd -B -e"UPDATE quelle.briefe SET quelldatum=STR_TO_DATE(\""${erga}"\",\""$FS"\") WHERE id=${arr[0]}";
          fi;
         fi; # quelldatum einzeln 
        # autor einzeln
         if echo ${arr[3]}|egrep -q ".* ("$autoren")\.pdf$"; then
          gefu=1;
          autor="$(echo ${arr[3]}|sed 's/^.* \('"${autoren//|/\\|}"'\)\.pdf$/\1/')";
          if [ $autor != "${arr[5]}" ]; then
            [ $verb -ge 2 ]&&{
              printf "%4s(9): $blau%3s$reset ${arr[2]} $blau%60s$reset ${arr[0]} => $lila$autor$reset\n" $nr "${arr[5]}" "${arr[3]}";
              [ $verb -ge 4 ]&&printf "${arr[1]}\n";
            }
            mysql --defaults-file=~/.mysqlpwd -B -e"UPDATE quelle.briefe SET autor=\"$autor\" WHERE id=${arr[0]}";
          fi;
         fi; # autor einzeln
        fi; # alle fertig
        if [ ! $gefu ]; then
          [ $verb -ge 2 ]&&printf "%4s(-): $blau%3s$reset ${arr[2]} $lila%60s$reset ${arr[0]} $blau${arr[1]}$reset\n" $nr "${arr[5]}" "${arr[3]}";
        fi;
        if [ ! "$dte" -a \( "${arr[6]}" != -1 \) ]; then
          printf "${arr[0]} $blau${arr[3]}$reset ${arr[1]} ${lila}nicht gefunden!$reset\n";
          mysql --defaults-file=~/.mysqlpwd -B -e"UPDATE quelle.briefe SET dokgroe=-1 WHERE id=${arr[0]}";
        fi;
     else # if true; then else
      sus=("^Dr.*D.*Wagner" "^G.*Schade" "^Dr.*Kothny" "^Dr.*A.*Hammerschmidt")
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
     fi; # if true else
    else
      [ $verb -ge 2 ]&&printf "%4s(-): $blau%3s$reset ${arr[2]} $lila%60s$reset ${arr[0]} $blau${arr[1]}$reset\n" $nr "${arr[5]}" "${arr[3]}";
    fi; # if false
   fi; # if [ "$D" ]
  done; # for D in
done; # for jahr in 
echo Schluss

