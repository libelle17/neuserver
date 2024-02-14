#!/bin/dash
# kopiert in p:\eingelesen\... fehlende Dokumente aus /DATA/turbomed/Dokumente und benennt differierend benannte um
gruen="\033[0;32m"
blau="\033[1;34m";
dblau="\033[0;34;1;47m";
rot="\033[1;31m";
lila="\033[1;35m";
reset="\033[0m";
EG=/DATA/Patientendokumente/eingelesen;
# DBBef="mariadb --defaults-extra-file=~/.mysqlpwd quelle -s -e\"SELECT CONCAT('\\\"',CONCAT_WS('\\\" \\\"',pfad,name,dokgroe,dokaend),'\\\"') z FROM briefe LIMIT 10\""; # LIMIt 10;\""
Jahr=2007;
Interv=0;
# for Jahr in $(seq 2018 1 $(date +%Y)); do
# for Jahr in $(seq $([ $(date +%m) = 12 ]&& expr $(date +%Y) - 1 - $Interv||expr $(date +%Y) - $Interv) 1 $(date +%Y));do 
for Jahr in 2023; do
 printf "${lila}Jahr: $gruen$Jahr$reset\n";
 DBBef="mariadb --defaults-extra-file=~/.mysqlpwd quelle -s -e\"SELECT CONCAT_WS('|',id,MID(pfad,INSTR(pfad,'\2'),4),REPLACE(REPLACE(pfad,'\\\\\\\\','/'),'$/TurboMed','/DATA/turbomed'),name,dokgroe,dokaend) z FROM briefe WHERE pfad<>'' AND NOT pfad RLIKE '\\\\\\\\\\\\\\\\PatBrief\\\\\\\\\\\\\\\\' AND pfad RLIKE '\\\\\\\\\\\\\\\\$Jahr' AND NOT pfad RLIKE '^[pq]:'\"";# LIMIT 20\"";
 printf "${blau}DBBef: $lila$DBBef$reset\n";
 TName=$(eval "$DBBef")
 nr=0;
 if [ "$TName" ];then 
  echo "$TName"|while read -r z; do
    nr=$(expr $nr + 1);            #    let nr=$nr+1 (geht nur in bash)
    case $nr in *00) 
     printf "$blau$nr$reset: $z\n";;
    esac;
#    printf "$blau$nr$reset ";
    wnr=0;
    RIFS=$IFS;
    IFS="|";
    for w in $z; do
      wnr=$(expr $wnr + 1);          
#      printf "$rot  $wnr$reset: $w\n"
      case $wnr in 
        1) ID="$w";;
        2) JAHR="$w";;
        3) PFAD="$w";;
        4) NAME="$w";
           RNAME=$(printf '%s\n' "$NAME"|sed 's/\$/\\$/g'); #           RNAME=${NAME//$/\\$};
          ;;
        5) DOKGROE="$w";;
        6) DOKAEND="$w";;
      esac;
    done;
    IFS=$RIFS;
    case "$NAME" in */*);;*)
     if test -f "$PFAD"; then
      obkop=;
      kop=$(find $EG/$JAHR -name "$NAME");
      if test "$kop"; then
#        printf "$blau$nr$reset: $kop\n";
        true;
      else
        printf "$nr: $blau$ID $lila$NAME $blau$PFAD$lila nicht gefunden!$reset\n"
        EP=$(date -d "$DOKAEND" +%s)
        EPmd=$(expr $EP - 86400);       #      let MTme=$MT-1 MTpt=$MT+86400;
        EPpe=$(expr $EP + 1);
        TBef="find $EG/$JAHR -type f -size ${DOKGROE}c -newermt @$EPmd -not -newermt @$EPpe"
        printf "${blau} TBef:$lila $TBef$reset\n";
        erg=$(eval "$TBef")
        if test "$erg"; then
          printf "$rot $erg$reset aufgetaucht und ";
          if diff "$PFAD" "$erg" >/dev/null; then 
            printf "gleich\n"; 
            be=$(basename "$erg");
            UBef="mariadb --defaults-extra-file=~/.mysqlpwd quelle -s -e\"SELECT id FROM briefe WHERE name=\\\"$be\\\" AND NOT id=$ID\"";
            printf " $blau$UBef$reset\n";
            res=$(eval "$UBef");
            printf " res: $blau$res$reset\n";
            if test "$res"; then
              obkop=1;
            else
              UBef="mv -i \"$erg\" \"$EG/$JAHR/$RNAME\""
              printf "$blau $UBef$reset\n";
              eval "$UBef";
            fi;
          else 
            obkop=1;
            printf "verschieden\n"; 
          fi;
        else
          obkop=1;
        fi;
        if test $obkop; then
          KBef="cp -ai \"$PFAD\" \"$EG/$JAHR/$RNAME\""
          printf "$blau $KBef$reset\n";
          eval "$KBef";
        fi;
        #        Kontr=$(date -d@$EP +"%Y%m%d %H%M%S")
#        printf "DOKAEND: $DOKAEND $EP $Kontr\n";
      fi;
     else
      printf "$rot$PFAD$reset fehlt!\n";
      bn=$(basename "$PFAD");
      UBef="find /DATA/Papierkorb/turbomed/Dokumente /DATA/turbomed/Dokumente -iname \"$bn*\" -ls";
      printf " $blau$UBef$reset\n";
      erg=$(eval "$Ubef")
      printf " ${blau}erg:$lila $erg$reset\n";
     fi;
    ;; esac;
    if test $wnr != 6; then printf "$rot Fehler: wnr=$wnr $reset\n"; exit; fi;
  done;
#  echo $TName;
 fi;
done;
