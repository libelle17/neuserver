#!/bin/bash
# uebernahme.sh - Notfall-Uebernahme der Netz-Identitaet eines ausgefallenen
# Servers durch einen Reserveserver (z.B. linux0 oder linux7 anstelle von
# linux1, s. los.sh "E) Einmalige Einrichtung" fuer die Reserveserver selbst).
#
# Commit-Text (Ersteinfuehrung dieses Skripts):
#   uebernahme.sh: Notfall-Skript fuer IP-/Hostnamen-Uebernahme durch Reserveserver
#
#   Ermoeglicht linux0/linux7, im Notfall (Ausfall von linux1) dessen Hostnamen
#   und IP-Adresse zu uebernehmen (NetworkManager + Gratuitous ARP, kein
#   Fritzbox-DHCP-Umbau noetig), Samba gezielt zu aktivieren, die auf linux7
#   abweichende /DATA-Pfadtiefe in der Samba-Freigabe zu korrigieren und
#   optional per TR-064 (.tr64cred) den Fritzbox-Hosteintrag umzubenennen.
#
# Aufruf (als root auf dem Reserveserver, der uebernehmen soll):
#   uebernahme.sh <alter-hostname> <alte-ip> [-e] [-f] [-v]
#
#   -e|-echt   echter Lauf (ohne: nur Anzeige/Simulation, es wird nichts veraendert)
#   -f|-force  ueberspringt Erreichbarkeitscheck und Rueckfrage (fuer Notfall-
#              Einzeiler per ssh, z.B. wenn der alte Server nachweislich zerstoert ist)
#   -v|-verbose ausfuehrlichere Ausgabe
#
# Beispiel im Notfall:
#   ssh linux0 "cd /root/bin && ./uebernahme.sh linux1 192.168.178.21 -e -f"
#
# Was das Skript tut:
#   1. Prueft (falls nicht -f), ob die Ziel-IP im LAN noch von einem anderen
#      Geraet beantwortet wird (Schutz vor Adresskonflikt, falls der alte
#      Server doch noch/wieder laeuft)
#   2. Fragt (falls -e ohne -f) interaktiv nach, bevor etwas veraendert wird
#   3. Setzt den Hostnamen auf <alter-hostname>
#   4. Prueft die eigene Crontab auf Plausibilitaet und installiert sie im
#      Zweifel aus /root/crontabakt neu (s. Warnung unten - Grund fuer diesen
#      Schritt). Wichtig, da die HOST=linux1-Bedingungen in der (auf allen drei
#      Servern identischen) Crontab erst nach dem Hostnamenwechsel greifen.
#   5. Vergibt <alte-ip> zusaetzlich zur eigenen Adresse - persistent ueber
#      NetworkManager (bleibt nach Reboot erhalten) und sofort per
#      "ip addr replace" plus Gratuitous ARP (arping -A), damit Switches/
#      Clients im LAN die neue Zuordnung ohne Wartezeit uebernehmen.
#      Bewusst KEINE Fritzbox-DHCP-Reservierung noetig - das funktioniert
#      auch wenn die Fritzbox gerade nicht erreichbar ist.
#   6. Korrigiert ggf. die auf linux7 historisch abweichende Pfadtiefe von
#      /DATA (dort liegen die gespiegelten Praxisdaten unter /DATA/DATA,
#      s. bul1.sh: DATAZIEL=DATA/DATA fuer linux7) in der Samba-[daten]-Freigabe,
#      erkannt anhand des tatsaechlichen Datenbestands, nicht am Hostnamen.
#   7. Startet Samba (smb/nmb). Das ist bewusst der EINZIGE Zeitpunkt, zu dem
#      das geschieht - im Ruhezustand bleibt Samba auf den Reserveservern aus
#      (Schutzgedanke gegen ein sich über Windows/wser ausbreitendes
#      Verschluesselungsvirus).
#   8. Weist nur auf die MariaDB-Aktualitaet hin (siehe unten) - promotet NICHTS
#      automatisch.
#   9. Best-effort per TR-064 (.tr64cred, Format wie fb.sh: "user:pass"): benennt
#      den Host-Eintrag in der Fritz!Box kosmetisch um. Fehler werden ignoriert,
#      da nicht alle Fritz!Box-Firmwares SetHostNameByIP unterstuetzen und dieser
#      Schritt fuer den eigentlichen Netzbetrieb nicht erforderlich ist.
#
# WICHTIG zu Schritt 4 (Stand 10.07.2026): Am 07.07.2026 wurde auf linux0/linux7
# durch eine kurze Stoerung waehrend des taeglichen bulinux.sh-Laufs (dessen
# var/spool-Sync die lebende Crontab von linux1 kopiert) die dortige Crontab
# auf wenige Zeilen verstuemmelt - unbemerkt, weil der Sync selbst fehlerfrei
# durchlief. Deshalb hier vor der eigentlichen Uebernahme sicherheitshalber
# gegenpruefen, statt sich auf ein "sieht aktiv aus" zu verlassen.
#
# WICHTIG zu Schritt 8 (Stand 09.07.2026): Der frueher hier vorgesehene
# automatische Weg, den auf /var/lib/mysql_1 rotierenden rsync-Schnappschuss
# (aus bulinux.sh, Zweig "gleiche Version") in die laufende Standby-Datenbank
# zu uebernehmen, wurde bewusst NICHT automatisiert und wird auch nicht mehr
# empfohlen: Ein Test am 09.07.2026 auf linux0 zeigte, dass dieser Schnappschuss
# per rsync gegen eine LAUFENDE, sich aendernde InnoDB-Datenbank auf linux1
# entsteht - ohne FLUSH TABLES WITH READ LOCK oder ein Hot-Backup-Tool
# (mariadb-backup) ist das nicht crash-konsistent. Die Uebernahme schlug mit
# "InnoDB: Tablespace ... was not found" fehl (mariadb startete nicht mehr).
# Fuer eine echte Aktualisierung der Standby-Datenbank bitte den logischen Weg
# verwenden (mariadb-dump --single-transaction | mariadb import, wie ihn
# bulinux.sh im Zweig "verschiedene Version" schon nutzt), z.B. manuell:
#   ssh linux1 "mariadb-dump --defaults-extra-file=/root/.mysqlrpwd \
#     --single-transaction --quick -c -K --routines --events --triggers \
#     --databases quelle" | mariadb --defaults-extra-file=/root/.mysqlrpwd --force
# und danach mit "bulinux.sh -dberg" verifizieren.

