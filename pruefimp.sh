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
find $D -mindepth 1 -maxdepth 3 -newermt 20091231 -type f -not -iregex '.*dmp-daten.*\|.*anforderung.*\|.*schweigepflichts+entbindung.*\|.*vhk an.*\|.*dokumentation.*html\|.*/predictive.*\|.*wav\|.*/pict.*jpg\|plan .*\|.*/programme.*\|.*/prüfung.*\|.*/pumpengutachten.*\|.*/patient[^/]*' \( -not -iregex '.*an fax.*' -o -iregex '.*arztbrief.*' \) -name '*'|sort > "$liste"
printf "\r$blau%d$reset zu untersuchende Dateien in $blau$D$reset gefunden, bearbeite sie ...\n" $(wc -l "$liste"|cut -f1 -d' ')
while read -r file; do
    gefu=; # deshalb dürfen nachfolgend keine subshells verwendet werden
    nr=$(expr $nr + 1);            #    let nr=$nr+1 (geht nur in bash)
#    [ $nr = 21 ]&&exit;
    [ $verb ]&&printf "$nr: $blau$file$reset\n"
    DBBef="mysql --defaults-extra-file=~/.mysqlpwd quelle -s -e\"SELECT REPLACE(REPLACE(Pfad,'\\\\\\\\','/'),'$/TurboMed','/DATA/turbomed') FROM briefe WHERE name='$(basename "$file")' GROUP BY Pfad\""
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
     init=$(basename "$file"|cut -d' ' -f1|sed 's/[-,.;_:]*$//;s/^\(.\{3\}\).*/\1/')
#      stat "$file";
      sz=$(stat -c%s "$file")
      MT=$(stat -c%Y "$file")
      MTme=$(expr $MT - 1);
      MTpt=$(expr $MT + 86400);       #      let MTme=$MT-1 MTpt=$MT+86400;
#      echo $init, $sz, $MTme, $MTpt
      TBef="find $Z -size ${sz}c -newermt @$MTme -not -newermt @$MTpt -name '"$init"*'"
      [ $verb ]&&printf "${lila}TBef: $rot$TBef$reset\n";
#     find /DATA/turbomed/Dokumente -name '*|*' => 0 Ergebnisse
      TName=$(eval $TBef|tr ' \n' '| ')
      if [ "$TName" ];then 
       for zeile in $TName; do # while read -r zeile; do
         zeile=$(echo "$zeile"|tr '|' ' ')
         [ $verb ]&&printf " nach Größe+Datum: $lila$zeile$reset\n"
    DName=$(mysql --defaults-extra-file=~/.mysqlpwd quelle -s -e"SELECT Name FROM briefe WHERE Pfad=REPLACE(REPLACE('$zeile','/DATA/turbomed','$/TurboMed'),'/','\\\\') GROUP BY Pfad")
         [ $verb ]&&printf " DName: $blau$DName$reset\n";
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
      printf "%4b: %s\n" $fnr "$(basename "$file")" >> $AD;
      printf "${blau}%4b: $rot$file$reset\n" $fnr; 
      printf "     $DBBef\n";
      printf "     $TBef\n";
      cp -a "$file" "$Zl";
    }
done < "$liste";
