#!/bin/bash
# zugang_gewaehren.sh - befristeter, eingeschraenkter SSH-Zugang fuer Claude/Admin auf andere Rechner.
#   zugang_gewaehren.sh [--stunden N | --tage N] [--user U] host...   Zugang eintragen (Passwort des Zielrechners wird gefragt)
#   zugang_gewaehren.sh --entfernen host...                            Zugang wieder entfernen
#   zugang_gewaehren.sh --status                                       Uebersicht (Ablauf, funktioniert er noch?)
# Der Zugang besteht aus einem EIGENEN Schluessel (/root/.ssh/id_ed25519_claude), der auf dem Zielrechner
# nur von diesem Rechner (from=) und nur bis zur Ablaufzeit (expiry-time=) gilt, ohne Weiterleitungen.
# Vorgabe: 24 Stunden. Der Eintrag traegt die Marke "claude-temp-zugang" und wird bei erneutem Aufruf ersetzt.
# Test-/Sonderoptionen: --datei <Pfad> (statt ssh in eine lokale Datei schreiben), --von <IP>, --ablauf <JJJJMMTThhmm>.
KEY=/root/.ssh/id_ed25519_claude; MARKE=claude-temp-zugang; STATE=/root/.ssh/claude_zugang.txt
STUNDEN=24; USER_=root; DATEI=; VON=; ABLAUF=; MODE=gewaehren; HOSTS=()
while [ $# -gt 0 ]; do case "$1" in
  --stunden) STUNDEN=$2; shift;; --tage) STUNDEN=$(( $2 * 24 )); shift;; --user) USER_=$2; shift;;
  --datei) DATEI=$2; shift;; --von) VON=$2; shift;; --ablauf) ABLAUF=$2; shift;;
  --entfernen) MODE=entfernen;; --status) MODE=status;; -h|--help) sed -n '2,10p' "$0"; exit 0;;
  -*) echo "unbekannte Option $1"; exit 1;; *) HOSTS+=("$1");; esac; shift; done
SSHO="-o IdentitiesOnly=yes -o BatchMode=yes -o ConnectTimeout=8 -o StrictHostKeyChecking=accept-new"
quelle_fuer() { [ -n "$VON" ] && { echo "$VON"; return; }
  local ip; ip=$(getent hosts "$1" | awk '{print $1; exit}'); ip route get "${ip:-192.168.178.1}" 2>/dev/null | sed -n 's/.* src \([0-9.]*\).*/\1/p' | head -1; }
zeile_bauen() { # host
  local src exp; src=$(quelle_fuer "$1"); exp=${ABLAUF:-$(date -d "+$STUNDEN hours" +%Y%m%d%H%M)}
  printf 'from="%s",expiry-time="%s",no-agent-forwarding,no-port-forwarding,no-X11-forwarding %s %s-%s-%s\n' \
    "$src" "$exp" "$(cut -d' ' -f1,2 "$KEY.pub")" "$MARKE" "$1" "$exp"; }
case "$MODE" in
gewaehren)
  [ ${#HOSTS[@]} -gt 0 ] || { sed -n '2,6p' "$0"; exit 1; }
  [ -f "$KEY" ] || ssh-keygen -q -t ed25519 -N "" -C "$MARKE" -f "$KEY" || exit 1
  for h in "${HOSTS[@]}"; do
    z=$(zeile_bauen "$h"); ablauf_txt=$(printf '%s' "$z" | sed -E 's/.*expiry-time="([0-9]+)".*/\1/')
    if [ -n "$DATEI" ]; then
      touch "$DATEI"; sed -i "/ $MARKE-$h-/d" "$DATEI"; printf '%s\n' "$z" >> "$DATEI"; echo "$h: Zeile in $DATEI geschrieben (Ablauf $ablauf_txt)"; continue
    fi
    echo "== $h: Passwort von $USER_@$h eingeben, um den befristeten Zugang einzutragen =="
    ssh -o StrictHostKeyChecking=accept-new "$USER_@$h" "umask 077; mkdir -p \$HOME/.ssh; touch \$HOME/.ssh/authorized_keys; sed -i '/ $MARKE-$h-/d' \$HOME/.ssh/authorized_keys; printf '%s\n' '$z' >> \$HOME/.ssh/authorized_keys; chmod 600 \$HOME/.ssh/authorized_keys" \
      && { sed -i "/^$h /d" "$STATE" 2>/dev/null; echo "$h $USER_ $ablauf_txt" >> "$STATE"
           if ssh -i "$KEY" $SSHO "$USER_@$h" true 2>/dev/null; then echo "$h: Zugang aktiv bis $ablauf_txt (JJJJMMTThhmm)"; else echo "$h: eingetragen, Testlogin scheitert noch - Quelladresse/Uhrzeit/Firewall pruefen"; fi; }
  done;;
entfernen)
  [ ${#HOSTS[@]} -gt 0 ] || { sed -n '2,6p' "$0"; exit 1; }
  for h in "${HOSTS[@]}"; do
    cmd="sed -i '/ $MARKE-$h-/d' \$HOME/.ssh/authorized_keys"
    if [ -n "$DATEI" ]; then sed -i "/ $MARKE-$h-/d" "$DATEI"; echo "$h: aus $DATEI entfernt"; continue; fi
    if ssh -i "$KEY" $SSHO "$USER_@$h" "$cmd" 2>/dev/null; then echo "$h: Zugang entfernt (mit dem Zugangsschluessel selbst)"
    else echo "$h: Schluessel greift nicht mehr - Passwort eingeben zum Entfernen"; ssh "$USER_@$h" "$cmd" && echo "$h: entfernt"; fi
    sed -i "/^$h /d" "$STATE" 2>/dev/null
  done
  [ -n "$DATEI" ] || [ -s "$STATE" ] || { rm -f "$STATE" "$KEY" "$KEY.pub"; echo "keine Zugaenge mehr eingetragen: lokaler Zugangsschluessel geloescht"; };;
status)
  [ -s "$STATE" ] || { echo "keine befristeten Zugaenge eingetragen"; exit 0; }
  while read -r h u ab; do
    if ssh -i "$KEY" $SSHO "$u@$h" true 2>/dev/null; then st="funktioniert"; else st="funktioniert NICHT (abgelaufen/entfernt/nicht erreichbar)"; fi
    echo "$h ($u): Ablauf $ab - $st"; done < "$STATE";;
esac