set -u
MUPR=$(readlink -f "$0")
MDIR=$(dirname "$MUPR")
# Farbcodes bewusst lokal definiert statt bugem.sh zu sourcen: bugem.sh setzt
# eigene Kontextvariablen (z.B. $QL) unter "set -u" voraus, verarbeitet "$@"
# selbst als bulinux.sh-Argumente und chownt/chmodt am Ende unbedingt
# /root/.ssh - alles fuer dieses eigenstaendige Skript unerwuenschte Kopplung.
blau="\033[1;34m";
dblau="\033[0;34;1;47m";
rot="\033[1;31m";
gruen="\033[0;32m";
reset="\033[0m";

alterhost=""
alteip=""
obecht=
obforce=
verb=

while [ $# -gt 0 ]; do
  case "$1" in
    -e|-echt) obecht=1;;
    -f|-force) obforce=1;;
    -v|-verbose) verb=1;;
    -h|-hilfe|-help|--help)
      printf "Aufruf: %s <alter-hostname> <alte-ip> [-e] [-f] [-v]\n" "$(basename "$0")"
      printf "  -e  echter Lauf (ohne: nur Simulation/Anzeige)\n"
      printf "  -f  ueberspringt Erreichbarkeitscheck und Rueckfrage (Notfall-Einzeiler)\n"
      printf "  -v  ausfuehrliche Ausgabe\n"
      printf "Beispiel: %s linux1 192.168.178.21 -e -f\n" "$(basename "$0")"
      exit 0;;
    -*) printf "${rot}Unbekannte Option: %s${reset}\n" "$1"; exit 1;;
    *)
      if [ -z "$alterhost" ]; then alterhost="$1";
      elif [ -z "$alteip" ]; then alteip="$1";
      else printf "${rot}Zu viele Argumente: %s${reset}\n" "$1"; exit 1;
      fi;;
  esac
  shift
done

