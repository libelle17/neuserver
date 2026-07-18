#!/bin/bash
# dbeinpacken.sh - packt die Datenbanktabellen ein, um sie umzuziehen oder
# ibdata1 zu loeschen: mountet /DATA falls nötig, ermittelt alle Datenbanken
# außer mysql/performance_schema/information_schema, schreibt deren Namen
# nach $Ds/dbverzeichnis und erstellt per mysqldump (komprimiert, UTF-8,
# inkl. Routinen/Events/Triggern) einen Gesamtdump aller dieser Datenbanken
# nach $Ds/dbeingepackt.sql. Gegenstück zum Wiedereinspielen: dbauspacken.sh.
# Aufruf ohne Parameter.
Ds=/DATA/sql/;
mountpoint -q /DATA||mount /DATA;
mountpoint -q /DATA&&{
  mkdir -p $Ds;
  dbs=$(mysql --defaults-extra-file=~/.mysqlpwd -BNe 'show databases' | grep -vE '^mysql$|^(performance|information)_schema$')
  echo $dbs>$Ds/dbverzeichnis
  mysqldump --defaults-extra-file=~/.mysqlpwd --default-character-set=utf8mb4 --complete-insert --compress --disable-keys --routines --events --triggers --databases $dbs > $Ds/dbeingepackt.sql
};
