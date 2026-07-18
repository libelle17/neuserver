#!/bin/bash
# rueckgabe.sh - Vorbereitung der Ruecknahme: weckt das reparierte linux1
# (bzw. den jeweiligen Hauptserver) und sorgt dafuer, dass es eine eigene
# IP-Adresse bekommt, OHNE Adresskonflikt mit der hier auf dem Reserveserver
# noch geliehenen IP - damit man sich danach z.B. per PuTTY/SSH auf linux1
# anmelden und dort ruecknahme.sh aufrufen kann. Gegenstueck zu
# uebernahme.sh, laeuft aber (anders als ruecknahme.sh) auf dem
# RESERVESERVER selbst (z.B. linux0), NICHT auf linux1.
#
# Commit-Text (Ersteinfuehrung dieses Skripts):
#   rueckgabe.sh: weckt das reparierte linux1 und raeumt die geliehene IP
#   rechtzeitig weg, damit linux1 sie konfliktfrei bekommt
#
# Herkunft (Stand 11.07.2026): Beim ersten echten Testlauf blieb linux1 nach
# dem Aufwecken laenger als erwartet in "wird verbunden (IP-Einstellungen
# werden ermittelt)" haengen: der Reserveserver trug zu dem Zeitpunkt noch
# dessen IP, wodurch linux1s DHCP-Client per Adresskonflikterkennung (ACD)
# jede Zuteilung ablehnte ("... cannot be configured because it is already
# in use by host <MAC des Reserveservers>"). Diese Reihenfolge (erst wecken,
# dann irgendwann die IP freigeben) provoziert das Rennen erst. rueckgabe.sh
# dreht die Reihenfolge deshalb um: IP zuerst freigeben, dann erst wecken.
#
# Aufruf (als root AUF DEM RESERVESERVER):
#   rueckgabe.sh <hauptserver> <dessen-ip> [-e] [-f] [-v]
#
#   <hauptserver>    Hostname des Servers, der geweckt werden und seine IP
#                    zurueckbekommen soll (z.B. linux1)
#   <dessen-ip>      dessen IP-Adresse (z.B. 192.168.178.21), die dieser
#                    Reserveserver waehrend der Notfallzeit zusaetzlich traegt
#   -e|-echt   echter Lauf (ohne: nur Anzeige/Simulation, es wird nichts veraendert)
#   -f|-force  ueberspringt die Rueckfrage (fuer nicht-interaktive Aufrufe)
#   -v|-verbose ausfuehrlichere Ausgabe
#
# Beispiel:
#   cd /root/bin && ./rueckgabe.sh linux1 192.168.178.21 -e
#
# Was das Skript tut:
#   1. Fragt (falls -e ohne -f) interaktiv nach, bevor etwas veraendert wird
#   2. Entfernt die waehrend der Uebernahme geliehene <dessen-ip> von diesem
#      Reserveserver (NetworkManager + ip addr del) - VOR dem Wecken, damit
#      kein Adresskonflikt entsteht (s. Herkunft oben). Eigener Hostname,
#      Samba und MariaDB bleiben hier unveraendert - das erledigt erst
#      ruecknahme.sh (von <hauptserver> aus aufgerufen), NACHDEM die Daten
#      zurueckgeholt wurden.
#   3. Weckt <hauptserver> per weckalle.sh (Fritzbox TR-064 WakeOnLAN)
#   4. Wartet/pollt bis zu ~10 Minuten, bis <dessen-ip> per Ping antwortet
#   5. Gibt die naechsten manuellen Schritte aus (SSH/PuTTY-Zugang zu
#      <hauptserver>, dort ruecknahme.sh aufrufen)
#
# WICHTIG: Falls <hauptserver> nach dem Timeout in Schritt 4 immer noch nicht
# erreichbar ist, kann das ein rein netzwerkseitiges Problem auf dessen
# eigener Seite sein (z.B. NetworkManager dort haengt trotz freier Adresse
# in einem alten Backoff-Zustand fest, beobachtet am 11.07.2026) - das laesst
# sich von hier aus nicht beheben. Dann bitte direkt an der Konsole von
# <hauptserver> pruefen, ggf. dort "nmcli connection down/up <Verbindung>"
# bzw. "ip neigh flush dev <interface>" fuer eine frische DHCP-Runde.