if [ -z "$alterhost" ] || [ -z "$alteip" ]; then
  printf "${rot}Aufruf: %s <alter-hostname> <alte-ip> [-e] [-f] [-v]${reset}\n" "$(basename "$0")"
  printf "Beispiel: %s linux1 192.168.178.21 -e\n" "$(basename "$0")"
  exit 1
fi

jetzt=$(hostname -s 2>/dev/null || hostname)
printf "${dblau}uebernahme${reset}(): dieser Rechner (aktuell ${blau}%s${reset}) uebernimmt die Identitaet von ${rot}%s${reset} / ${rot}%s${reset}\n" "$jetzt" "$alterhost" "$alteip"
if [ -z "$obecht" ]; then
  printf "${rot}Simulationsmodus${reset} (kein -e angegeben) - es wird nichts veraendert, nur angezeigt.\n"
fi

# aktives Interface + zugehoerige NetworkManager-Verbindung ermitteln
iface=$(ip route get 1.1.1.1 2>/dev/null | awk '{for(i=1;i<=NF;i++) if($i=="dev") print $(i+1)}')
con=""
if [ -n "$iface" ] && command -v nmcli >/dev/null 2>&1; then
  con=$(nmcli -t -f NAME,DEVICE con show --active 2>/dev/null | awk -F: -v d="$iface" '$2==d{print $1; exit}')
fi
if [ -z "$iface" ]; then
  printf "${rot}Konnte aktives Netzwerk-Interface nicht ermitteln - breche ab.${reset}\n"
  exit 1
fi
printf "Interface: ${blau}%s${reset}, NetworkManager-Verbindung: ${blau}%s${reset}\n" "$iface" "${con:-?}"

# 1) Sicherheitscheck: antwortet die Ziel-IP noch jemand (Ping und/oder ARP)?
if [ -z "$obforce" ]; then
  printf "${dblau}Erreichbarkeitscheck${reset} von %s ...\n" "$alteip"
  if ping -c2 -W1 "$alteip" >/dev/null 2>&1; then
    printf "${rot}ACHTUNG: %s antwortet noch auf Ping! Uebernahme abgebrochen, um Adresskonflikt zu vermeiden.${reset}\n" "$alteip"
    printf "Falls das unbeabsichtigt ist, mit -f erzwingen.\n"
    exit 1
  fi
  if command -v arping >/dev/null 2>&1; then
    if arping -c2 -w2 -I "$iface" "$alteip" 2>/dev/null | grep -q "Received [1-9]"; then
      printf "${rot}ACHTUNG: %s antwortet auf ARP-Ebene! Uebernahme abgebrochen.${reset}\n" "$alteip"
      exit 1
    fi
  else
    printf "(arping nicht gefunden - nur Ping-Check moeglich; zypper in iputils fuer arping)\n"
  fi
  printf "${gruen}%s antwortet nicht - scheint frei zu sein.${reset}\n" "$alteip"
else
  printf "${rot}-f gesetzt: Erreichbarkeitscheck uebersprungen.${reset}\n"
fi

# 2) Rueckfrage vor echten Aenderungen (nur bei -e ohne -f)
if [ -n "$obecht" ] && [ -z "$obforce" ]; then
  printf "${rot}Dieser Rechner wird jetzt zu '%s' umbenannt, uebernimmt %s und startet Samba. Fortfahren? (ja/NEIN): ${reset}" "$alterhost" "$alteip"
  read -r antwort
  [ "$antwort" = "ja" ] || { printf "Abgebrochen.\n"; exit 1; }
fi

# 3) Hostname setzen
if [ -n "$obecht" ]; then
  printf "${blau}hostnamectl set-hostname %s${reset}\n" "$alterhost"
  hostnamectl set-hostname "$alterhost"
else
  printf "Simulation: hostnamectl set-hostname %s\n" "$alterhost"
fi

