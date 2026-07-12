#!/bin/bash
MUPR=$(readlink -f $0); # Mutterprogramm
. ${MUPR%/*}/bul1.sh # LINEINS=linux1, buhost=linux1 festlegen
ziele="0 7"; # Vorgaben für Ziel-Servernummern: linux1ur, linux3 usw., abwandelbar durch Befehlszeilenparameter -z
ZL=; # dann werden die cifs-Laufwerke verwendet
# vom Zielrechner selbst aufgerufen (buhost != LINEINS)? Dann wie bulinux.sh/
# butm.sh statt zu pushen von LINEINS pullen (QL gesetzt, ZL bleibt leer = lokal):
[ "$buhost"/ = "$LINEINS"/ ]&&ZL=||QL=$LINEINS;
. ${MUPR%/*}/bugem.sh # commandline-Parameter, $ZL aus commandline, $qssh, $zssh festlegen
# nurdrei=1;
# nurzweidrei=1;
[ "$ZL" ]&&{ printf "Ziel \"$blau$ZL$reset\" wird zurückgesetzt.\n"; ZL=;}
if [ "$buhost"/ = "$LINEINS"/ ]; then
  # Normalbetrieb: von hier ($LINEINS) aus auf $ziele pushen.
  # Notfallbetrieb: eigenes, gerade verlassenes Ziel aus ziele herausfiltern
  # (s. Kommentar in bul1.sh) - sonst wuerde waehrend einer geliehenen
  # Identitaet versucht, /DATA auf sich selbst zu sichern.
  if [ "$EIGENHOST" != "$buhost" ]; then
    _neuziele=;
    for _z in $ziele; do [ "$_z" != "$EIGENNR" ] && _neuziele="$_neuziele $_z"; done;
    ziele=${_neuziele# };
    printf "${rot}Notfallbetrieb erkannt (eigentlich $EIGENHOST statt $buhost) - Sicherungsziel $EIGENNR aus ziele entfernt (keine Sicherung auf sich selbst).${reset}\n";
  fi;
  # Analyse (Auswertung /var/mail/root, Stand 8.7.2026):
  # bunacht.sh ist bewusst der einzige verbliebene volle kopiermt(...,--delete)-
  # Lauf über den kompletten /DATA-Baum (einmal nächtlich, 02:20 Uhr laut
  # crontab) - bumo.sh (14:20/19:20 Uhr) wurde auf inkrementelles Kopieren ohne
  # --delete umgestellt, s. Kommentar dort; das tatsächliche Nachziehen von
  # Löschungen passiert deshalb jetzt nur noch hier, einmal pro Nacht.
  # Genau bei diesem Lauf traten am 29.5. und 31.5.2026 "error allocating core
  # memory buffers" (rsync-OOM) und in der Folge zehntausende "mkdir/rename/
  # mkstemp ... No such file or directory"-Fehler auf (43.708 bzw. 2.912
  # Stück). Auffällig: um 02:20 Uhr laufen laut crontab bereits mehrere andere,
  # nicht genicete Jobs auf demselben Host (u.a. mariadb-dump aller
  # Praxis-Datenbanken um 02:15, doppelteimporte.py und berein um 02:00,
  # copytoshz.sh um 02:15) - die Speicher-/IO-Konkurrenz in diesem enge
  # Zeitfenster ist ein naheliegender Mitverursacher der OOM-Fehler. Das lässt
  # sich innerhalb dieses Skripts nicht beheben; empfehlenswert wäre, die
  # Startzeiten dieser Cron-Jobs zu entzerren (z.B. bunacht.sh deutlich später
  # oder die DB-Dumps/Kopierjobs zeitlich vor 02:20 abzuschließen).
  obOBDEL=--delete
  wirt=$buhost;
  for ziel in $ziele; do
    ZL=linux$ziel;
    ZmD=$ZL:;
    if [ $ziel -eq 7 ]; then vz=DATA\/DATA;else vz=DATA; fi;
#    kopiermt "/DATA/Patientendokumente/dok" "/$vz/Patientendokumente/" "" "$obOBDEL" "" ""; # ohne --iconv
#    kopiermt "/DATA/Patientendokumente/eingelesen" "/$vz/Patientendokumente/" "" "$obOBDEL" "" ""; # ohne --iconv
    kopiermt "/DATA/" "/$vz/" "" "$obOBDEL" "" ""; # ohne --iconv
    _bs_ret=$?; [ "$obecht" ] && backupstatus "$([ $_bs_ret -eq 0 ] && echo OK || echo FEHLER)"; # nur bei echtem Lauf, nicht bei Trockenlauf-Tests
#    ZL=;
#    ZmD=;
#    mount /mnt/wser/indamed
#    kopiermt "/mnt/wser/indamed" "/wrz" "" "$obOBDEL" "" "";
    EXGES="";
  done;
else
  # Vom Zielrechner selbst aufgerufen: einmalig von $QL (=$LINEINS) auf
  # diesen lokalen Rechner ziehen (mit --delete, wie im Normalbetrieb),
  # $vz kommt aus $DATAZIEL (bul1.sh, rechnerabhängig nach $buhost).
  printf "${blau}Vom Zielrechner aus aufgerufen ($buhost) - ziehe von ${QL}.${reset}\n";
  obOBDEL=--delete
  wirt=$QL;
  vz=$DATAZIEL;
  kopiermt "/DATA/" "/$vz/" "" "$obOBDEL" "" ""; # ohne --iconv
  _bs_ret=$?; [ "$obecht" ] && backupstatus "$([ $_bs_ret -eq 0 ] && echo OK || echo FEHLER)"; # nur bei echtem Lauf, nicht bei Trockenlauf-Tests
  EXGES="";
fi;
