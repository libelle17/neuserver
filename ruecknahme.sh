#!/bin/bash
# ruecknahme.sh - Rueckgabe der Netz-Identitaet nach Reparatur von linux1:
# Gegenstueck zu uebernahme.sh. Holt die waehrend der Uebernahme entstandenen
# Datenaenderungen vom Reserveserver zurueck auf linux1 und gibt dem
# Reserveserver anschliessend seine eigene Identitaet zurueck.
#
# Commit-Text (Ersteinfuehrung dieses Skripts):
#   ruecknahme.sh: Reaktivierung von linux1 nach Reparatur, Gegenstueck zu uebernahme.sh
#
#   Holt per "bulinux.sh -u -e -f <reserveserver>" die waehrend der
#   Uebernahmezeit auf dem Reserveserver entstandenen Datenaenderungen
#   (Konfiguration, Windows-Freigaben, /DATA bzw. /DATA/DATA, MariaDB) auf
#   das reparierte linux1 zurueck und gibt dem Reserveserver danach seine
#   eigene Identitaet zurueck (Hostname, IP-Alias, Samba-Abschaltung,
#   Samba-[daten]-Pfad).
#
# Aufruf (als root AUF DEM REPARIERTEN LINUX1):
#   ruecknahme.sh <reserveserver> [-e] [-f] [-v]
#
#   <reserveserver>  Hostname des Servers, der die Praxis zwischenzeitlich
#                    vertreten hat (z.B. linux0 oder linux7) - unter diesem,
#                    stets ueber DNS/hosts erreichbaren Namen wird er
#                    angesprochen, unabhaengig von der geliehenen Identitaet.
#   -e|-echt   echter Lauf (ohne: nur Anzeige/Simulation, es wird nichts veraendert)
#   -f|-force  ueberspringt die Rueckfrage (fuer nicht-interaktive Aufrufe)
#   -v|-verbose ausfuehrlichere Ausgabe (an bulinux.sh durchgereicht)
#
# Beispiel:
#   cd /root/bin && ./ruecknahme.sh linux0 -e -f
#
# Was das Skript tut:
#   1. Prueft, ob <reserveserver> erreichbar ist
#   2. Fragt (falls -e ohne -f) interaktiv nach, bevor etwas veraendert wird
#      (mit dem Hinweis auf die kurze Praxis-Unterbrechung durch Schritt 3)
#   3. Stoppt Samba auf dem Reserveserver, BEVOR irgendetwas kopiert wird -
#      damit waehrend der Rueckholung keine neuen Datei-Aenderungen entstehen
#      (bewegliches Ziel) und die Praxis-Bedienung dort sauber endet statt
#      einfach unter dem laufenden Betrieb weggezogen zu werden. MariaDB
#      bleibt bewusst noch aktiv, s. Schritt 4b.
#   3b. Sichert linux1s AKTUELLEN (noch ungesyncten) Datenbankstand per
#      mariadb-dump nach /DATA/sql/vor_ruecknahme_<Zeitstempel>/ (Rechte
#      700/600), BEVOR er gleich ueberschrieben wird. Noetig, weil
#      mariadb-dump/Import beim Rueckholen die Datenbank immer komplett
#      konsistent durch den Stand von $reserveserver ersetzt (kein Zeilen-
#      Merge) - rein lokale, nie gesicherte Aenderungen auf linux1 (z.B. kurz
#      vor dessen Ausfall) wuerden sonst kommentarlos verloren gehen. Dieser
#      Dump ist die einzige Moeglichkeit, so etwas danach manuell zu retten.
#   4. Holt per bulinux.sh -u -e -f <reserveserver> alle Datenaenderungen
#      (Konfig, Windows-Freigaben, DATA, MariaDB) vom Reserveserver zurueck
#      auf dieses (lokale) linux1 - MariaDB dort ist zu diesem Zeitpunkt noch
#      aktiv (s. Schritt 3), das brauchen SHOW DATABASES/mariadb-dump.
#      Bricht bei Fehlern ab, BEVOR dem Reserveserver die Identitaet
#      entzogen wird - sonst waeren zwischenzeitliche Aenderungen ggf.
#      verloren.
#   4b. Erst wenn Schritt 4 fehlerfrei war: stoppt MariaDB auf dem
#      Reserveserver (im Ruhezustand dort nicht benoetigt).
#   5. Entfernt auf dem Reserveserver die
#      waehrend der Uebernahme geliehene IP (per NetworkManager + ip addr del),
#      setzt dessen Hostnamen zurueck auf <reserveserver>, stellt eine evtl.
#      von uebernahme.sh gesicherte smb.conf wieder her und deaktiviert Samba
#      dort dauerhaft (Schutzgedanke wie in los.sh/uebernahme.sh - im
#      Ruhezustand bleibt Samba auf den Reserveservern aus).
#
# WICHTIG (Stand 11.07.2026): Eine Analyse der bulinux.sh-Versionsgeschichte
# (git log) zeigte, dass die -u-Funktion erst am 21.05.2026 eingefuehrt und
# am 24.05.2026 mehrfach nachgebessert wurde (u.a. ein versehentlicher
# Revert um 18:40 Uhr, der um 18:53 Uhr wieder rueckgaengig gemacht wurde) -
# das duerfte die Erinnerung an fruehere Fehlschlaege mit "-u" erklaeren. Die
# Kernlogik (Quelle/Ziel-Tausch, DtZ-Neuberechnung) wurde am 11.07.2026 per
# Simulation verifiziert und ist korrekt. Ausserdem stellte sich bei der
# Analyse eines realistischen Szenarios (auf linux1 UND Reserveserver wird
# zwischen den Backups unabhaengig voneinander weitergearbeitet) heraus, dass
# der zwischenzeitlich fuer -u genutzte dateibasierte MariaDB-Datadir-Kopierweg
# selbst bei gestoppter Quelle einen inkonsistenten Mischzustand ueber mehrere
# Tabellen hinweg erzeugen konnte (rsync -u ueberspringt neuere Zieldateien
# pro Datei einzeln, was bei InnoDB nichts Verlaessliches ueber den
# logischen Datenstand aussagt). Deshalb nutzt bulinux.sh seit demselben Tag
# fuer die Datenbank immer den mariadb-dump/Import-Weg (konsistent, aber ohne
# Zeilen-Merge) - Schritt 3b faengt den dadurch moeglichen Verlust rein
# lokaler linux1-Aenderungen ab.
#
# WICHTIG: Dieses Skript geht NICHT davon aus, dass linux1 seine eigene
# IP/seinen eigenen Hostnamen verloren hat - es wird davon ausgegangen, dass
# das reparierte linux1 bereits unter seiner echten Identitaet laeuft. Die
# geliehene IP existiert nur noch als Zusatzadresse auf dem Reserveserver und
# wird hier entfernt, um einen Adresskonflikt zu vermeiden.