# 4) Crontab-Plausibilitaetscheck: erst nach dem Hostnamenwechsel greifen die
# HOST=linux1-Bedingungen der (auf allen drei Servern identischen) Crontab -
# eine verstuemmelte Crontab wuerde das aber lautlos verhindern (s. Warnung
# im Skriptkopf). Referenz: /root/crontabakt (Backup, wird per bulinux.sh
# dt1-Phase alle paar Stunden aktualisiert verteilt).
_ue_cron_ist=$(crontab -l 2>/dev/null | wc -l);
_ue_cron_soll=0; [ -f /root/crontabakt ] && _ue_cron_soll=$(wc -l </root/crontabakt);
printf "${dblau}Crontab-Check${reset}: %s Zeilen aktuell, %s Zeilen in /root/crontabakt\n" "$_ue_cron_ist" "$_ue_cron_soll";
if [ "$_ue_cron_soll" -gt 20 ] && [ "$_ue_cron_ist" -lt $(( _ue_cron_soll / 2 )) ]; then
  printf "${rot}Crontab sieht verstuemmelt aus (%s statt ~%s Zeilen)${reset}\n" "$_ue_cron_ist" "$_ue_cron_soll";
  if [ -n "$obecht" ]; then
    crontab /root/crontabakt && printf "${blau}Crontab aus /root/crontabakt neu installiert.${reset}\n";
  else
    printf "Simulation: crontab /root/crontabakt (Neuinstallation aus Backup)\n";
  fi;
else
  printf "${gruen}Crontab plausibel.${reset}\n";
fi;

# 5) IP-Adresse zusaetzlich vergeben: persistent (NetworkManager) + sofort (ip addr) + Gratuitous ARP
if [ -n "$obecht" ]; then
  if [ -n "$con" ]; then
    printf "${blau}nmcli connection modify \"%s\" +ipv4.addresses %s/24${reset}\n" "$con" "$alteip"
    nmcli connection modify "$con" +ipv4.addresses "$alteip/24"
    nmcli connection up "$con" >/dev/null 2>&1
  else
    printf "${rot}Keine NetworkManager-Verbindung gefunden - IP wird nur fluechtig (bis Reboot) gesetzt.${reset}\n"
  fi
  printf "${blau}ip addr replace %s/24 dev %s${reset}\n" "$alteip" "$iface"
  ip addr replace "$alteip/24" dev "$iface"
  if command -v arping >/dev/null 2>&1; then
    printf "${blau}arping -c3 -A -I %s %s${reset} (Gratuitous ARP)\n" "$iface" "$alteip"
    arping -c3 -A -I "$iface" "$alteip" >/dev/null 2>&1
  else
    printf "${rot}arping nicht gefunden - Gratuitous ARP uebersprungen; Clients aktualisieren ARP-Cache dann erst nach Timeout.${reset}\n"
  fi
else
  printf "Simulation: nmcli connection modify \"%s\" +ipv4.addresses %s/24; ip addr replace %s/24 dev %s; arping -A\n" "${con:-?}" "$alteip" "$alteip" "$iface"
fi

