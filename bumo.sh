#!/bin/bash
# bumo.sh - Mittagssicherung: inkrementelles Kopieren (kopiermt_delta, kein
# --delete) von /DATA/Patientendokumente, 2x taeglich per wecklauf.sh
# (Mittag-Fenster) auf linux0/linux7. Loeschungen auf den Zielen werden
# bewusst NICHT hier nachgezogen (s. Analyse-Kommentar unten zu den
# rsync-OOM-Vorfaellen 27.5.-1.6.2026), sondern einmal naechtlich von
# bunacht.sh - das haelt bumo.sh schnell und speicherschonend.
#
# Zwei Aufrufarten (wie bulinux.sh):
#   - auf $LINEINS (linux1) selbst: pusht auf alle Hosts aus $ziele (Default
#     "0 7" = linux0/linux7), per Push-Schleife weiter unten.
#   - direkt auf einem Zielrechner aufgerufen (buhost != linux1): zieht
#     stattdessen einmalig von $QL (=linux1) auf sich selbst (Pull).
#
# Parameter (per bugem.sh commandline() geparst, source davor beachten):
#   -e            echter Lauf (ohne: nur Simulation/Anzeige)
#   -z "<nummern>" Zielrechner-Nummern statt Default "0 7" (z.B. -z "0")
#   SD / SD=/Pfad Nur Schutzdateien verteilen, kein echter Datentransfer,
#                 kein dopweg.sh-Aufruf, kein Backup-Status-Heartbeat
#   -v            gespraechigere Ausgabe
# (weitere von bugem.sh geparste Flags wie -f/-dt1/-db wirken sich auf
# bumo.sh nicht aus, da es immer nur den einen Patientendokumente-Pfad kopiert)
MUPR=$(readlink -f $0); # Mutterprogramm
. ${MUPR%/*}/bul1.sh # LINEINS=linux1, buhost=linux1 festlegen
ziele="0 7"; # Vorgaben für Ziel-Servernummern: linux1ur, linux3 usw., abwandelbar durch Befehlszeilenparameter -z
ZL=; # dann werden die cifs-Laufwerke verwendet
# vom Zielrechner selbst aufgerufen (buhost != LINEINS)? Dann wie bulinux.sh/
# butm.sh statt zu pushen von LINEINS pullen (QL gesetzt, ZL bleibt leer = lokal):
[ "$buhost"/ = "$LINEINS"/ ]&&ZL=||QL=$LINEINS;
. ${MUPR%/*}/bugem.sh # commandline-Parameter, $ZL aus commandline, $qssh, $zssh festlegen
. ${MUPR%/*}/bustate.sh # bustate_changed()/kopiermt_delta() für inkrementelles Kopieren, s. Analyse unten
# nurdrei=1;
# nurzweidrei=1;
[ "$ZL" ]&&{ printf "Ziel \"$blau$ZL$reset\" wird zurückgesetzt.\n"; ZL=;}
if [ "$buhost"/ = "$LINEINS"/ ]; then
  # Normalbetrieb: von hier ($LINEINS) aus auf $ziele pushen.
  # Notfallbetrieb: eigenes, gerade verlassenes Ziel aus ziele herausfiltern
  # (s. Kommentar in bul1.sh) - sonst wuerde waehrend einer geliehenen
  # Identitaet versucht, /DATA/Patientendokumente auf sich selbst zu sichern.
  if [ "$EIGENHOST" != "$buhost" ]; then
    _neuziele=;
    for _z in $ziele; do [ "$_z" != "$EIGENNR" ] && _neuziele="$_neuziele $_z"; done;
    ziele=${_neuziele# };
    printf "${rot}Notfallbetrieb erkannt (eigentlich $EIGENHOST statt $buhost) - Sicherungsziel $EIGENNR aus ziele entfernt (keine Sicherung auf sich selbst).${reset}\n";
  fi;
  # nicht im SD-Modus: dopweg.sh bereinigt echte Fehlimporte, hat nichts mit
  # der reinen Schutzdatei-Verteilung zu tun
  [ -z "$sdneu" ] && /root/bin/dopweg.sh ${obecht:+-e}
  # Analyse (Auswertung /var/mail/root, Stand 8.7.2026):
  # bumo.sh lief bislang 2x täglich (14:20/19:20 Uhr, s. crontab) mit vollem
  # kopiermt(...,--delete) über den kompletten Patientendokumente-Baum. An
  # mehreren Tagen (u.a. 27./28./29./30.5., 1.6.) quittierte das zugehörige
  # rsync das mit "error allocating core memory buffers" (Speicher reicht
  # nicht), gefolgt von zehntausenden Folgefehlern ("mkdir/rename/mkstemp ...
  # No such file or directory").
  # kopiermt_delta() (bugem.sh) würde per bustate_changed() nur seit dem
  # letzten Lauf geänderte Dateien übertragen - fällt aber bei "--delete"
  # automatisch auf die alte volle kopiermt() zurück, weil bustate.sh
  # Löschungen nicht erfasst (Fallback-Logik in kopiermt_delta()). Deshalb
  # hier: --delete NICHT mehr in den beiden Tages-Läufen von bumo.sh, dafür
  # echtes inkrementelles Kopieren (schnell, speicherschonend). Das endgültige
  # Nachziehen von Löschungen bleibt bei bunacht.sh (einmal nächtlich, s. dort).
  wirt=$buhost;
  for ziel in $ziele; do
    ZL=linux$ziel;
    ZmD=$ZL:;
    if [ $ziel -eq 7 ]; then vz=DATA\/DATA;else vz=DATA; fi;
#    kopiermt_delta "/DATA/Patientendokumente/dok/" "/$vz/Patientendokumente/dok/" "" "" "" ""; # ohne --iconv
#    kopiermt_delta "/DATA/Patientendokumente/eingelesen/" "/$vz/Patientendokumente/eingelesen/" "" "" "" ""; # ohne --iconv
    kopiermt_delta "/DATA/Patientendokumente/" "/$vz/Patientendokumente/" "" "" "" ""; # kein --delete mehr (s. Analyse oben); ohne --iconv
    _bs_ret=$?; [ "$obecht" ] && [ -z "$sdneu" ] && backupstatus "$([ $_bs_ret -eq 0 ] && echo OK || echo FEHLER)"; # nur bei echtem Lauf, nicht bei Trockenlauf-Tests
#    ZL=;
#    ZmD=;
#    mount /mnt/wser/indamed
#    kopiermt "/mnt/wser/indamed/" "/wrz/indamed/" "" "$obOBDEL" "" "";
    EXGES="";
  done;
else
  # Vom Zielrechner selbst aufgerufen (z.B. per ssh direkt auf linux0/linux7
  # ausgeführt): einmalig von $QL (=$LINEINS) auf diesen lokalen Rechner
  # ziehen, statt der obigen Push-Schleife über $ziele. $vz kommt aus
  # $DATAZIEL (bul1.sh, rechnerabhängig nach $buhost) statt aus der
  # ziel-Nummer. dopweg.sh bereinigt Fehlimporte an der Quelle (Turbomed
  # importiert nur dort) - deshalb per $qssh (normaler, uneingeschränkter
  # Root-Zugriff auf $LINEINS, s. bugem.sh/_backup_sshopts) auf $QL ausführen:
  printf "${blau}Vom Zielrechner aus aufgerufen ($buhost) - ziehe von ${QL}.${reset}\n";
  machssh; # setzt $qssh/$zssh aus $QL/$ZL (sonst leer, da sonst nur lazy in kopiermt* gesetzt)
  # nicht im SD-Modus, s. Kommentar im Normalbetrieb-Zweig oben
  [ -z "$sdneu" ] && eval "$qssh '/root/bin/dopweg.sh ${obecht:+-e}'";
  wirt=$QL;
  vz=$DATAZIEL;
  kopiermt_delta "/DATA/Patientendokumente/" "/$vz/Patientendokumente/" "" "" "" ""; # ohne --iconv
  _bs_ret=$?; [ "$obecht" ] && [ -z "$sdneu" ] && backupstatus "$([ $_bs_ret -eq 0 ] && echo OK || echo FEHLER)"; # nur bei echtem Lauf, nicht bei Trockenlauf-Tests
  EXGES="";
fi;
