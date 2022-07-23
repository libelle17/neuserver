#!/bin/bash
HOST=$(hostname);
# Datenverzeichnis von mysql
VLM=$(sed -n 's/^[[:space:]]*datadir[[:space:]]*=[[:space:]]*\(.*\)/\1/p' /etc/my.cnf); VLM=${VLM:-/var/lib/mysql};
# nicht auf linux1, um nichts falsches zu löschen
if [ ${HOST%%.*}/ != linux1/ ]; then
  # wenn dbeingepackt frisch erstellt und kopiert wurde
  find ~/ -mtime -1 -name dbeingepackt.sql|while read q; do
  # und genauso dbverzeichnis
   find ~/ -mtime -1 -name dbverzeichnis|while read v; do
     echo $q":"
     for db in $(cat ~/dbverzeichnis);do 
       echo " "$db;
       # die alten Datenbanken löschen 
       mysqladmin --defaults-extra-file=~./mysqlpwd -f drop $db; 
       # und ggf. Reste löschen
       rm -rf $VLM/$db;
     done;
     mysql --defaults-extra-file=~./mysqlpwd -e 'SET GLOBAL innodb_fast_shutdown = 0';
     systemctl stop mariadb;
     # Datenbank gleich packen
     rm -f $VLM/ib{data1,_logfile0}
     systemctl start mariadb;
     # und Daten übertragen
     mysql --defaults-extra-file=~./mysqlpwd </root/dbeingepackt.sql;
   done;
  done;
fi;