set -u
MUPR=$(readlink -f "$0")
MDIR=$(dirname "$MUPR")
blau="\033[1;34m";
dblau="\033[0;34;1;47m";
rot="\033[1;31m";
gruen="\033[0;32m";
reset="\033[0m";

hauptserver="linux1"  # Default (11.07.2026): in der Praxis gibt es nur ein linux1 - Parameter bleibt trotzdem ueberschreibbar
hauptip="192.168.178.21"  # Default, s.o.
obecht=
obforce=
verb=
obdbdump=
obnurdb=

while [ $# -gt 0 ]; do
  case "$1" in
    -e|-echt) obecht=1;;
    -f|-force) obforce=1;;
    -v|-verbose) verb=1;;
    -dbdump) obdbdump=1;;    # an ruecknahme.sh/bulinux.sh durchgereicht, s. dort - erzwingt mariadb-dump statt Datadir-rsync
    -nurdb) obnurdb=1;;      # an ruecknahme.sh/bulinux.sh durchgereicht, s. dort
    -h|-hilfe|-help|--help)
      printf "Aufruf: %s [<hauptserver> <dessen-ip>] [-e] [-f] [-v] [-dbdump] [-nurdb]\n" "$(basename "$0")"
      printf "  -e  echter Lauf (ohne: nur Simulation/Anzeige)\n"
      printf "  -f  ueberspringt die Rueckfrage\n"
      printf "  -v  ausfuehrliche Ausgabe\n"
      printf "  -dbdump/-nurdb  werden an ein automatisch angestossenes ruecknahme.sh durchgereicht (s. Schritt 5)\n"
      printf "Beispiel: %s -e  (linux1/192.168.178.21 sind seit 11.07.2026 Default und koennen weggelassen werden)\n" "$(basename "$0")"
      exit 0;;
    -*) printf "${rot}Unbekannte Option: %s${reset}\n" "$1"; exit 1;;
    *)
      if [ -z "$hauptserver" ]; then hauptserver="$1";
      elif [ -z "$hauptip" ]; then hauptip="$1";
      else printf "${rot}Zu viele Argumente: %s${reset}\n" "$1"; exit 1;
      fi;;
  esac
  shift
done

if [ -z "$hauptserver" ] || [ -z "$hauptip" ]; then
  printf "${rot}Aufruf: %s <hauptserver> <dessen-ip> [-e] [-f] [-v]${reset}\n" "$(basename "$0")"
  printf "Beispiel: %s -e  (linux1/192.168.178.21 sind seit 11.07.2026 Default und koennen weggelassen werden)\n" "$(basename "$0")"
  exit 1
fi

jetzt=$(hostname -s 2>/dev/null || hostname)
# Waehrend des Notfallbetriebs traegt dieser Reserveserver selbst schon den
# Namen des Hauptservers (s. uebernahme.sh) - fuer die Selbstidentifikation
# hier (Banner, Vorschlag fuer ruecknahme.sh-Aufruf) zaehlt aber die eigene,
# urspruengliche Identitaet aus /etc/notfallbetrieb, falls vorhanden.
[ -r /etc/notfallbetrieb ] && jetzt=$(cat /etc/notfallbetrieb)
printf "${dblau}rueckgabe${reset}(): dieser Reserveserver (${blau}%s${reset}) gibt die geliehene IP von ${blau}%s${reset} frei und weckt es\n" "$jetzt" "$hauptserver"
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

# 1) Rueckfrage vor echten Aenderungen (nur bei -e ohne -f)
if [ -n "$obecht" ] && [ -z "$obforce" ]; then
  printf "${rot}Die geliehene IP %s wird jetzt von diesem Reserveserver entfernt und %s geweckt. Fortfahren? (ja/NEIN): ${reset}" "$hauptip" "$hauptserver"
  read -r antwort
  [ "$antwort" = "ja" ] || { printf "Abgebrochen.\n"; exit 1; }
fi

