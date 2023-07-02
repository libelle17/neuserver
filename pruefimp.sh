#!/bin/dash
gruen="\033[0;32m"
blau="\033[1;34m";
dblau="\033[0;34;1;47m";
rot="\033[1;31m";
lila="\033[1;35m";
reset="\033[0m";
# Jahr=2023
D=/DATA/Patientendokumente/eingelesen/$Jahr
liste=/DATA/Patientendokumente/eingelesen/dateiliste.txt
Z=/DATA/turbomed/Dokumente
Zl=/DATA/Patientendokumente/ohneImportNachweis
AD="/DATA/Patientendokumente/Nicht_gefundene_Importe_$Jahr_"$(date +%y%m%d_%H%M%S)".txt"
nr=0
fnr=0
verb=
printf "suche ..."
find $D -mindepth 1 -maxdepth 3 -newermt 20091231 -type f -not -iregex '.*\(abrechnungssem\|azubi\|anforderung\|bei geräten\|blankoform\|dmp-daten\|diabetes\(tag\|mittel\)\|dokumentation.*htm\|einladung\|experten forum\|fortbildung\|haus\(ärzteverb\|arztvertr\)\|patientenbefrag\|pipettieren\|qualitätskrit\|schweigepflichts+entbindung\|verbandsstoffe\|vhk an\)[^/]*$\|.*\.wav\|.*/\(pict\|img\).*jpg\|plan .*\|.*/[0-9. ()]*.\.\(tif\|jpg\)\|.*/\(192.168\|7komma7\|abrechnung\|acots\|act\(os\|rapid\)\|ada \|adipositas\|advan[tz]ia\|afghanistan\|aida-studie\|äkd\|akag\|aktuell\|amd phenom\|amper\|anfrage\|angebot\|anleit\|anmeld\|antrag\|antwort\|aok \|apo-bank\|approbat\|artikel\|ärzt\|auf\(trag\|zug\)\|aus\(geschrieben\|richt\|stehen\)\|autofax\|avoid\|avp\|axa\|b2b\|bad heilbrunn\|bahn\|barmenia\|base \|basin\|bay\(\.\|eris\)\|befr\(agu\|eiu\)\|behand\|begleit\|berlin\( ak\|sulin\)\|brmitschnitt\|canon\|dmp\|blahusch\|easd\|ekf \|empfohlen\|erinnerung\|erklärung\|euromed\|europe\|exenatide\|fachverband\|fahrrad\|falsche\|fehlende überw\|ffh \|filelist\|finanztest\|force 3d\|fortknox\|gkm \|gkv \|gloxo\|glucosepent\|goä\|hävg\|ing-\|motivat\|patmit\|predictive\|programme\|prüfung\|pumpengutachten\|patient\|patmit\|schulungs\|sidebar\|unbekannt\)[^/]*$' \( -not -iregex '.*an fax.*' -o -iregex '.*arztbrief.*' \) -name '*'|sort > "$liste" 
printf "\r$blau%d$reset zu untersuchende Dateien in $blau$D$reset gefunden, bearbeite sie ...\n" $(wc -l "$liste"|cut -f1 -d' ')
while read -r file; do
    gefu=; # deshalb dürfen nachfolgend keine subshells verwendet werden
    TBef=;
    DNBef=;
    nr=$(expr $nr + 1);            #    let nr=$nr+1 (geht nur in bash)
#    [ $nr = 21 ]&&exit;
    [ $verb ]&&printf "$nr: $blau$file$reset\n"
    DBBef="mysql --defaults-extra-file=~/.mysqlpwd quelle -s -e\"SELECT REPLACE(REPLACE(Pfad,'\\\\\\\\','/'),'$/TurboMed','/DATA/turbomed') FROM briefe WHERE name like '$(basename "$file"|sed 's/`/%%/g'|sed "s/'/\\\\'/g")' GROUP BY Pfad\""
    TName=$(eval "$DBBef")
    if [ "$TName" ];then 
#    mysql --defaults-extra-file=~/.mysqlpwd -s quelle -e"select pfad from briefe where pfad like '%|%'" => 0 Ergebnisse
     TName=$(echo "$TName"|tr ' \n' '| ')
#     echo "$TName"|hexdump -C
     for zeile in $TName; do            #     while read -r zeile; do
      zeile=$(echo "$zeile"|tr '|' ' ')
      [ $verb ]&&printf " in DB: $reset$zeile$blau existiert"
      [ -f "$zeile" ]&&{ [ $verb ]&&printf "$reset\n";gefu=ja;}||{ [ $verb ]&&printf "$rot nicht$reset\n";}
     done;          #   done < <(echo "$TName");
    else
     init=$(basename "$file"|cut -d' ' -f1|sed "s/[-,.;_:]*$//;s/^\(.\{3\}\).*/\1/"|tr '`' "?")
     [ $verb ]&&echo init: $init
#      stat "$file";
      sz=$(stat -c%s "$file")
      MT=$(stat -c%Y "$file")
      MTme=$(expr $MT - 1);
      MTpt=$(expr $MT + 86400);       #      let MTme=$MT-1 MTpt=$MT+86400;
#      echo $init, $sz, $MTme, $MTpt
      TBef="find $Z -size ${sz}c -newermt @$MTme -not -newermt @$MTpt -iname \""$init"*\""
      [ $verb ]&&printf "${lila}TBef: $rot$TBef$reset\n";
#     find /DATA/turbomed/Dokumente -name '*|*' => 0 Ergebnisse
      TName=$(eval $TBef|tr ' \n' '| ')
      if [ "$TName" ];then 
       for zeile in $TName; do # while read -r zeile; do
         zeile=$(echo "$zeile"|tr "|" " "|tr '`' "'"|sed "s/'/\\\\'/g")
         DNBef="mysql --defaults-extra-file=~/.mysqlpwd quelle -s -e\"SELECT Name FROM briefe WHERE Pfad=REPLACE(REPLACE('"$zeile"','/DATA/turbomed','$/TurboMed'),'/','\\\\\\\\') GROUP BY Pfad\""
         DName=$(eval $DNBef)
         [ $verb ]&&printf " nach Größe+Datum: $lila$zeile$reset\n DNBef: $blau$DNBef$reset\n DName: $blau$DName$reset\n";
         [ "$DName" ]&&{ gefu=ja;} # break
       done # < <(echo "$TName");
      fi;
    fi;
    [ $gefu ]||{ 
      fnr=$(expr $fnr + 1);  
      [ $fnr = 1 ]&&{ 
        printf "Liste der in den Karteikarten fehlenden Dokumente: $blau$AD\nnicht gefunden:$reset\n"
        printf "Nicht in den Turbomed-Karteikarten gefundene Dokumente aus $D:\n" >> $AD; 
        mkdir -p "$Zl"
        for d in "$AD" "$Zl"; do 
          chown sturm:praxis "$d"
          chmod 774 "$d"
        done;
      }
      printf "%4b: %s\n" $fnr "$(basename "$file"|sed "s/'/\\\\'/g")" >> $AD;
      printf "${blau}%4b: $rot$file$reset\n" $fnr; 
      printf "     DBBef: $DBBef\n";
      printf "     TBef : $TBef\n";
      printf "     DNBef: $DNBef\n";
      cp -a "$file" "$Zl";
    }
done < "$liste";
