#/bin/bash
# Anzeige des Mysql-Datenbankinhalts zum Überprüfen der Integrität nach Kopie
mysql --defaults-extra-file=~/.mysqlpwd -e"SELECT CONCAT(TABLE_SCHEMA,'.\`',TABLE_NAME,'\`') FROM information_schema.tables WHERE TABLE_TYPE='BASE TABLE'"|tail -n +2|while read zeile; do
   mysql --defaults-extra-file=~/.mysqlpwd quelle -e"select count(0) from $zeile"|tail -n +2|while read erg; do 
    printf " %70s %10s\n" "$zeile" "$erg";
    break; 
   done;
done;
