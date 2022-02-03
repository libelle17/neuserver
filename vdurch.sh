#!/bin/bash
MUPR=$(readlink -f $0); # Mutterprogramm
. ${MUPR%/*}/bul1.sh # LINEINS=linux1, buhost festlegen
. ${MUPR%/*}/bugem.sh # commandline-Parameter, $ZL aus commandline, $qssh, $zssh festlegen
wirt=$buhost;
. ${MUPR%/*}/virtnamen.sh # legt aus $wirt fest: $gpc, $gast, $tush
echo Stelle 1
ot=/opt/turbomed;
echo Stelle 2
ausf "$tush 'mv /$ot/lauf /$ot/lau  2>/dev/null||touch /$ot/lau'&&sleep 80s";
echo Stelle 3
VBoxManage controlvm Win10 poweroff; VBoxManage startvm Win10 --type headless;
echo Stelle 4
mv /$ot/lau /$ot/lauf 2>/dev/null||touch /$ot/lauf; # zurückbenennen, damit Turbomed wieder starten kann
echo Stelle 5
