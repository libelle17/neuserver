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
#   3. Holt per bulinux.sh -u -e -f <reserveserver> alle Datenaenderungen
#      (Konfig, Windows-Freigaben, DATA, MariaDB) vom Reserveserver zurueck
#      auf dieses (lokale) linux1. Bricht bei Fehlern ab, BEVOR dem
#      Reserveserver die Identitaet entzogen wird - sonst waeren
#      zwischenzeitliche Aenderungen ggf. verloren.
#   4. Erst wenn Schritt 3 fehlerfrei war: entfernt auf dem Reserveserver die
#      waehrend der Uebernahme geliehene IP (per NetworkManager + ip addr del),
#      setzt dessen Hostnamen zurueck auf <reserveserver>, stellt eine evtl.
#      von uebernahme.sh gesicherte smb.conf wieder her und schaltet dessen
#      Samba wieder ab (Schutzgedanke wie in los.sh/uebernahme.sh - im
#      Ruhezustand bleibt Samba auf den Reserveservern aus).
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
  printf "${rot}Es werden jetzt Daten von %s zurueckgeholt, danach verliert %s die geliehene Identitaet (Hostname/IP/Samba). Fortfahren? (ja/NEIN): ${reset}" "$reserveserver" "$reserveserver"
  read -r antwort
  [ "$antwort" = "ja" ] || { printf "Abgebrochen.\n"; exit 1; }
fi

# 3) Datenrueckholung: bulinux.sh -u zieht ALLES (Konfig, Windows-Freigaben,
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

# 4) Reserveserver: geliehene IP entfernen, Hostname zurueck, Samba abschalten
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

  printf "${blau}Samba auf %s abschalten${reset}\n" "$reserveserver";
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
