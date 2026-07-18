#!/bin/sh
# 7zdb.sh - sichert gezippte Datenbanken nach DBBack, zuletzt geändert 8.2.22
# Sicherung zwischen labor3 und linux1ur s. netzverbind. Aktualisiert (7z u)
# jeweils ein Archiv pro Datenquelle unter /DATA/DBBack mit Tages- bzw.
# Monatsdatum im Namen: AccuChek-Diaries, Diabass(Pro)/diabassdata,
# custobase.mdb+Ekg/Blutdruck/LuFu-Verzeichnisse (monatlich) und
# CareLink-Daten; setzt am Ende Eigentümer/Rechte für $SichV zurück.
# Aufruf ohne Parameter; erfordert gemountetes /DATA.
DBV=/DATA/Patientendokumente/Datenbanken/
DBV2="/DATA/eigene Dateien/"
SichV=/DATA/DBBack
AccuVerz=Diaries

cd "${DBV}AccuChek/$AccuVerz" && \
mountpoint -q "/DATA" && ionice -c3 nice -n19 7z u $SichV/${AccuVerz}_`date +\%Y\%m\%d` -r -x!"*.bak" -mx=9 -mtc=on -mmt=on
echo $PWD
cd -

cd "${DBV}" && \
mountpoint -q "/DATA" && ionice -c3 nice -n19 7z u $SichV/Diabass_`date +\%Y\%m\%d` DiabassPro Diabass diabassdata -r -mx=9 -mtc=on -mmt=on
echo $PWD
cd -

mountpoint -q "/DATA" && ionice -c3 nice -n19 7z u $SichV/custo_`date +\%Y\%m` ${DBV}custobase.mdb "${DBV}Ekg" "${DBV}Blutdruck" "${DBV}LuFu" "${DBV}ulufu" "${DBV}ublutdruck" -r -mx=9 -mtc=on -mmt=on

mountpoint -q "/DATA" && ionice -c3 nice -n19 7z u $SichV/carelink_`date +\%Y\%m\%d` ${DBV}CareLink\ Data -r -mx=9 -mtc=on -mmt=on

chmod 770 -R $SichV
chown sturm:praxis -R $SichV
