#!/bin/bash
# packt die Datenbanktabellen ein, um sie umzuziehen oder ibdata1 zu loeschen
if false; then
dbs=$(mysql --defaults-extra-file=~/.mysqlpwd -BNe 'show databases' | grep -vE '^mysql$|^(performance|information)_schema$')
echo $dbs>~/dbverzeichnis
mysqldump --defaults-extra-file=~/.mysqlpwd --default-character-set=utf8mb4 --complete-insert --compress --disable-keys --routines --events --triggers --databases $dbs > ~/dbeingepackt.sql
fi;
for z in 0 3 7 8; do
  echo linux$z":";
  for datei in dbverzeichnis dbeingepackt.sql; do
    rsync -avuz ~/$datei linux$z:/root/
  done;
done;
