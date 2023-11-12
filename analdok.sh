#!/bin/bash
blau="\033[1;34m";
gruen="\033[1;32m";
dblau="\033[0;34;1;47m";
rot="\033[1;31m";
lila="\033[1;35m";
reset="\033[0m";
VglVz=/DATA/turbomed/Dokumente

mar() {
#  echo $1;
  mariadb --defaults-extra-file=~/.mysqlpwd quelle -e"$1";
}

mar "DROP TABLE IF EXISTS dokfiles";
mar "CREATE TABLE dokfiles(id INT(10) AUTO_INCREMENT PRIMARY KEY,pfad VARCHAR(256) DEFAULT '\'\'',name VARCHAR(256) DEFAULT '\'\'',groe INT(10) DEFAULT 0,laend DATETIME DEFAULT 0,KEY pfad(pfad,name),KEY groe(groe),KEY laend(laend))"
mar "SHOW CREATE TABLE dokfiles"
find $VglVz -type f -printf '%TY%Tm%Td%TH%TM%.2TS %s %p\0'|while IFS= read -r -d '' zeile; do 
 arr=($zeile);
 dn=$(dirname "${arr[2]}");
 bn=$(basename "${arr[2]}");
 printf "$blau${arr[0]} $lila%10s $blau$dn $lina$bn\n" ${arr[1]};
 mar "insert into dokfiles(laend,groe,pfad,name) values(\""${arr[0]}"\",\""${arr[1]}"\",\""$dn"\",\""$bn"\")";
done;
