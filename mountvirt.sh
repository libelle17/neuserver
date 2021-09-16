#!/bin/bash
ftb="/etc/fstab";
cre="/home/schade/.wincredentials"
[ -f "$cre" ]&&
for gpc in virtwin virtwin0; do
 grep -q /$gpc/ $ftb||{
  sed -i.bak -e "/^LABEL=/{i\//$gpc/Turbomed /mnt/$gpc/turbomed cifs nofail,vers=3.11,credentials=$cre 0 2" -e ":a;n;ba}" $ftb
 }
done|| echo Datei $cre nicht gefunden!;

