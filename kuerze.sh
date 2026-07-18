#/bin/bash
# kuerze.sh - kürzt eine Datei $1 VORNE (nicht am Ende wie üblich bei
# Logrotate) auf maximal $2 Bytes: ist die Datei größer, wird per "dd"
# der überschüssige vordere Teil übersprungen (skip=diff), der Rest in
# "<datei>_gekuerzt" geschrieben und diese Datei zurück auf den
# Originalnamen verschoben. Nützlich z.B. für stetig wachsende Logs, bei
# denen nur der jüngste Teil interessiert. Aufruf: kuerze.sh <Datei>
# <MaxBytes>. Tut nichts, wenn die Datei fehlt oder $2 leer ist.
datei=$1;
max=$2;
if [ -f "$datei" -a "$max" ]; then
  awk 'BEGIN{
    if ((diff='$(stat $datei -c '%s')'-'$max')>0){
      cmd="dd bs="diff" skip=1 if='$datei' of='$datei'_gekuerzt 2>/dev/null;\
           mv '$datei'_gekuerzt '$datei'";
      system(cmd);
    }
  }';
fi;
