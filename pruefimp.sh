#!/bin/dash
gruen="\033[0;32m"
blau="\033[1;34m";
dblau="\033[0;34;1;47m";
rot="\033[1;31m";
lila="\033[1;35m";
# reset="\e[0m";
reset="\033[0m";
Jahr=2023
D=/DATA/Patientendokumente/eingelesen/$Jahr
Z=/DATA/turbomed/Dokumente
Zl=/DATA/Patientendokumente/ohneImportNachweis
AD="/DATA/Patientendokumente/Nicht_gefundene_Importe_$Jahr_"$(date +%y%m%d_%H%M%S)".txt"
echo $AD
nr=0
fnr=0
verb=
find $D -mindepth 1 -maxdepth 1 -name "P*"|sort|while read -r file; do
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
      printf "${lila}TBef: $rot$TBef$reset\n";
#      TName=$(find $Z -size ${sz}c -newermt @$MTme -not -newermt @$MTpt -name "${Name}*" -printf "%p\n")
#     find /DATA/turbomed/Dokumente -name '*|*' => 0 Ergebnisse
      TName=$(eval $TBef|tr ' \n' '| ')
      if [ "$TName" ];then 
       for zeile in $TName; do # while read -r zeile; do
         zeile=$(echo "$zeile"|tr '|' ' ')
         printf " nach Größe+Datum: $lila$zeile$reset\n"
    DName=$(mysql --defaults-extra-file=~/.mysqlpwd quelle -s -e"SELECT Name FROM briefe WHERE Pfad=REPLACE(REPLACE('$zeile','/DATA/turbomed','$/TurboMed'),'/','\\\\') GROUP BY Pfad")
         printf " DName: $blau$DName$reset\n";
         [ "$DName" ]&&{ gefu=ja;} # break
       done # < <(echo "$TName");
      fi;
    fi;
#    echo gefu: $gefu
    [ $gefu ]||{ 
      fnr=$(expr $fnr + 1);  
      [ $fnr = 1 ]&&{ 
        printf "Nicht in den Turbomed-Karteikarten gefundene Dokumente aus $D:\n" >> $AD; 
        mkdir -p "$Zl"
        for d in "$AD" "$Zl"; do 
          chown sturm:praxis "$d"
          chmod 774 "$d"
        done;
      }
      printf "$DBBef\n";
      printf "$TBef\n";
      printf "${blau}nicht gefunden: $rot$file$reset\n"; printf "%3b: %s\n" $fnr "$(basename "$file")" >> $AD;
      cp -ai "$file" "$Zl";
    }
done;
