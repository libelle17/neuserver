#!/bin/bash
# laesst die juengste Datei immer stehen
Pfad=/DATA/sql
Itv=14;
for D in $(find $Pfad -maxdepth 1 -mtime +$Itv -size +1M -name "*.sql"); do
  if find $Pfad -wholename "${D%%--*}--*.sql" -newer $D |grep .; then
    rm -f $D.7z;
    7z a $D.7z $D -mx=9 -mtc=on -mnt=on&&{
      touch -r $D $D.7z && rm $D;
    }
  fi;
done;
