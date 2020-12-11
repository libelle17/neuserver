#!/bin/sh
dblau="\e[0;34;1;47m";
reset="\e[0m";
PROT="/var/log/rsync.log"
kopier () {
 echo Parameter in kopier: "$@"
# tuez="rsync -avu $@"
# tue=$(echo $tuez|sed 's/ -avu / -avu /g');
 tue="ionice -c3 nice -n19 rsync -avu $@"
# echo -e $dblau$tuez$reset;
# eval $tuez; erg=$?;
##error in rsync protocol data stream (code 12)
# if test $erg -eq 12; then 
  echo -e $dblau$tue$reset;
  eval $tue; 
# fi;
}
echo `date +'%Y-%m-%d %H:%M:%S'` "Beginn rsync aus $0 \""$@"\"" >> "$PROT";
#ionice -c 3 rsync -avu "$@"
echo Parameter: "$@"
kopier "$@";
echo `date +'%Y-%m-%d %H:%M:%S'` "Ende rsync aus $0 \""$@"\"" >> "$PROT";
