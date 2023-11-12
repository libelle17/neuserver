#!/bin/bash
blau="\033[1;34m";
gruen="\033[1;32m";
dblau="\033[0;34;1;47m";
rot="\033[1;31m";
lila="\033[1;35m";
reset="\033[0m";
VglVz=/DATA/turbomed/Dokumente
testVz=/DATA/Patientendokumente/ohneImportNachweis

mar() {
  echo $1;
  mariadb --defaults-extra-file=~/.mysqlpwd quelle -e"$1";
}

indb() {
mar "DROP TABLE IF EXISTS dokfiles";
mar "CREATE TABLE dokfiles(id INT(10) AUTO_INCREMENT PRIMARY KEY,pfad VARCHAR(256) DEFAULT '\'\'',name VARCHAR(256) DEFAULT '\'\'',groe INT(10) DEFAULT 0,laend DATETIME DEFAULT 0,KEY pfad(pfad,name),KEY groe(groe),KEY laend(laend))"
mar "SHOW CREATE TABLE dokfiles"
find $VglVz -type f -printf '%TY%Tm%Td%TH%TM%.2TS %s %p\0'|while IFS= read -r -d '' zeile; do 
 arr=($zeile);
 rest=${arr[2]};
 for (( i=3;i<${#arr[@]};i++ )); do
   rest="$rest ${arr[$i]}";
 done;
 dn=$(dirname "$rest");
 bn=$(basename "$rest");
 printf "$blau${arr[0]} $lila%10s $blau$dn $lina$bn\n" ${arr[1]};
 mar "INSERT INTO dokfiles(laend,groe,pfad,name) VALUES(\""${arr[0]}"\",\""${arr[1]}"\",\""$dn"\",\""$bn"\")";
done;
}

vortest() { 
if find "$VglVz" "$testVz" -type f -iname '*|*' -printf "${rot}%p$reset gefunden, macht Programm Problem wegen des |-Zeichens, breche ab!\n" |grep .; then # -quit, falls nur eine Datei angezeigt werden soll
 exit 1;
fi;
}

haupttest() {
find "$testVz" -type f -printf '%TY%Tm%Td%TH%TM%.2TS|%s|%p\0'|while IFS= read -r -d '' zeile; do 
 IFS='|' arr=($zeile);
 epo=$(date --date="$(echo "${arr[0]}"|sed 's/\(....\)\(..\)\(..\)\(..\)\(..\)\(..\)/\2\/\3\/\1 \4:\5:\6/')" +'%s');
 von=$(date -d @$(awk "BEGIN{print "$epo"-5*24*60*60}") +"%Y%m%d%H%M%S")
 bis=$(date -d @$(awk "BEGIN{print "$epo"+3*60*60+1}") +"%Y%m%d%H%M%S") # all mögliche Kombinationen von Zeitzonen
 dn=$(dirname "${arr[2]}");
 bn=$(basename "${arr[2]}");
# printf "$dblau$zeile$reset\n";
# printf "$blau${arr[0]} $lila%10s $blau$dn $lila$bn$reset\n" ${arr[1]};
 ru=1;
 bef="SELECT CONCAT(DATE_FORMAT(laend,'%Y%m%d%H%i%S'),'|',pfad,'|',name) FROM dokfiles WHERE groe=\""${arr[1]}"\" AND laend BETWEEN $von AND $bis";
 mariadb --defaults-extra-file=~/.mysqlpwd quelle -Ne"$bef"|while read -r zeile; do
# echo bef: "$bef";
  IFS="|" ari=($zeile);
  echo "";

if false; then
  if [ ! -f "${ari[1]}/${ari[2]}" ]; then
    bef="find \"${ari[1]}\" -size \"${arr[1]}\"c -newermt \"$(echo $von|sed 's/^\(........\)\(....\).*/\1 \2/')\" -not -newermt \"$(echo $bis|sed 's/^\(........\)\(....\).*/\1 \2/')\" -name \"${ari[2]}*\" -printf '%f\n'";
    echo bef: $bef;
#    neuname=$(find "${ari[1]}" -size "${arr[1]}"c -newermt "$(echo $von|sed 's/^\(........\)\(....\).*/\1 \2/')" -not -newermt "$(echo $bis|sed 's/^\(........\)\(....\).*/\1 \2/')" -name "${ari[2]}*" -printf '%f\n');
    neuname=$(eval "$bef");
    [ $neuname ]&& printf "${ari[2]} => $rot$neuname$reset\n";
  fi;
fi;

  diff "$dn/$bn" "${ari[1]}/${ari[2]}" >/dev/null 2>/dev/null;
  if [ $? -ne 0 ]; then
    echo "$dn/$bn" "${ari[1]}/${ari[2]}"
    echo bef: "$bef";
    printf "zeile: $lila$zeile$reset\n";
    diff "$dn/$bn" "${ari[1]}/${ari[2]}";
    echo ari2: ${ari[2]};
  fi;
  if diff "$dn/$bn" "${ari[1]}/${ari[2]}" >/dev/null; then # wenn identisch
    bef="select * from briefe where pfad like '%"${ari[2]}"%'";
    bef="SELECT * FROM briefe WHERE pfad=CONCAT(REPLACE(REPLACE(\""${ari[1]}"\",\"/DATA/turbomed\",\"$/TurboMed\"),\"/\",\"\\\\\"),\"\\\\\",\""${ari[2]}"\")";
#    echo bef: $bef
    mariadb --defaults-extra-file=~/.mysqlpwd quelle -Ne"$bef"|while read -r zeile; do
      printf "$rot gefunden!!!!!!!!!!!!!!!$reset\n";
  #    printf "${rot}Runde: ${blau}$ru$reset\n";
      printf "$rot$dn $bn$reset $zeile\n";
      printf "$dblau${arr[2]}$reset\n";
      printf "$lila${ari[0]}$reset\n";
      printf "$lila${ari[1]}$reset\n";
      printf "$lila${ari[2]}$reset\n";
    done;
  fi;
  ru=$(awk "BEGIN{print "$ru"+1}");
 done;
done;
}

indb;
vortest;
haupttest;
