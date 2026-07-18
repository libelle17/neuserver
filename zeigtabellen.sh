#/bin/bash
# zeigtabellen.sh - Anzeige des Mysql-Datenbankinhalts zum Überprüfen der
# Integrität nach Kopie: listet für JEDE Basistabelle in JEDER Datenbank
# (INFORMATION_SCHEMA.TABLES, TABLE_TYPE='BASE TABLE') deren Zeilenzahl
# (SELECT COUNT(0)) auf - anders als fzst.sh (eine Datenbank, ein Rechner,
# geschätzte TABLE_ROWS) hier über ALLE Datenbanken hinweg und mit echtem
# COUNT(0) statt geschätzter Zeilenzahl. Aufruf ohne Parameter, läuft gegen
# den lokalen Server mit den in ~/.mysqlpwd hinterlegten Zugangsdaten.
mysql --defaults-extra-file=~/.mysqlpwd -e"SELECT CONCAT(TABLE_SCHEMA,'.\`',TABLE_NAME,'\`') FROM information_schema.tables WHERE TABLE_TYPE='BASE TABLE'"|tail -n +2|while read zeile; do
   mysql --defaults-extra-file=~/.mysqlpwd quelle -e"select count(0) from $zeile"|tail -n +2|while read erg; do 
    printf " %75s %10s\n" "$zeile" "$erg";
    break; 
   done;
done;
