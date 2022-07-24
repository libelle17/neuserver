#!/bin/bash
# packt die Datenbanktabellen ein, um sie umzuziehen oder ibdata1 zu loeschen
Ds=/DATA/sql/;
mountpoint -q /DATA||mount /DATA;
mountpoint -q /DATA&&{
  mkdir -p $Ds;
  dbs=$(mysql --defaults-extra-file=~/.mysqlpwd -BNe 'show databases' | grep -vE '^mysql$|^(performance|information)_schema$')
  echo $dbs>$Ds/dbverzeichnis
  mysqldump --defaults-extra-file=~/.mysqlpwd --default-character-set=utf8mb4 --complete-insert --compress --disable-keys --routines --events --triggers --databases $dbs > $Ds/dbeingepackt.sql
};