set -u
MUPR=$(readlink -f "$0")
MDIR=$(dirname "$MUPR")
# Farbcodes bewusst lokal definiert statt bugem.sh zu sourcen, s. Begruendung
# in uebernahme.sh (bugem.sh setzt eigene Kontextvariablen unter "set -u"
# voraus und hat Nebenwirkungen wie chown/chmod auf /root/.ssh).
blau="\033[1;34m";
dblau="\033[0;34;1;47m";
rot="\033[1;31m";
gruen="\033[0;32m";
reset="\033[0m";

reserveserver=""
obecht=
obforce=
verb=

while [ $# -gt 0 ]; do
  case "$1" in
    -e|-echt) obecht=1;;
    -f|-force) obforce=1;;
    -v|-verbose) verb=1;;
    -h|-hilfe|-help|--help)
      printf "Aufruf: %s <reserveserver> [-e] [-f] [-v]\n" "$(basename "$0")"
      printf "  -e  echter Lauf (ohne: nur Simulation/Anzeige)\n"
      printf "  -f  ueberspringt die Rueckfrage\n"
      printf "  -v  ausfuehrliche Ausgabe\n"
      printf "Beispiel: %s linux0 -e -f\n" "$(basename "$0")"
      exit 0;;
    -*) printf "${rot}Unbekannte Option: %s${reset}\n" "$1"; exit 1;;
    *)
      if [ -z "$reserveserver" ]; then reserveserver="$1";
      else printf "${rot}Zu viele Argumente: %s${reset}\n" "$1"; exit 1;
      fi;;
  esac
  shift
