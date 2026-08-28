#!/bin/bash
# kocoreboot.sh - startet die KoCoBox (Konnektor) per REST-API neu.
# Bildet den offiziellen 3-Schritt-Ablauf nach (Login -> X-Token holen ->
# perform/reboot), ohne den fragilen cmd/PowerShell-Polyglot-Trick
# ("more +8"), der bei jeder Zeilenverschiebung beim Copy-Paste die
# $IP-Zuweisung verschluckt (-> leere Uri, "Hostname konnte nicht analysiert
# werden"). Gerald Schade, 28.8.2026
#
# Aufruf: kocoreboot.sh [-ip <IP>] [-u <Benutzer>] [-neu] [-v] [-h|--help]
#   -ip <IP>      IP/Hostname der KoCoBox (Vorgabe: 192.168.178.240)
#   -u <Benutzer> koco-root-Benutzer (Vorgabe: koco-root)
#   -neu          Passwort neu abfragen (überschreibt $credfile)
#   -v            gesprächiger Modus (zeigt HTTP-Status der einzelnen Schritte)
#   -h|--help     diese Hilfe

vorgaben() {
  IP=192.168.178.240;
  User=koco-root;
  obneu=0;
  verb=;
  credfile="$HOME/.kococred"; # enthält nur das Passwort, chmod 600
  cookiejar=$(mktemp);
  headerdt=$(mktemp);
  trap 'rm -f "$cookiejar" "$headerdt"' EXIT;
}

commandline() {
  while [ $# -gt 0 ]; do
    case "$1" in
      -ip) IP=$2; shift;;
      -u|-user) User=$2; shift;;
      -neu|-new) obneu=1;;
      -v|--verbose) verb=1;;
      -h|--h|--help|-\?)
        printf "Aufruf: $0 [-ip <IP>] [-u <Benutzer>] [-neu] [-v] [-h]\n";
        printf "  -ip <IP>      IP/Hostname der KoCoBox (Vorgabe: $IP)\n";
        printf "  -u <Benutzer> koco-root-Benutzer (Vorgabe: $User)\n";
        printf "  -neu          Passwort neu abfragen\n";
        printf "  -v            gesprächiger Modus\n";
        exit 0;;
      *) printf "Unbekannter Parameter: $1\n" >&2; exit 1;;
    esac;
    shift;
  done;
}

# Passwort aus $credfile lesen, bei Bedarf (fehlend oder -neu) interaktiv erfragen
authorize() {
  [ "$obneu" = 0 ] && [ -f "$credfile" ] && Pass=$(cat "$credfile");
  if [ -z "$Pass" ]; then
    if [ -t 0 ]; then
      printf "Passwort für %s@%s eingeben: " "$User" "$IP"; read -rs Pass; echo;
      printf "%s" "$Pass" > "$credfile";
      chmod 600 "$credfile";
    else
      printf "Kein Passwort in %s und kein Terminal vorhanden. Bitte einmal interaktiv \"%s -neu\" ausführen.\n" "$credfile" "$0" >&2;
      exit 1;
    fi;
  fi;
}

pruefcode() {
  # Parameter: 1: http-Code, 2: Bezeichnung des Schritts (für Fehlermeldung)
  case "$1" in
    2??|3??) [ "$verb" ] && printf "%s: HTTP %s ok\n" "$2" "$1";;
    *) printf "%s fehlgeschlagen: HTTP %s\n" "$2" "$1" >&2; exit 1;;
  esac;
}

reboot() {
  base="https://$IP:9443";
  curltmo="--connect-timeout 5 --max-time 15";

  [ "$verb" ] && printf "Hole initiale Session von %s/administration/ ...\n" "$base";
  code=$(curl -sk $curltmo -o /dev/null -w '%{http_code}' -c "$cookiejar" "$base/administration/");
  pruefcode "$code" "Initiale Session";
  [ "$verb" ] && { printf "Cookiejar nach initialer Session:\n"; cat "$cookiejar"; }

  [ "$verb" ] && printf "Login bei %s/j_security_check ...\n" "$base";
  code=$(curl -sk $curltmo -o /dev/null -w '%{http_code}' -b "$cookiejar" -c "$cookiejar" -D "$headerdt" \
    --data-urlencode "j_username=$User" --data-urlencode "j_password=$Pass" \
    "$base/j_security_check");
  pruefcode "$code" "Login";
  [ "$verb" ] && { printf "Antwort-Header Login:\n"; cat "$headerdt"; printf "Cookiejar nach Login:\n"; cat "$cookiejar"; }

  [ "$verb" ] && printf "Hole X-Token von %s/administration/start.htm ...\n" "$base";
  startdt=$(mktemp);
  code=$(curl -sk $curltmo -o "$startdt" -w '%{http_code}' -b "$cookiejar" -c "$cookiejar" -L "$base/administration/start.htm");
  pruefcode "$code" "X-Token-Abfrage";
  # der Token steckt in einem versteckten Feld der Dashboard-Seite: <textarea id="x-token">...</textarea>
  xtoken=$(sed -n 's/.*id="x-token"[^>]*>\([^<]*\)<.*/\1/p' "$startdt");
  rm -f "$startdt";
  if [ -z "$xtoken" ]; then
    printf "Konnte X-Token nicht aus %s/administration/start.htm ermitteln (Login evtl. fehlgeschlagen).\n" "$base" >&2; exit 1;
  fi;
  [ "$verb" ] && printf "X-Token: %s\n" "$xtoken";

  [ "$verb" ] && printf "Starte Neustart über %s/administration/perform/reboot ...\n" "$base";
  antwort=$(curl -sk $curltmo -w '\n%{http_code}' -b "$cookiejar" -c "$cookiejar" \
    -H "Content-Type: application/json" -H "Accept: application/json" -H "X-Requested-With: XMLHttpRequest" -H "X-TOKEN: $xtoken" \
    -X POST -d '' "$base/administration/perform/reboot");
  code=$(echo "$antwort" | tail -n1);
  antwort=$(echo "$antwort" | sed '$d');
  pruefcode "$code" "Neustart-Kommando";
  printf "Antwort der KoCoBox: %s\n" "$antwort";
}

vorgaben;
commandline "$@";
authorize;
reboot;
