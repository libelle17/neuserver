#!/bin/bash
MUPR=$(readlink -f $0); # Mutterprogramm
. ${MUPR%/*}/bul1.sh # LINEINS=linux1, buhost festlegen
. ${MUPR%/*}/bugem.sh # commandline-Parameter, $ZL aus commandline, $qssh, $zssh festlegen
wirt=$buhost;
. ${MUPR%/*}/virtnamen.sh # legt aus $wirt fest: $gpc, $gast, $tush
if [ "${gpc##/}" ]; then # auf linux3 gibts keinen virtuellen Server
  ot=/opt/turbomed;
  echo Benenne /$ot/lauf zu /$ot/lau um und warte 80 Sekunden
  ausf "$tush 'mv /$ot/lauf /$ot/lau  2>/dev/null||touch /$ot/lau'&&sleep 80s";
  echo  Starte den virtuellen Server Win10 durch
  VBoxManage controlvm Win10 poweroff; VBoxManage startvm Win10 --type headless;
  echo Benenne /$ot/lau wieder zu /$ot/lauf um
  mv /$ot/lau /$ot/lauf 2>/dev/null||touch /$ot/lauf; # zurückbenennen, damit Turbomed wieder starten kann
else
  echo "laut virtnamen.sh kein virtueller Server hier"
fi;
echo Fertig!