# 6) /DATA-Pfadtiefe pruefen und ggf. Samba-Freigabe korrigieren
# (anhand des tatsaechlichen Datenbestands, nicht anhand des Hostnamens -
# damit das Skript auch fuer kuenftige, aehnlich abweichend eingerichtete
# Reserveserver richtig funktioniert)
datenpfad=/DATA
if [ ! -d /DATA/Patientendokumente ] && [ -d /DATA/DATA/Patientendokumente ]; then
  datenpfad=/DATA/DATA
  printf "${rot}Hinweis:${reset} Praxisdaten liegen unter ${blau}%s${reset} statt /DATA (bekannte Eigenheit z.B. auf linux7).\n" "$datenpfad"
  if [ -n "$obecht" ]; then
    if [ -f /etc/samba/smb.conf ] && grep -q '^\[daten\]' /etc/samba/smb.conf; then
      cp -a /etc/samba/smb.conf "/etc/samba/smb.conf.vor_uebernahme_$(date +%Y%m%d_%H%M%S)"
      awk -v neu="   path = $datenpfad" '
        /^\[daten\]/ { insec=1; print; next }
        /^\[/ { insec=0; print; next }
        insec && /^[[:space:]]*path[[:space:]]*=/ { print neu; next }
        { print }
      ' /etc/samba/smb.conf > /etc/samba/smb.conf.neu \
        && mv /etc/samba/smb.conf.neu /etc/samba/smb.conf
      printf "${blau}[daten]-Freigabe in smb.conf auf %s umgestellt.${reset}\n" "$datenpfad"
    else
      printf "${rot}Kein [daten]-Abschnitt in smb.conf gefunden - bitte Samba-Freigabe manuell pruefen.${reset}\n"
    fi
  else
    printf "Simulation: [daten]-Freigabe in /etc/samba/smb.conf auf 'path = %s' umstellen\n" "$datenpfad"
  fi
fi

# 7) Samba starten (bewusst der einzige Aktivierungszeitpunkt)
if [ -n "$obecht" ]; then
  printf "${blau}Samba starten${reset}\n"
  systemctl enable --now smb 2>/dev/null || systemctl enable --now smbd 2>/dev/null
  systemctl enable --now nmb 2>/dev/null || systemctl enable --now nmbd 2>/dev/null
  systemctl is-active smb 2>/dev/null || systemctl is-active smbd 2>/dev/null
else
  printf "Simulation: systemctl enable --now smb nmb (bzw. smbd nmbd)\n"
fi

# 8) MariaDB-Aktualitaet nur anzeigen - keine automatische Promotion (s. Warnung oben)
printf "${dblau}MariaDB-Hinweis${reset}: Live-Datenbankstand NICHT automatisch aktualisiert.\n"
VLM=$(sed -n 's/^[[:space:]]*datadir[[:space:]]*=[[:space:]]*\(.*\)/\1/p' /etc/my.cnf 2>/dev/null)
if [ -n "$VLM" ] && [ -d "$VLM" ]; then
  printf "  Datenverzeichnis zuletzt geaendert: %s\n" "$(stat -c '%y' "$VLM" 2>/dev/null)"
fi
printf "  Bitte vor Produktivbetrieb pruefen: ${blau}bulinux.sh -dberg${reset} (Vergleich gegen %s falls erreichbar)\n" "$alterhost"

# 9) Best-effort: Fritzbox-Hosteintrag kosmetisch umbenennen (TR-064)
credfile="$HOME/.tr64cred"
if [ -f "$credfile" ]; then
  if [ -n "$obecht" ]; then
    printf "${dblau}Fritzbox-Hosteintrag umbenennen${reset} (best effort, TR-064) ...\n"
    crede=$(cat "$credfile")
    xml='<?xml version="1.0" encoding="utf-8"?>
<s:Envelope s:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/" xmlns:s="http://schemas.xmlsoap.org/soap/envelope/">
<s:Body><u:SetHostNameByIP xmlns:u="urn:dslforum-org:service:Hosts:1">
<NewIPAddress>'"$alteip"'</NewIPAddress>
<NewHostName>'"$alterhost"'</NewHostName>
</u:SetHostNameByIP></s:Body>
</s:Envelope>'
    if curl -s -k --anyauth -u "$crede" "http://fritz.box:49000/upnp/control/hosts" \
        -H 'Content-Type: text/xml; charset="utf-8"' \
        -H 'SoapAction: urn:dslforum-org:service:Hosts:1#SetHostNameByIP' \
        -d "$xml" 2>/dev/null | grep -qi "SetHostNameByIPResponse"; then
      printf "${gruen}Fritzbox-Eintrag umbenannt.${reset}\n"
    else
      printf "${rot}Fritzbox-Umbenennung nicht bestaetigt - nicht kritisch, ggf. manuell im Fritzbox-UI anpassen.${reset}\n"
    fi
  else
    printf "Simulation: Fritzbox-Hosteintrag fuer %s per TR-064 auf '%s' umbenennen\n" "$alteip" "$alterhost"
  fi
else
  printf "Kein %s gefunden - Fritzbox-Umbenennung uebersprungen.\n" "$credfile"
fi

printf "\n${dblau}Fertig.${reset}"
[ -z "$obecht" ] && printf " (Simulation - fuer den echten Lauf: -e anhaengen)"
printf "\nNaechste Schritte pruefen:\n"
printf "  - Zugriff von wser/wres auf \\\\\\\\%s\\\\daten testen\n" "$alterhost"
printf "  - MariaDB-Aktualitaet verifizieren (bulinux.sh -dberg) und bei Bedarf gezielt per\n"
printf "    mariadb-dump --single-transaction | mariadb nachziehen (s. Warnung im Skriptkopf)\n"
printf "  - los.sh -smb / los.sh firewall bei Bedarf erneut pruefen\n"
