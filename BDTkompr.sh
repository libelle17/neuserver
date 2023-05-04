#!/bin/bash
# 21.11.2010
vz="/DATA/eigene Dateien/TMExport"
lvz="/DATA/Papierkorb/eigene Dateien/TMExport"
declare -i -r mint=10 # Mindesttage bis zum Komprimieren
declare -i -r minl=23 # Mindesttage bis zum Löschen
. /root/.7zpassw
# declare -i alter
# declare -i tage
# declare -i jetzt
jetzt=`date +%s`
Dateien=("$vz"/*.BDT "$vz"/*.bdt)
for datei in  "${Dateien[@]}";  do
 echo " "`ls --full-time "$datei"`:
# zdatei=`echo $datei | sed s/".BDT"/".BDT.7z"/g`   # ginge auch
# zdatei=${datei/%.BDT/.BDT.7z}                     # ginge auch
 zdatei="$datei".7z                    # Sekunden seit 1970
 vgl=`stat -c %Y "$datei"`      # Sekunden seit 1970 modification time
 alter=$(($jetzt-$vgl))
 tage=$((alter/60/60/24))
 for runde in 1 2; do                     # wenn Test nicht in Ordnung (s.u.), nochmal
  if [ ! -f "$zdatei" ]; then       # wenn Datei nicht existiert
   echo "  ""Alter: " $tage " Tage"
   echo "  ""$zdatei" existiert nicht.
   if [ $tage -ge $mint ]; then     # wenn Datei alt genug
     ionice -c3 nice -n19 /usr/bin/7z a  "$zdatei" "$datei" -p$passw  -mx=9 -mtc=on -mmt=on      # komprimieren
     touch	 -c -r "$datei" "$zdatei"      # Änderungsdatum setzen
   fi
  fi
  if [ -f "$zdatei" ]; then      # wenn Datei (dann) existiert
   echo "  "$zdatei existiert.
   ionice -c3 nice -n19 /usr/bin/7z t "$zdatei" -p$passw > /dev/null
   rv=$?
   if [ $rv = 0 ]; then
     echo "  ""$zdatei" in Ordnung
     if [ "$tage" -ge $mint ];then	 	 
      echo "  "´$datei´ wird nach ´$lvz´ verschoben
       mv "$datei" "$lvz"
     fi	  
     break	 
   else
     echo "  ""$zdatei" nicht in Ordnung! rv: $rv
     echo "  "´$zdatei´ wird nach ´$lvz´ verschoben
     mv "$zdatei" "$lvz"
   fi 
  else
    break  
  fi 
 done 
done
echo ""
# ganz alte aus dem Papierkorb löschen
Dateien=("$lvz"/*)
for datei in "${Dateien[@]}"; do
 echo "  "`ls --full-time "$datei"`:
 vgl=`stat -c %Y "$datei"`
 alter=$(($jetzt-$vgl))
 tage=$((alter/60/60/24))
 echo "  ""Alter: " $tage " Tage"
 if [ $tage -ge $minl ]; then
  echo "  -> wird geloescht"
  rm "$datei"
 else
  echo "  -> wird noch nicht geloescht"
 fi
done