done

if [ -z "$reserveserver" ]; then
  printf "${rot}Aufruf: %s <reserveserver> [-e] [-f] [-v]${reset}\n" "$(basename "$0")"
  printf "Beispiel: %s linux0 -e -f\n" "$(basename "$0")"
  exit 1
fi

jetzt=$(hostname -s 2>/dev/null || hostname)
printf "${dblau}ruecknahme${reset}(): dieser Rechner (${blau}%s${reset}) holt Aenderungen von ${blau}%s${reset} zurueck und gibt ihm danach seine Identitaet zurueck\n" "$jetzt" "$reserveserver"
if [ -z "$obecht" ]; then
  printf "${rot}Simulationsmodus${reset} (kein -e angegeben) - es wird nichts veraendert, nur angezeigt.\n"
fi
case "$jetzt" in
  linux1|linux1.*) ;;
  *) printf "${rot}Hinweis:${reset} dieser Rechner heisst aktuell '%s', nicht linux1 - bitte pruefen, ob dieses Skript wirklich hier laufen soll.\n" "$jetzt";;
esac

# 1) Erreichbarkeit pruefen
printf "${dblau}Erreichbarkeitscheck${reset} von %s ...\n" "$reserveserver"
if ! ssh -o BatchMode=yes -o ConnectTimeout=5 "$reserveserver" 'true' 2>/dev/null; then
  printf "${rot}%s per SSH nicht erreichbar - breche ab.${reset}\n" "$reserveserver"
  exit 1
fi
printf "${gruen}%s ist erreichbar.${reset}\n" "$reserveserver"

# 2) Rueckfrage (nur bei -e ohne -f)
if [ -n "$obecht" ] && [ -z "$obforce" ]; then
  printf "${rot}%s wird jetzt gestoppt (Samba+MariaDB), Daten werden zurueckgeholt, danach verliert %s die geliehene Identitaet. Kurze Praxis-Unterbrechung waehrend der Rueckholung. Fortfahren? (ja/NEIN): ${reset}" "$reserveserver" "$reserveserver"
  read -r antwort
  [ "$antwort" = "ja" ] || { printf "Abgebrochen.\n"; exit 1; }
fi

# 3) Reserveserver VOR der Rueckholung stoppen (nur Samba): verhindert, dass
# waehrend der Rueckholung noch neue Datei-Aenderungen auf dem Reserveserver
# entstehen (bewegliches Ziel) und beendet die Praxis-Bedienung dort sauber,
# statt sie einfach unter dem laufenden Betrieb wegzuziehen.
# Bugfix 11.07.2026: MariaDB bleibt hier bewusst NOCH aktiv (anders als
# frueher) - Schritt 4 braucht per SSH erreichbares MariaDB auf der Quelle
# fuer "SHOW DATABASES"/mariadb-dump; Konsistenz liefert --single-transaction
# ohnehin schon, ein Stop hier fuehrte nur dazu, dass bulinux.sh -u
# "Keine Datenbanken auf Quelle gefunden" meldete und die DB-Ruecknahme
# stillschweigend ausfiel (bei einem echten Testlauf am 11.07.2026 entdeckt).
# MariaDB wird stattdessen erst nach erfolgreicher Ruecknahme in Schritt 4b
# gestoppt.
printf "${dblau}Reserveserver stoppen${reset}: Samba auf %s (kein bewegliches Ziel waehrend der Rueckholung; MariaDB bleibt bis nach der Datenruecknahme aktiv)\n" "$reserveserver"
if [ -n "$obecht" ]; then
  ssh "$reserveserver" "systemctl stop smb 2>/dev/null; systemctl stop smbd 2>/dev/null; systemctl stop nmb 2>/dev/null; systemctl stop nmbd 2>/dev/null";
  printf "${gruen}%s gestoppt.${reset}\n" "$reserveserver";
else
  printf "Simulation: auf %s systemctl stop smb nmb\n" "$reserveserver";
fi

