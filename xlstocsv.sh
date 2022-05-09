#!/bin/bash
#wandelte Dateien mit pathologischen Laborwerten von xls zu csv-Dateien und verschiebt die Originale nach LaborAlt
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
     mv "$G" "$SL";
    };
   fi;
  };
 done;
done;
#echo Fertig!
