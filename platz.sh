#!/bin/bash
# wenn auf Laufwerk / der verbrauchte Platz 100% ist, dann geratenerweise postdrop abbrechen
par=;
for iru in $(seq 1 1 5); do
  [ $iru = 3 ]&&par="-9";
  [ $(df /|awk '/\//{print $5*1}') = 100 ]&&ps -Alf|grep postdrop|grep -v grep|pkill $par postdrop;
done;
