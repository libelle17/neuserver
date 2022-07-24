#/bin/bash
MUPR=$(readlink -f $0); # Mutterprogramm
. ${MUPR%/*}/bul1.sh # LINEINS=linux1, buhost festlegen
. ${MUPR%/*}/bugem.sh # commandline-Parameter, $ZL aus commandline, $qssh, $zssh festlegen
nr="0 3 7 8"; # Vorgaben für Ziel-Servernummern: linux0, linux3 usw., abwandelbar durch Befehlszeilenparameter -z
for nr in $ziele; do
  ZL=linux$nr;
  pruefpc $ZL;
  ssh $ZL dbauspacken;
  [ "$geweckt" ]&&ssh $ZL shutdown now;
  geweckt=;
done;
