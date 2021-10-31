#!/bin/dash
MUPR=$(readlink -f $0); # Mutterprogramm
. ${MUPR%/*}/bul1.sh # LINEINS=linux1, buhost festlegen
[ "$buhost"/ = "$LINEINS"/ ]&&ZL=||QL=$LINEINS;
. ${MUPR%/*}/bugem.sh # commandline-Parameter, $ZL aus commandline, $qssh, $zssh festlegen
[ "$buhost"/ != "$LINEINS"/ -a "$ZL" ]&&{ printf "Ziel \"$blau$ZL$reset\" wird zurückgesetzt.\n"; ZL=;}
[ "$buhost"/ = "$LINEINS"/ -a -z "$ZL" ]&&{ printf "${rot}Kein Ziel angegeben. Breche ab$reset.\n";exit;}
wirt=${QL:-$buhost};
. ${MUPR%/*}/virtnamen.sh # legt aus $wirt fest: $gpc, $gast sowie aus $buhost: tush
l1gpc=$gpc; # Gast-PC von Linux1
wirt=${ZL:-$buhost};
. ${MUPR%/*}/virtnamen.sh # legt aus $wirt fest: $gpc, $gast sowie aus $buhost: tush
rgpc=$gpc; # Gast-PC des Reserveservers
qv=/mnt/virtwin/turbomed;
zv=/mnt/$gpc/turbomed;
ausf "mountpoint $qv 2>/dev/null";
ret1=$ret;
ausf "mountpoint $zv 2>/dev/null";
ret2=$ret;
diffbef="diff $qv/$SD $zv/$SD 2>/dev/null";
[ $ret1 = 0 -a $ret2 = 0 ]&&{
  ausf "$diffbef";
  [ $ret = 0 ]&&{
   datei="/DATA/VirtualBox/Wind10/Wind10.vdi";
   if [ "$QL" ]; then
     tue="rsync -avu \"$QL:$datei\" \"$datei\"";
   else
     tue="rsync -avu \"$datei\" \"$ZL:$datei\"";
   fi;
   if [ $obecht ]; then
     ausf "$tue";
   else 
     printf "$dblau$tue$reset\n";
   fi; 
  }
}
exit;
[ "$SD" ]&&{
  if [ -z "$QL" -a -z "$ZL" ]; then
    diffbef="diff /$QVos/$SD /$ZVos/$SD 2>/dev/null";
  elif [ "$QL" ]; then
    diffbef="ssh $QL cat \"/$QVos/$SD\" 2>/dev/null| diff - /$ZVos/$SD 2>/dev/null";
  elif [ "$ZL" ]; then
    diffbef="ssh $ZL cat \"/$ZVos/$SD\" 2>/dev/null| diff - /$QVos/$SD 2>/dev/null";
  fi;
#    printf "${blau}$diffbef$reset\n"
  ausf "$diffbef";
  if [ $ret/ != 0/ ]; then
    printf "Liebe Praxis,\nbeim Versuch der Sicherheitskopie fand sich ein Unterschied zwischen\n${Q:-$LINEINS:}$SDHIER und\n$ZL$SDDORT.\nDa so etwas auch durch Ransomeware verursacht werden könnte, wurde die Sicherheitskopie für dieses Verzeichnis unterlassen.\nBitte den Systemadiminstrator verständigen!\nMit besten Grüßen, Ihr Linuxrechner"|mail -s "Achtung, Sicherheitswarnung von ${QL:-$LINEINS:} zu /$QVos vor Kopie auf $ZL!" diabetologie@dachau-mail.de
    printf "${rot}keine Übereinstimmung bei \"$SD\"!$reset\n"
    return 1;
  fi
}


