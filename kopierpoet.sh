#!/bin/bash
# if test ! -z `cat /proc/mounts | cut -d' ' -f2,2 | grep "wres2"`; then
if `mountpoint -q /wres2`; then
for Uvz in "PraxisDB" "StammDB" "DruckDB" "Dictionary"; do 
 date
 echo Kopiere /opt/turbomed/${Uvz}:
 rm -rf /wres2/opt/turbomed/${Uvz}_4
 test -d /wres2/opt/turbomed/${Uvz}_3 && test -d /wres2/opt/turbomed/${Uvz}_4 && mv /wres2/opt/turbomed/${Uvz}_3 /wres2/opt/turbomed/${Uvz}_4
 test -d /wres2/opt/turbomed/${Uvz}_2 && test -d /wres2/opt/turbomed/${Uvz}_3 && mv /wres2/opt/turbomed/${Uvz}_2 /wres2/opt/turbomed/${Uvz}_3
 test -d /wres2/opt/turbomed/${Uvz}_1 && test -d /wres2/opt/turbomed/${Uvz}_2 && mv /wres2/opt/turbomed/${Uvz}_1 /wres2/opt/turbomed/${Uvz}_2
 test -d /wres2/opt/turbomed/${Uvz} && test -d /wres2/opt/turbomed/${Uvz}_1 &&  mv /wres2/opt/turbomed/${Uvz}   /wres2/opt/turbomed/${Uvz}_1
 rsync -avuz --delete /opt/turbomed/${Uvz}/ /wres2/opt/turbomed/${Uvz}
done
date
fi
