#!/bin/bash
HOST=$(hostname);
Ds=/DATA/sql/;
# Datenverzeichnis von mysql
VLM=$(sed -n 's/^[[:space:]]*datadir[[:space:]]*=[[:space:]]*\(.*\)/\1/p' /etc/my.cnf); VLM=${VLM:-/var/lib/mysql};
echo VLM: $VLM;
# nicht auf linux1, um nichts falsches zu löschen
if [ ${HOST%%.*}/ != linux1/ ]; then
  # nochmal kopieren, falls dieser Rechner zum Erstellungzeitpunkt ausschaltet sein sollte
  for datei in dbverzeichnis dbeingepackt.sql; do
    mountpoint -q /DATA||mount /DATA;
    mountpoint -q /DATA&&{ 
      mkdir -p $Ds;
      rsync -avuz linux1:/root/$datei $Ds;
    }
  done;
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
#  for datei in dbverzeichnis dbeingepackt.sql; do rm $Ds/$datei; done;
fi;
