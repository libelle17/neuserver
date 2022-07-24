#!/bin/bash
HOST=$(hostname);
Ds=/DATA/sql;
# Datenverzeichnis von mysql
VLM=$(sed -n 's/^[[:space:]]*datadir[[:space:]]*=[[:space:]]*\(.*\)/\1/p' /etc/my.cnf); VLM=${VLM:-/var/lib/mysql};
Beleg=$VLM/dbausgepackt;
MUPR=$(readlink -f $0); # Mutterprogramm
. ${MUPR%/*}/bugem.sh # commandline-Parameter, $ZL aus commandline, $qssh, $zssh festlegen
printf "VLM: $blau$VLM$reset\n";
# nicht auf linux1, um nichts falsches zu löschen
if [ ${HOST%%.*}/ != linux1/ ]; then
  # nochmal kopieren, falls dieser Rechner zum Erstellungzeitpunkt ausschaltet sein sollte
  for datei in dbverzeichnis dbeingepackt.sql; do
    mountpoint -q /DATA||mount /DATA;
    mountpoint -q /DATA&&{ 
      ausf "mkdir -p $Ds";
      ausf "rsync -avuz linux1:$Ds/$datei $Ds/" $blau;
    }
  done;
  # wenn die Datei nicht schon ausgepackt wurde
  [ -f $Beleg ]&&pruef="-newer $Beleg"||pruef=;
  [ "$verb" ]&&printf "Beleg: $blau$Beleg$reset\n";
  [ "$verb" ]&&printf "pruef: $blau$pruef$reset\n";
  [ "$verb" ]&&printf "${blau}find $Ds $pruef -name dbeingepackt.sql$resett\n";
  if find $Ds $pruef -name dbeingepackt.sql|grep -q .; then
    # wenn dbeingepackt frisch erstellt und kopiert wurde
    find $Ds -mtime -1 -name dbeingepackt.sql|while read q; do
    # und genauso dbverzeichnis
     find $Ds -mtime -1 -name dbverzeichnis|while read v; do
       echo $q":"
       for db in $(cat $Ds/dbverzeichnis);do 
         echo " "$db;
         # die alten Datenbanken löschen 
         mysqladmin --defaults-extra-file=~/.mysqlpwd -f drop $db; 
         # und ggf. Reste löschen
         rm -rf $VLM/$db;
       done;
       mysql --defaults-extra-file=~/.mysqlpwd -e 'SET GLOBAL innodb_fast_shutdown = 0';
       systemctl stop mariadb;
       # Datenbank gleich packen
       rm -f $VLM/ib{data1,_logfile0}
       systemctl start mariadb;
       # und Daten übertragen
       mysql --defaults-extra-file=~/.mysqlpwd </$Ds/dbeingepackt.sql;
     done;
    done;
    touch -r $Ds/dbeingepackt.sql $Beleg;
  fi;
#  for datei in dbverzeichnis dbeingepackt.sql; do rm $Ds/$datei; done;
fi;
