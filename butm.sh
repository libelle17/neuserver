#!/bin/bash
# dash geht nicht: --exclude={,abc/,def/} wirkt nicht
# soll alle sehr relevanten Datenen von aktiven Server linux1 auf die Reserveserver kopieren, fuer z.B. halbstündlichen Gebrauch
# wenn des das Verzeichnis /opt/turbomed/PraxisDB gibt, wird dieses für die Datenbank verwendet, sonst /amnt/virtwin/turbomed
# wird auch aus butint.sh mit -nv aufgerufen, wenn dieses mit -m ("mehr") aufgerufen wird
# das auf den Reserveservern verwendete Verzeichnis hängt davon ab, ob es auf linux1 /opt/turbomed/PraxisDB gibt
# mountvirt.sh -a
MUPR=$(readlink -f $0); # Mutterprogramm
. ${MUPR%/*}/bul1.sh # LINEINS=linux1, buhost aus hostname festlegen
[ "$buhost"/ = "$LINEINS"/ ]&&ZL=||QL=$LINEINS;
. ${MUPR%/*}/bugem.sh # commandline-Parameter, $ZL aus commandline, in obalt und kopiermt $qssh, $zssh festlegen
[ "$buhost"/ != "$LINEINS"/ -a "$ZL" ]&&{ printf "Ziel \"$blau$ZL$reset\" wird zurückgesetzt.\n"; ZL=;}
[ "$buhost"/ = "$LINEINS"/ -a -z "$ZL" ]&&{ printf "${rot}Kein Ziel angegeben. Breche ab$reset.\n";exit;}
# [ "$QL" ]&& pruefpc "$QL";
# [ "$ZL" ]&& pruefpc "$ZL";
wirt=${QL:-$buhost};
. ${MUPR%/*}/virtnamen.sh # legt aus $wirt fest: $gpc, $gast, $tush
g1=$gast;
l1gpc=$gpc; # Gast-PC von Linux1, also /virtwin
wirt=${ZL:-$buhost};
. ${MUPR%/*}/virtnamen.sh # legt aus $wirt fest: $gpc, $gast, $tush
rgpc=$gpc; # Gast-PC des Reserveservers
# hier wir tush nicht nicht wirt festgelegt, wie in virtnamen.sh, sondern nach buhost:
[ "$verb" ]&&{ printf "ZL: ${blau}$ZL$reset\n"; sleep 1;};
case $buhost in $LINEINS)tush="sh -c ";zish="ssh $ZL ";;*)tush="ssh $ZL ";zish="sh -c ";;esac

ot=opt/turbomed;
otP=/$ot/PraxisDB;
otr=/$ot/PraxisDB-res;
if eval "$tush 'test -d $otP'"; then # wenn es auf linux1 /opt/turbomed/PraxisDB gibt, 
    obvirt=;                                   # also nicht die virtuelle Installation verwendet wird
    Pr=PraxisDB;
    ausf "$zish '[ -d $otr -a ! -d $otP ]&& mv $otr $otP'" $blau; # umgekehrt
else
    obvirt=1; 
    Pr=PraxisDB-res;
    ausf "$zish '[ -d $otP -a ! -d $otr ]&& mv $otP $otr'" $blau; # dann ggf. auf dem Zielrechner die linux-Datenbank umbenennen
fi;
for iru in 1 2; do # interne Runde
  if test $iru = 1; then
    ur=$ot;  # kopiere das gesamte /opt/turbomed
    hin=$ot;
    offen=1;
  else  # iru = 2
    [ "$obvirt" ]||break;
    Pr=PraxisDB;
    ur=amnt/$l1gpc/turbomed; # kopiere das gesamte /amnt/virtwin/turbomed
    hin=amnt/$rgpc/turbomed;
    uQL=$QL;
    QL=;
    uZL=$ZL;
    ZL=; # dann werden die cifs-Laufwerke verwendet, alle auf selbem Server
    [ "$obkill" ]&&{ if mountpoint -q /$ur||[ $iru = 1 ];then # dann pruefen, ob objects.idx gesperrt ist
      if ! ssh administrator@$l1gpc cmd /c "(>>c:\turbomed\StammDB\objects.idx (call ) )&&exit||exit /b 1" 2>/dev/nul; then
       ausf "$tush 'mv /$ot/lauf /$ot/lau '&&sleep 80s";
      fi;
      if ! ssh administrator@$l1gpc cmd /c "(>>c:\turbomed\StammDB\objects.idx (call ) )&&exit||exit /b 1" 2>/dev/nul; then
        ausf "VBoxManage controlvm $g1 poweroff" $blau;
        ausf "VBoxManage startvm $g1 --type headless" $blau;
      fi;
    fi;};# dann killt der windows-task "Turbomed töten" turbomed
    if ssh administrator@$l1gpc cmd /c "(>>c:\turbomed\StammDB\objects.idx (call ) )&&exit||exit /b 1" 2>/dev/nul; then offen=1; else offen=; fi;
  fi;
  [ "$verb" ]&&printf "tush: ${blau}$obsh$reset\n";
  [ "$verb" ]&&printf "obvirt: ${blau}$obvirt$reset\n";
  [ "$verb" ]&&printf "offen: ${blau}$offen$reset\n";
  [ "$obforce" ]&&testdt=||testdt=$Pr/objects.dat;
  if [ "$offen" ]; then
   kopiermt "$ur/" "$hin" "" "$OBDEL" "$testdt" "1800" 1; # ohne --iconv
  fi;
  if test $iru = 2; then
    QL=$uQL;
    ZL=$uZL;
  fi;
  [ "$obnv" ]&&break; # dann keine iru 2
  [ "$gpc" ]||break; # auf linux3 gibts keinen virtuellen Server
done;
[ "$obkill" -a "$obvirt" ]&&{ mv /$ot/lau /$ot/lauf||touch /$ot/lauf;} # zurückbenennen, damit Turbomed wieder starten kann
Dt=DATA; 
Pt=Patientendokumente;
for zug in "$tush" "$zish"; do
  ausf "$zug 'mountpoint -q /$Dt 2>/dev/null||mount /$Dt'";
done;
ausf "$tush 'mountpoint -q /${Dt} 2>/dev/null'&&$zish 'mountpoint -q /${Dt} 2>/dev/null'"
if [ "$ret"/ = 0/ ]; then
  kopiermt "$Dt/turbomed" "$Dt/" "" "$OBDEL" "" "" 1
  kopiermt "$Dt/$Pt/eingelesen" "$Dt/$Pt/" "" "$OBDEL" "" "" 1
else
 printf $rot$Dt$reset kein Mountpoint, hier nichts kopiert!
fi;
# gutenacht;
[ "$verb" ]&&printf "\n${rot} ziemlich am Schluss von $MUPR$reset\n";
