#/bin/bash
# budbaus.sh - lässt auf jedem Ziel-Linuxrechner (Vorgabe: linux0/3/7/8, per
# -z abwandelbar wie bei bumo.sh/bunacht.sh) per SSH dbauspacken.sh laufen
# (packt dort die MySQL/MariaDB-Tabellen für einen Umzug/ibdata1-Reset ein,
# s. dbeinpacken.sh/dbauspacken.sh) und fährt anschließend optional weitere,
# in einer Datei $gewdat gelistete PCs herunter (shutdown now per SSH) - $gewdat
# und die Hilfsfunktionen pruefpc()/ausf() kommen aus dem gesourcten bugem.sh.
# Aufruf: budbaus.sh [bugem.sh-Parameter, z.B. -z "<nummern>"].
MUPR=$(readlink -f $0); # Mutterprogramm
. ${MUPR%/*}/bul1.sh # LINEINS=linux1, buhost festlegen
. ${MUPR%/*}/bugem.sh # commandline-Parameter, $ZL aus commandline, $qssh, $zssh festlegen
nr="0 3 7 8"; # Vorgaben für Ziel-Servernummern: linux0, linux3 usw., abwandelbar durch Befehlszeilenparameter -z
for nr in $nr; do
  ZL=linux$nr;
  pruefpc $ZL;
  ausf "ssh $ZL dbauspacken.sh" $blau;
  [ "$gewdat" -a -f "$gewdat" ]&&for pc in $(cat $gewdat);do  
   ssh $pc shutdown now;
  done;
done;
