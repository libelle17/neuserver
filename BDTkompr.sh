#!/bin/bash
# BDTkompr.sh - 21.11.2010: komprimiert alte BDT-Exportdateien unter
# "/DATA/eigene Dateien/TMExport" (*.BDT/*.bdt) einzeln per 7z (mit
# Passwort aus /root/.7zpassw), sobald sie mindestens $mint (10) Tage alt
# sind, prüft danach die Archiv-Integrität (7z t) und verschiebt bei
# Erfolg das Original nach $lvz (Papierkorb-Pfad); ist das Archiv defekt,
# wird stattdessen das (fehlerhafte) Archiv selbst in den Papierkorb
# verschoben, damit beim nächsten Lauf ein neuer Versuch erfolgt. Im
# zweiten Teil werden Dateien im Papierkorb-Pfad, die mindestens $minl
# (23) Tage alt sind, endgültig gelöscht. Aufruf ohne Parameter.
vz="/DATA/eigene Dateien/TMExport"
lvz="/DATA/Papierkorb/eigene Dateien/TMExport"
declare -i -r mint=10 # Mindesttage bis zum Komprimieren
declare -i -r minl=23 # Mindesttage bis zum L�schen
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
     touch	 -c -r "$datei" "$zdatei"      # �nderungsdatum setzen
   fi
  fi
  if [ -f "$zdatei" ]; then      # wenn Datei (dann) existiert
   echo "  "$zdatei existiert.
   ionice -c3 nice -n19 /usr/bin/7z t "$zdatei" -p$passw > /dev/null # Integrit�t testen
   rv=$?
   if [ $rv = 0 ]; then
     echo "  ""$zdatei" in Ordnung
     if [ "$tage" -ge $mint ];then	 	 
      echo "  "�$datei� wird nach �$lvz� verschoben
       mv "$datei" "$lvz"
     fi	  
     break	 
   else
     echo "  ""$zdatei" nicht in Ordnung! rv: $rv
     echo "  "�$zdatei� wird nach �$lvz� verschoben
     mv "$zdatei" "$lvz"
   fi 
  else
    break  
  fi 
 done 
done
echo ""
# ganz alte aus dem Papierkorb l�schen
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
