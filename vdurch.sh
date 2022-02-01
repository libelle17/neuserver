#!/bin/bash
MUPR=$(readlink -f $0); # Mutterprogramm
. ${MUPR%/*}/bul1.sh # LINEINS=linux1, buhost festlegen
. ${MUPR%/*}/bugem.sh # commandline-Parameter, $ZL aus commandline, $qssh, $zssh festlegen
wirt=$buhost;
echo wirt: $wirt
exit
. ${MUPR%/*}/virtnamen.sh # legt aus $wirt fest: $gpc, $gast, $tush
ot=/opt/turbomed;
ausf "$tush 'mv /$ot/lauf /$ot/lau  2>/dev/null||touch /$ot/lau'&&sleep 80s";
VBoxManage controlvm Win10 poweroff; VBoxManage startvm Win10 --type headless;
mv /$ot/lau /$ot/lauf 2>/dev/null||touch /$ot/lauf; # zurückbenennen, damit Turbomed wieder starten kann
