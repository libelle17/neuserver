#!/bin/bash
dt=nmap.txt
rm -f $dt
for i in $(seq 1 1 255); do
  echo i: $i
  erg=$(nmap -sP 192.168.178.$i);
  if ! echo $erg|grep -q "seems down"; then
    echo $erg >>$dt;
  fi;
done;