# 2) Geliehene IP VOR dem Wecken entfernen (s. Herkunft im Kopfkommentar).
# Bugfix 11.07.2026: frueher wurde das NUR gemacht, wenn die IP GERADE
# LIVE auf dem Interface sichtbar war ("ip addr show"). Das reicht nicht:
# uebernahme.sh traegt die IP per "nmcli connection modify +ipv4.addresses"
# dauerhaft ins Verbindungsprofil ein - bleibt sie dort haengen (z.B. weil
# ein vorheriger rueckgabe.sh/ruecknahme.sh-Lauf abgebrochen ist), meldet
# NetworkManager bei jeder Neuaktivierung (DHCP-Renewal etc.) erneut einen
# Adresskonflikt mit dem echten Hauptserver und wirft dabei die GESAMTE
# Verbindung raus (auch die eigene, im selben Profil laufende Adresse!) -
# beobachtet am 11.07.2026: rein die "ip addr show"-Live-Pruefung fand in
# einem solchen Fehlschleifen-Moment zufaellig gerade nichts und liess das
# Profil unbereinigt, wodurch linux0 selbst voruebergehend komplett vom Netz
# ging. Deshalb jetzt IMMER (unconditional) versuchen, die IP aus dem
# Profil UND vom Interface zu entfernen - beides ist bei bereits fehlender
# Adresse ein harmloses No-Op.
if true; then
  printf "${dblau}Geliehene IP freigeben${reset}: %s von %s (%s)\n" "$hauptip" "$jetzt" "$iface"
  if [ -n "$obecht" ]; then
    if [ -n "$con" ]; then
      nmcli connection modify "$con" -ipv4.addresses "$hauptip/24" 2>/dev/null
    fi
    ip addr del "$hauptip/24" dev "$iface" 2>/dev/null
    printf "${gruen}%s freigegeben.${reset}\n" "$hauptip"
  else
    printf "Simulation: nmcli connection modify \"%s\" -ipv4.addresses %s/24; ip addr del %s/24 dev %s\n" "${con:-?}" "$hauptip" "$hauptip" "$iface"
  fi
fi

# 3) Hauptserver wecken (Fritzbox TR-064 WakeOnLAN, s. weckalle.sh) -
# harmlos, falls er schon an ist (bloss ein zusaetzliches Magic Packet)
printf "${dblau}Wecken${reset}: %s/weckalle.sh %s\n" "$MDIR" "$hauptserver"
if [ -n "$obecht" ]; then
  "$MDIR/weckalle.sh" "$hauptserver"
else
  printf "Simulation: %s/weckalle.sh %s\n" "$MDIR" "$hauptserver"
fi

# 4) Auf Erreichbarkeit warten (bis zu ~10 Minuten, physische Server-Boots
# inkl. evtl. Reparatur-bedingter Checks koennen dauern, s. WICHTIG oben)
if [ -n "$obecht" ]; then
  printf "${dblau}Warte auf Erreichbarkeit${reset} von %s (%s) ...\n" "$hauptserver" "$hauptip"
  _rg_wach=
  for _rg_i in $(seq 1 60); do
    if ping -c1 -W1 "$hauptip" >/dev/null 2>&1; then
      _rg_wach=1
      break
    fi
    [ "$verb" ] && printf "  [%02d/60] noch nicht erreichbar ...\n" "$_rg_i"
    sleep 10
  done
  if [ -n "$_rg_wach" ]; then
    printf "${gruen}%s (%s) ist erreichbar.${reset}\n" "$hauptserver" "$hauptip"
    # Nachpruefung (11.07.2026, erweitert nach dem linux0-Vorfall vom selben
    # Tag): prueft jetzt sowohl die LIVE-Interface-Adresse als auch das
    # DAUERHAFTE nmcli-Profil (s. Bugfix-Kommentar bei Schritt 2 oben) -
    # falls die geliehene IP zwischenzeitlich (z.B. durch einen erneuten
    # uebernahme.sh-Aufruf oder ein reaktiviertes NetworkManager-Profil)
    # doch wieder hier aufgetaucht ist, waere jetzt trotzdem ein
    # Adresskonflikt moeglich - sicherheitshalber nochmal pruefen und ggf.
    # erneut freigeben, statt uns auf den einmaligen Schritt 2 zu verlassen.
    _rg_prof_hat_ip=
    [ -n "$con" ] && nmcli connection show "$con" 2>/dev/null | grep -q "ipv4.addresses:.*$hauptip/" && _rg_prof_hat_ip=1
    if ip -4 addr show "$iface" 2>/dev/null | grep -q "$hauptip/" || [ -n "$_rg_prof_hat_ip" ]; then
      printf "${rot}Nachpruefung${reset}: %s ist auf diesem Reserveserver (live und/oder im Profil) schon wieder gesetzt - gebe erneut frei.\n" "$hauptip"
      [ -n "$con" ] && nmcli connection modify "$con" -ipv4.addresses "$hauptip/24" 2>/dev/null
      ip addr del "$hauptip/24" dev "$iface" 2>/dev/null
      printf "${gruen}%s erneut freigegeben.${reset}\n" "$hauptip"
    fi
  else
    printf "${rot}%s (%s) antwortet nach ~10 Minuten immer noch nicht.${reset}\n" "$hauptserver" "$hauptip"
    printf "Bitte direkt an der Konsole von %s pruefen (s. WICHTIG im Skriptkopf).\n" "$hauptserver"
  fi