# 3b) Sicherungsdump von linux1s AKTUELLEM (noch ungesyncten) Datenbankstand,
# BEVOR bulinux.sh -u ihn gleich unwiderruflich ueberschreibt. mariadb-dump/
# Import ersetzt beim Rueckholen IMMER die komplette Datenbank konsistent
# durch den Stand von $reserveserver (kein Zeilen-Merge moeglich) - falls auf
# linux1 nach dem letzten Backup zu $reserveserver noch produktiv
# weitergearbeitet wurde (z.B. kurz vor dessen Ausfall), gehen solche
# Aenderungen sonst kommentarlos verloren. Dieser Dump ist die einzige
# Moeglichkeit, so etwas danach noch manuell zu retten. Enthaelt ggf.
# Patientendaten - deshalb strikte Rechte (700/600) und niemals Inhalt in
# Log-/Bildschirmausgabe.
_re_dumpdir="/DATA/sql/vor_ruecknahme_$(date +%Y%m%d_%H%M%S)";
printf "${dblau}Sicherungsdump${reset} von linux1s aktuellem Datenbankstand nach %s\n" "$_re_dumpdir"
if [ -n "$obecht" ]; then
  mkdir -p "$_re_dumpdir" && chmod 700 "$_re_dumpdir";
  _re_dbs=$(mariadb --defaults-extra-file=/root/.mysqlrpwd -BN -e "SHOW DATABASES" 2>/dev/null | grep -vE '^(information_schema|performance_schema|sys|mysql)$');
  for _re_db in $_re_dbs; do
    mariadb-dump --defaults-extra-file=/root/.mysqlrpwd --default-character-set=utf8mb4 -c -K \
      --routines --events --triggers --single-transaction --skip-lock-tables --skip-add-locks --quick \
      "$_re_db" > "$_re_dumpdir/$_re_db.sql" 2>>"$_re_dumpdir/dump.log";
  done;
  chmod 600 "$_re_dumpdir"/*.sql "$_re_dumpdir"/dump.log 2>/dev/null;
  printf "${gruen}Sicherungsdump abgeschlossen: %s${reset} (%s Datenbanken)\n" "$_re_dumpdir" "$(printf '%s\n' $_re_dbs | wc -l)";
else
  printf "Simulation: mariadb-dump aller lokalen Datenbanken nach %s\n" "$_re_dumpdir";
fi

# 4) Datenrueckholung: bulinux.sh -u zieht ALLES (Konfig, Windows-Freigaben,
# DATA, MariaDB) von $reserveserver zurueck auf dieses lokale linux1.
# -f (Vollabgleich) bewusst immer gesetzt, unabhaengig vom eigenen -f dieses
# Skripts (der hier steuert nur die Rueckfrage) - nach einer Uebernahmezeit
# soll die Rueckholung vollstaendig sein, nicht nur inkrementell.
printf "${dblau}Datenrueckholung${reset}: bulinux.sh -u -e -f %s\n" "$reserveserver"
if [ -n "$obecht" ]; then
  "$MDIR/bulinux.sh" -u -e -f ${verb:+-v} "$reserveserver";
  bu_ret=$?;
  if [ "$bu_ret" -ne 0 ]; then
    printf "${rot}bulinux.sh -u meldete einen Fehler (Exitcode %s) - breche ab, OHNE %s die Identitaet zu entziehen.${reset}\n" "$bu_ret" "$reserveserver";
    printf "Bitte Log pruefen und erst nach erfolgreicher Rueckholung erneut versuchen.\n";
    exit 1;
  fi;
  printf "${gruen}Datenrueckholung abgeschlossen.${reset}\n";
else
  printf "Simulation: %s/bulinux.sh -u -e -f %s\n" "$MDIR" "$reserveserver";
fi

# 4b) Erst JETZT, nach erfolgreicher Datenruecknahme, MariaDB auf dem
# Reserveserver stoppen (s. Begruendung/Bugfix-Kommentar bei Schritt 3) -
# wird dort im Ruhezustand nicht gebraucht.
printf "${dblau}MariaDB stoppen${reset}: auf %s (nach erfolgreicher Ruecknahme nicht mehr benoetigt)\n" "$reserveserver"
if [ -n "$obecht" ]; then
  ssh "$reserveserver" "systemctl stop mariadb 2>/dev/null";
  printf "${gruen}MariaDB auf %s gestoppt.${reset}\n" "$reserveserver";
else
  printf "Simulation: auf %s systemctl stop mariadb\n" "$reserveserver";
fi

# 5) Reserveserver: geliehene IP entfernen, Hostname zurueck, Samba dauerhaft abschalten
meineip=$(ip route get 1.1.1.1 2>/dev/null | awk '{for(i=1;i<=NF;i++) if($i=="src") print $(i+1)}');
printf "${dblau}Identitaet zurueckgeben${reset}: %s (geliehene IP: %s)\n" "$reserveserver" "${meineip:-unbekannt}";

if [ -n "$obecht" ]; then
  if [ -n "$meineip" ]; then
    _re_con=$(ssh "$reserveserver" "nmcli -t -f NAME,DEVICE con show --active 2>/dev/null" | head -1 | cut -d: -f1);
    if [ -n "$_re_con" ]; then
      printf "${blau}nmcli connection modify \"%s\" -ipv4.addresses %s/24 (auf %s)${reset}\n" "$_re_con" "$meineip" "$reserveserver";
      ssh "$reserveserver" "nmcli connection modify '$_re_con' -ipv4.addresses '$meineip/24' 2>/dev/null; nmcli connection up '$_re_con' >/dev/null 2>&1";
    fi;
    _re_iface=$(ssh "$reserveserver" "ip route get 1.1.1.1 2>/dev/null" | awk '{for(i=1;i<=NF;i++) if($i=="dev") print $(i+1)}');
    [ -n "$_re_iface" ] && ssh "$reserveserver" "ip addr del '$meineip/24' dev '$_re_iface'" 2>/dev/null;
  else
    printf "${rot}Konnte eigene IP nicht ermitteln - IP-Alias auf %s bitte manuell pruefen/entfernen.${reset}\n" "$reserveserver";
  fi;

  printf "${blau}hostnamectl set-hostname %s (auf %s)${reset}\n" "$reserveserver" "$reserveserver";
  ssh "$reserveserver" "hostnamectl set-hostname '$reserveserver'";

  printf "${blau}smb.conf-Sicherung von uebernahme.sh wiederherstellen, falls vorhanden${reset}\n";
  ssh "$reserveserver" '
    _b=$(ls -t /etc/samba/smb.conf.vor_uebernahme_* 2>/dev/null | head -1);
    if [ -n "$_b" ]; then
      cp -a "$_b" /etc/samba/smb.conf && echo "wiederhergestellt: $_b";
    else
      echo "keine smb.conf-Sicherung von uebernahme.sh gefunden - unveraendert gelassen";
    fi
  ';

  printf "${blau}Samba auf %s dauerhaft deaktivieren${reset} (war in Schritt 3 schon gestoppt)\n" "$reserveserver";
  ssh "$reserveserver" "systemctl disable --now smb 2>/dev/null; systemctl disable --now smbd 2>/dev/null; systemctl disable --now nmb 2>/dev/null; systemctl disable --now nmbd 2>/dev/null";
else
  printf "Simulation: auf %s IP-Alias %s entfernen, hostnamectl set-hostname %s, smb.conf-Backup wiederherstellen, Samba abschalten\n" "$reserveserver" "${meineip:-?}" "$reserveserver";
fi

printf "\n${dblau}Fertig.${reset}";
[ -z "$obecht" ] && printf " (Simulation - fuer den echten Lauf: -e anhaengen)";
printf "\nNaechste Schritte pruefen:\n";
printf "  - MariaDB-Aktualitaet verifizieren: ${blau}bulinux.sh -dberg %s${reset}\n" "$reserveserver";
printf "  - Samba/Freigabenzugriff auf linux1 (\\\\\\\\linux1\\\\daten) testen\n";
printf "  - %s sollte Samba wieder abgeschaltet haben (Ransomware-Schutz, s. los.sh)\n" "$reserveserver";
printf "  - Crontab auf %s bei Bedarf pruefen (bulinux.sh haelt sie i.d.R. automatisch synchron)\n" "$reserveserver";
