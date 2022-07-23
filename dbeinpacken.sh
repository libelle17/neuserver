#!/bin/bash
dbs=$(mysql --defaults-extra-file=~/.mysqlpwd -BNe 'show databases' | grep -vE '^mysql$|^(performance|information)_schema$')
echo $dbs>~/dbverzeichnis
mysqldump --defaults-extra-file=~/.mysqlpwd --default-character-set=utf8mb4 --complete-insert --compress --disable-keys --routines --events --triggers --databases $dbs > ~/dbeingepackt.sql
#    echo "$dbs" | while read -r db; do
#        mysqladmin drop "$db"
#    done && \
#    mysql -e 'SET GLOBAL innodb_fast_shutdown = 0' && \
#    /etc/init.d/mysql stop && \
#    rm -f /var/lib/mysql/ib{data1,_logfile*} && \
#    /etc/init.d/mysql start && \
#    mysql < alldatabases.sql