else
  printf "Simulation: bis zu 10 Minuten auf Ping-Antwort von %s warten, danach Nachpruefung der geliehenen IP\n" "$hauptip"
fi

# 5) Auto-Verkettung (11.07.2026): falls hauptserver erreichbar ist UND per
# SSH ohne Passwortabfrage angesprochen werden kann, gleich ruecknahme.sh
# dort anstossen, statt nur die manuellen Schritte auszugeben - mit
# denselben -e/-f/-v-Flags wie dieser rueckgabe.sh-Aufruf (wer rueckgabe.sh
# also z.B. nur simuliert hat, bekommt auch nur eine Simulation von
# ruecknahme.sh; -dbrsync/-nurdb werden ebenfalls durchgereicht). Klappt die
# SSH-Verbindung nicht (z.B. NetworkManager auf hauptserver haengt trotz
# freier Adresse in einem Backoff-Zustand fest, s. WICHTIG oben), bleibt es
# beim bisherigen manuellen Hinweis - das laesst sich von hier aus ohnehin
# nicht automatisch beheben.
_rg_extra="";
[ -n "$obdbdump" ] && _rg_extra="$_rg_extra -dbdump";
[ -n "$obnurdb" ] && _rg_extra="$_rg_extra -nurdb";
if [ -n "$obecht" ] && [ -n "$_rg_wach" ]; then
  printf "${dblau}Pruefe SSH-Zugang${reset} zu %s ...\n" "$hauptip"
  if ssh -o BatchMode=yes -o ConnectTimeout=5 -o StrictHostKeyChecking=accept-new "root@$hauptip" 'true' 2>/dev/null; then
    printf "${gruen}SSH-Verbindung funktioniert${reset} - starte ruecknahme.sh automatisch auf %s.\n" "$hauptserver"
    ssh "root@$hauptip" "cd /root/bin && ./ruecknahme.sh $jetzt${obecht:+ -e}${obforce:+ -f}${verb:+ -v}$_rg_extra"
    _rg_rn_ret=$?
    if [ "$_rg_rn_ret" -ne 0 ]; then
      printf "${rot}ruecknahme.sh auf %s meldete Exitcode %s${reset} - bitte Ausgabe oben pruefen.\n" "$hauptserver" "$_rg_rn_ret"
    fi
  else
    printf "${rot}SSH-Verbindung zu %s klappt (noch) nicht${reset} - kein automatischer Start moeglich.\n" "$hauptip"
    printf "Bitte manuell pruefen (s. WICHTIG oben) und danach selbst anmelden:\n"
    printf "  - Per SSH/PuTTY auf %s (%s) anmelden\n" "$hauptserver" "$hauptip"
    printf "  - Dort: ${blau}cd /root/bin && ./ruecknahme.sh %s -e${reset} (zunaechst ohne -f zur Sicherheit)\n" "$jetzt"
  fi
fi

printf "\n${dblau}Fertig.${reset}"
[ -z "$obecht" ] && printf " (Simulation - fuer den echten Lauf: -e anhaengen)"
if [ -z "$obecht" ] || [ -z "$_rg_wach" ]; then
  printf "\nNaechste Schritte:\n"
  printf "  - Per SSH/PuTTY auf %s (%s) anmelden\n" "$hauptserver" "$hauptip"
  printf "  - Dort: ${blau}cd /root/bin && ./ruecknahme.sh %s -e${reset} (zunaechst ohne -f zur Sicherheit)\n" "$jetzt"
else
  printf "\n"
fi
