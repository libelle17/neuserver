#/bin/bash
# kürzt eine Datei $1 vorne auf maximal $2 Byes
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
