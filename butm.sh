#!/bin/zsh
# soll alle sehr relevanten Datenen kopieren, fuer z.B. halbstündlichen Gebrauch
# mountvirt.sh -a
MUPR=$(readlink -f $0); # Mutterprogramm
. ${MUPR%/*}/bugem.sh
wirt=$ZoD;
. ${MUPR%/*}/virtnamen.sh # braucht $wirt
USB=1;
altZL=$ZL; ZL=;
altEXFEST=$EXFEST;EXFEST=;
for Vz in PraxisDB StammDB DruckDB Dictionary Vorlagen Formulare KVDT Dokumente Daten labor LaborStaber; do
  case $Vz in PraxisDB|StammDB|DruckDB)testdt="objects.dat";;Dictionary)testdt="_objects.dat";;*)testdt=;;esac;
  case $Vz in Vorlagen|Formulare|KVDT|Dokumente|Daten|labor|LaborStaber)obOBDEL=;;*)obOBDEL=$OBDEL;;esac;
  [ -d /opt/turbomed/PraxisDB ]&&ur=opt||ur=mnt/virtwin;
  kopiermt "$ur/turbomed/$Vz" "mnt/$gpc/turbomed/" "" "$obOBDEL" "$testdt" "1800" 1; # ohne --iconv
#  [ "$ur" = opt ]&&{
#   kopiermt "$ur/turbomed/$Vz" "$ur/turbomed/" "" "$obOBDEL" "$testdt" "1800" 1; # ohne --iconv
#  }
done;
USB=;
ZL=$altZL;
EXFEST=$altEXFEST;
[ "$ZoD/" = "$HOSTK/" ]&&exit;

Dt=DATA; 
mountpoint -q /$Dt || mount /$Dt;
ssh $ANDERER mountpoint -q /$Dt 2>/dev/null || ssh $ANDERER mount /$Dt;
if mountpoint -q /$Dt && ssh $ANDERER mountpoint -q /$Dt 2>/dev/null; then
 kopiermt "$Dt/turbomed" "$Dt/" "" "$OBDEL"
fi;
Pt=Patientendokumente
kopiermt "$Dt/$Pt/eingelesen" "$Dt/$Pt/" "" "$OBDEL"
