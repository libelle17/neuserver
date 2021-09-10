#!/bin/zsh
# soll alle sehr relevanten Datenen kopieren, fuer z.B. halbstündlichen Gebrauch
MUPR=$(readlink -f $0); # Mutterprogramm
. ${MUPR%/*}/bugem.sh
for Vz in PraxisDB StammDB DruckDB Dictionary; do
 wz="opt/turbomed"
 kopiermt "$wz/$Vz" "$wz" "" "$OBDEL"
done;
Dt=DATA; 
mountpoint -q /$Dt || mount /$Dt;
ssh $ANDERER mountpoint -q /$Dt 2>/dev/null || ssh $ANDERER mount /$Dt;
if mountpoint -q /$Dt && ssh $ANDERER mountpoint -q /$Dt 2>/dev/null; then
 kopiermt "$Dt/turbomed" "$Dt/" "" "$OBDEL"
fi;
Pt=Patientendokumente
kopiermt "$Dt/$Pt/eingelesen" "$Dt/$Pt/" "" "$OBDEL"
