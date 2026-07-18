#!/bin/dash
# buwin10.sh - sichert die virtuelle Windows-10-Festplatte
# (/DATA/VirtualBox/Wind10/Wind10.vdi) per rsync von linux1 auf den
# Zielrechner $ZL (Push) bzw. zieht sie von $QL (Pull, wenn direkt auf dem
# Zielrechner aufgerufen) - wie bumo.sh/bunacht.sh nach demselben
# Push/Pull-Schema (siehe bul1.sh/bugem.sh). VOR dem eigentlichen Kopieren
# wird zur Sicherheit eine Turbomed-Schutzdatei ($SD, von bugem.sh gesetzt)
# zwischen Quelle (/mnt/virtwin/turbomed) und Ziel (/mnt/$gpc/turbomed)
# verglichen (diff) - stimmen beide Mountpunkte nicht überein, wird NICHT
# kopiert, sondern eine Ransomware-Sicherheitswarnung an
# diabetologie@dachau-mail.de gemailt (Gedanke: unerwartete Abweichungen
# könnten auf eine laufende Verschlüsselung hindeuten). $obecht (per -e)
# steuert, ob wirklich kopiert wird oder nur der Befehl angezeigt wird.
# Aufruf: buwin10.sh [bugem.sh-Parameter, u.a. -e, -z "<Zielnummer>"].
MUPR=$(readlink -f $0); # Mutterprogramm
. ${MUPR%/*}/bul1.sh # LINEINS=linux1, buhost festlegen
[ "$buhost"/ = "$LINEINS"/ ]&&ZL=||QL=$LINEINS;
. ${MUPR%/*}/bugem.sh # commandline-Parameter, $ZL aus commandline, $qssh, $zssh festlegen
[ "$buhost"/ != "$LINEINS"/ -a "$ZL" ]&&{ printf "Ziel \"$blau$ZL$reset\" wird zurückgesetzt.\n"; ZL=;}
[ "$buhost"/ = "$LINEINS"/ -a -z "$ZL" ]&&{ printf "${rot}Kein Ziel angegeben. Breche ab$reset.\n";exit;}
wirt=${QL:-$buhost};
. ${MUPR%/*}/virtnamen.sh # legt aus $wirt fest: $gpc, $gast, $tush
[ "$gpc" ]||exit; # auf linux3 gibts keinen virtuellen Server
l1gpc=$gpc; # Gast-PC von Linux1
wirt=${ZL:-$buhost};
. ${MUPR%/*}/virtnamen.sh # legt aus $wirt fest: $gpc, $gast, $tush
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
  if [ $ret/ = 0/ -o 1 ]; then
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
 else
    printf "Liebe Praxis,\nbeim Versuch der Sicherheitskopie fand sich ein Unterschied zwischen\n${Q:-$LINEINS:}$SDHIER und\n$ZL$SDDORT.\nDa so etwas auch durch Ransomeware verursacht werden könnte, wurde die Sicherheitskopie für dieses Verzeichnis unterlassen.\nBitte den Systemadiminstrator verständigen!\nMit besten Grüßen, Ihr Linuxrechner"|mail -s "Achtung, Sicherheitswarnung von ${QL:-$LINEINS:} zu /$QVos vor Kopie auf $ZL!" diabetologie@dachau-mail.de
    printf "${rot}keine Übereinstimmung bei \"$SD\"!$reset\n"
    return 1;
 fi;
}

