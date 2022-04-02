#!/bin/bash

[ -z "$3" ] && echo "Usage: $0 host user password" >&2 && exit 1

dt="tmp_$RANDOM$RANDOM"

mysql -h $1 -u $2 -p$3 -ABNe "create database $dt;"
[ $? -ne 0 ] && echo "Error: $0 terminating" >&2 exit 1

echo
echo "Created temporary database ${dt} on host $1"
echo

c=0
for d in $(mysql -h $1 -u $2 -p$3 -ABNe "show databases;" | egrep -iv "information_schema|mysql|performance_schema|$dt")
do
  echo database: $d;
  mysql -h $1 -u $2 -p$3 -ABNe "show tables;" $d|while read t; do 
#  mysql -h $1 -u $2 -p$3 -ABNe "SELECT TABLE_NAME FROM information_schema.tables WHERE table_schema='$d' AND table_type='BASE TABLE'"|while read t; do 
    echo " table: $t;"
    tc=$(mysql -h $1 -u $2 -p$3 -ABNe "show create table \`$t\`\\G" $d | egrep -iv "^\*|^$t")
		
		echo $tc | grep -iq "ROW_FORMAT"
		if [ $? -ne 0 ]
		then
			tf=$(mysql -h $1 -u $2 -p$3 -ABNe "select row_format from information_schema.innodb_sys_tables where name = '${d}/${t}';")
			tc="$tc ROW_FORMAT=$tf"
		fi
		
		ef="/tmp/e$RANDOM$RANDOM"
		mysql -h $1 -u $2 -p$3 -ABNe "set innodb_strict_mode=1; set foreign_key_checks=0; ${tc};" $dt >/dev/null  2>$ef
		[ $? -ne 0 ] && cat $ef | grep -q "Row size too large" && echo "${d}.${t}" && let c++ || mysql -h $1 -u $2 -p$3 -ABNe "drop table if exists \`${t}\`;" $dt
		rm -f $ef
	done
done
mysql -h $1 -u $2 -p$3 -ABNe "set innodb_strict_mode=1; drop database $dt;"
[ $c -eq 0 ] && echo "No tables with rows size too large found." || echo && echo "$c tables found with row size too large."
echo
echo "$0 done."
