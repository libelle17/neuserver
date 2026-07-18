#!/bin/bash
# xlstocsv.sh - wandelt "labor*.xls"-Dateien mit pathologischen Laborwerten
# direkt unter /DATA/Patientendokumente per soffice in .csv um (setzt bei
# Erfolg zusätzlich CR-Zeilenenden per sed), verschiebt danach die
# Original-.xls nach LaborAlt und verteilt die neue .csv per Kopie in
# KothnyLabor/WagnerLabor/HammerschmidtLabor sowie per Verschieben in
# SchadeLabor (letzte Ablage "gewinnt" also, die anderen behalten nur
# Kopien). Bereits vorhandene .csv-Zieldateien werden nicht überschrieben
# (Meldung "gabs schon"). Aufruf: xlstocsv.sh [-v] (-v = ausführliche
# Zwischenausgaben inkl. der aufgerufenen Befehle).
St=/DATA/Patientendokumente;
La="$St/LaborAlt";
KL="$St"/KothnyLabor/;
HL="$St"/HammerschmidtLabor/;
WL="$St"/WagnerLabor/;
SL="$St"/SchadeLabor/;
[ "$1" = "-v" ]&&verbose=1;
for Vz in "$St"; do
 find $Vz -maxdepth 1 -iname "labor*.xls"|
 while read F; do
  G=${F%.xls}.csv
  [ "$verbose" ]&&echo $G
  [ "$verbose" ]&&echo $F
  [ "$verbose" ]&&echo soffice --headless --convert-to csv --outdir "$Vz" "$F"
  [ -f "$G" ]&&echo " '$G' gabs schon!"||
  {
   befehl="soffice --headless --convert-to csv --outdir \"$Vz\" \"$F\"";
   if [ "$verbose" ];then
     eval "$befehl";
   else
     eval "$befehl" >/dev/null;
   fi;
   if [ "$?" -eq 0 ]; then
#    sed -i "s/$/\r\n/" "$G" &&{  # geht nicht so gut
    sed -i "s/$/`echo -e \\\r`/" "$G" &&{ 
     [ "$Vz" == "$La" ]|| mv "$F" "$La";
     cp -a "$G" "$KL";
     cp -a "$G" "$WL";
     cp -a "$G" "$HL";
     mv "$G" "$SL";
    };
   fi;
  };
 done;
done;
#echo Fertig!
