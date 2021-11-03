#!/bin/dash
# soll alle sehr relevanten Datenen von aktiven Server linux1 auf die Reserveserver kopieren, fuer z.B. halbstündlichen Gebrauch
# wenn des das Verzeichnis /opt/turbomed gibt, wird dieses für die Datenbank verwendet, sonst /mnt/virtwin/turbomed
# das auf den Reserveservern verwendete Verzeichnis hängt davon ab, ob es auf linux1 /opt/turbomed gibt
# mountvirt.sh -a
MUPR=$(readlink -f $0); # Mutterprogramm
. ${MUPR%/*}/bul1.sh # LINEINS=linux1, buhost aus hostname festlegen
[ "$buhost"/ = "$LINEINS"/ ]&&ZL=||QL=$LINEINS;
. ${MUPR%/*}/bugem.sh # commandline-Parameter, $ZL aus commandline, $qssh, $zssh festlegen
[ "$buhost"/ != "$LINEINS"/ -a "$ZL" ]&&{ printf "Ziel \"$blau$ZL$reset\" wird zurückgesetzt.\n"; ZL=;}
[ "$buhost"/ = "$LINEINS"/ -a -z "$ZL" ]&&{ printf "${rot}Kein Ziel angegeben. Breche ab$reset.\n";exit;}
wirt=${QL:-$buhost};
. ${MUPR%/*}/virtnamen.sh # legt aus $wirt fest: $gpc, $gast, $tush
l1gpc=$gpc; # Gast-PC von Linux1
wirt=${ZL:-$buhost};
. ${MUPR%/*}/virtnamen.sh # legt aus $wirt fest: $gpc, $gast, $tush
rgpc=$gpc; # Gast-PC des Reserveservers
# hier wir tush nicht nicht wirt festgelegt, wie in virtnamen.sh, sondern nach buhost:
case $buhost in $LINEINS)tush="sh -c ";;*)tush="ssh $buhost ";;esac

ot=opt/turbomed;
otP=/$ot/PraxisDB;
resD=PraxisDB-res;
res=$ot/$resD;
if eval "$tush 'test -d $otP'"; then # wenn es auf linux1 /opt/turbomed/PraxisDB gibt, 
    obvirt=;                                   # also nicht die virtuelle Installation verwendet wird
    Pr=PraxisDB;
    ausf "$zssh '[ -d $res -a ! -d $otP ]&& mv /$res $otP'" $blau; # umgekehrt
else
    obvirt=1; 
    Pr=PraxisDB-res;
    ausf "$zssh '[ -d $otP -a ! -d $res ]&& mv $otP /$res'" $blau; # dann ggf. auf dem Zielrechner die linux-Datenbank umbenennen
fi;
for iru in 1 2; do
  if test $iru = 1; then
    ur=$ot; 
    hin=$ot;
  else  # iru = 2
    [ "$obvirt" ]||break;
    Pr=PraxisDB;
    ur=mnt/$l1gpc/turbomed; 
    hin=mnt/$rgpc/turbomed;
    uQL=$QL;
    QL=;
    uZL=$ZL;
    ZL=; # dann werden die cifs-Laufwerke verwendet
    [ "$obkill" ]&&{ mv /$ur/lauf /$ur/lau&&sleep 1m;} # dann killt der windows-task "Turbomed töten" turbomed
  fi;
  [ "$verb" ]&&printf "tush: ${blau}$obsh$reset\n";
  [ "$verb" ]&&printf "obvirt: ${blau}$obvirt$reset\n";
  [ "$obforce" ]&&testdat=||testdat=$Pr/objects.dat;
  kopiermt "$ur/" "$hin" "" "$OBDEL" "$testdat" "1800" 1; # ohne --iconv
done;
[ "$obkill" -a "$obvirt" ]&&{ mv /$ur/lau /$ur/lauf||touch /$ur/lauf;} # zurückbenennen, damit Turbomed wieder starten kann
ZL=$altZL;
Dt=DATA; 
Pt=Patientendokumente;
for zug in "$qssh" "$zssh"; do
  ausf "$zug 'mountpoint -q /$Dt 2>/dev/null||mount /$Dt'";
done;
ausf "$qssh 'mountpoint -q /${Dt} 2>/dev/null'&&$zssh 'mountpoint -q /${Dt} 2>/dev/null'"
if [ "$ret"/ = 0/ ]; then
 QL=$uQL;
 ZL=$uZL;
 kopiermt "$Dt/turbomed" "$Dt/" "" "$OBDEL" "" "" 1
 kopiermt "$Dt/$Pt/eingelesen" "$Dt/$Pt/" "" "$OBDEL" "" "" 1
fi;
