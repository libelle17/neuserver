#!/bin/bash
if test $# != 2; then
  echo $0: Listet den Füllungszustand aller gefüllten Tabellen einer Datenbank eines Servers auf
  echo Gebrauch: "$0 <datenbank> <rechner>"
else
DB=$1;SV=$2;ssh $SV "mysql --defaults-extra-file=~/.mysqlpwd $DB -e \"SELECT CONCAT(RPAD(table_name,40,'.'),TABLE_ROWS) \\\`$SV $DB:\\\` FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = '$DB' AND NOT ISNULL(table_rows) AND table_rows<>0 ORDER BY table_name\""
fi
