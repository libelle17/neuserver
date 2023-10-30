#!/bin/dash
# prüfe die Dateien nochmal nach
gruen="\033[0;32m"
blau="\033[1;34m";
dblau="\033[0;34;1;47m";
rot="\033[1;31m";
lila="\033[1;35m";
reset="\033[0m";
# Verzeichnis für Kopien der nicht Gefundenen
VzKp=/DATA/Patientendokumente/ohneImportNachweis
# Liste mit allen zu pruefenden Dateien
liste=/DATA/Patientendokumente/eingelesen/dateiliste2_$(date +%Y%d%m_%H%M%S).txt
# Verzeichnis zum Suchen
VzZS=/DATA/turbomed/Dokumente
# Protokolldatei der doch noch Gefundenen
PrtDt="/DATA/Patientendokumente/Doch_gefundene_Importe_$Jahr_"$(date +%y%m%d_%H%M%S)".txt"
nr=0
fnr=0
verb=
find $VzKp -type f > "$liste"
printf "\r$blau%d$reset zu untersuchende Dateien gefunden, bearbeite sie ...\n" $(wc -l "$liste"|cut -f1 -d' ')
# lese die $liste
while read -r file; do
    nr=$(expr $nr + 1);            #    let nr=$nr+1 (geht nur in bash)
    [ $verb ]&&printf "$nr: $blau$file$reset\n"
# falls Dateiname ein Leerzeichen am Schluss enthält
#     Größe der Datei
    bn=$(basename "$file");
    dn=$(dirname "$file");
    sz=$(find "$dn" -regextype sed -regex ".*/$bn *" -exec stat -c%s {} \;)
# falls Dateiname ein Leerzeichen am Schluss enthält
#     Änderungsdatum der Datei
    MT=$(find "$dn" -regextype sed -regex ".*/$bn *" -exec stat -c%Y {} \;)
    MTme=$(expr $MT - 172800);
    MTpt=$(expr $MT + 172800);       #      let MTme=$MT-1 MTpt=$MT+86400;
#     Dateien mit dieser Größe und ungefähr diesem Änderungdatum finden
    TBef="find $VzZS -type f -size ${sz}c -newermt @$MTme -not -newermt @$MTpt -iname \""$init"*\""
    [ $verb ]&&printf "${lila}TBef: $rot$TBef$reset\n";
    TName=$(eval $TBef|tr ' \n' '| ')
    if [ "$TName" ];then 
     for zeile in $TName; do # while read -r zeile; do
       zeile=$(echo "$zeile"|tr "|" " "|tr '`' "'"|sed "s/'/\\\\'/g")
       DNBef="mariadb --defaults-extra-file=~/.mysqlpwd quelle -s -e\"SELECT Name FROM briefe WHERE Pfad=REPLACE(REPLACE('"$zeile"','/DATA/turbomed','$/TurboMed'),'/','\\\\\\\\') GROUP BY Pfad\""
       DName=$(eval $DNBef)
       [ $verb ]&&printf " nach Größe+Datum: $lila$zeile$reset\n DNBef: $blau$DNBef$reset\n DName: $blau$DName$reset\n";
       [ "$DName" ]&&{ 
        fnr=$(expr $fnr + 1);  
        [ $fnr = 1 ]&&{ 
          printf "Liste der doch noch gefundenen Dokumente: $blau$PrtDt\ndoch gefunden:$reset\n"
          printf "Doch noch in den Turbomed-Karteikarten gefundene Dokumente aus $VzKp:\n" >> $PrtDt; 
        }
        printf "%4b: %s\n" $fnr "$(basename "$file"|sed "s/'/\\\\'/g")" >> $PrtDt;
        printf "${blau}%4b: $rot$file$reset\n" $fnr; 
        printf "     DName: $DName\n";
        printf "     zeile: $zeile\n";
        [ $verb ]&&printf "     TBef : $TBef\n";
        [ $verb ]&&printf "     DNBef: $DNBef\n";
        rm "$file";
       } # break
     done # < <(echo "$TName");
    fi;
done < "$liste";
 
