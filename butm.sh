#!/bin/zsh
. /root/bin/bugem.sh
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
P=Patientendokumente
kopiermt "$Dt/$P/eingelesen" "$Dt/$P/" "" "$OBDEL"
