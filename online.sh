#!/bin/bash
# online.sh - zeigt rasch an, welche der bekannten Linux-Server und
# Windows-PCs im LAN gerade eingeschaltet/erreichbar sind, mit
# Name, IPv4- und MAC-Adresse. Pings laufen parallel fuer Tempo.

linux_pcs="linux0 linux1 linux2 linux3 linux7 linux8"
win_pcs="anmoo anmww anmmo anmmw anmh bzw2 fuss labor3 res1 res3 sono1 sr6 srn2 szo1 szon1 szoo1 szow1 szs1 szn4 wexp wres wser amd hss"

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

eigenname=$(hostname -s)

pruef() {
  local pc="$1" gruppe="$2" out
  out=$(ping -c1 -W1 "$pc" 2>/dev/null) || return
  local ip=$(echo "$out" | sed -n '1s/^PING [^ ]* (\([0-9.]*\)).*/\1/p')
  local mac
  if [ "$pc" = "$eigenname" ]; then
    # eigene MAC steht nicht in der ARP-Tabelle - stattdessen lokale Schnittstelle abfragen
    mac=$(ip -o link show | awk '!/ lo:/{for(i=1;i<=NF;i++) if ($i=="link/ether") {print $(i+1); exit}}')
  else
    mac=$(ip neigh show "$ip" 2>/dev/null | awk '{print $5; exit}')
  fi
  printf "%s\t%s\t%s\t%s\n" "$gruppe" "$pc" "${ip:--}" "${mac:--}" > "$TMP/$gruppe-$pc"
}

for pc in $linux_pcs; do pruef "$pc" linux & done
for pc in $win_pcs;   do pruef "$pc" windows & done
wait

lila="\033[1;35m"; reset="\033[0m"

zeig_zeile() {
  local name="$1" ip="$2" mac="$3"
  local zeile; zeile=$(printf "%-10s %-16s %s" "$name" "$ip" "$mac")
  if [ "$name" = "$eigenname" ]; then
    printf "${lila}%s${reset}\n" "$zeile"
  else
    printf "%s\n" "$zeile"
  fi
}

echo "=== Linux-Server ==="
printf "%-10s %-16s %s\n" "NAME" "IP" "MAC"
for f in $(ls "$TMP"/linux-* 2>/dev/null | sort); do
  IFS=$'\t' read -r _ name ip mac < "$f"
  zeig_zeile "$name" "$ip" "$mac"
done

echo
echo "=== Windows-PCs ==="
printf "%-10s %-16s %s\n" "NAME" "IP" "MAC"
for f in $(ls "$TMP"/windows-* 2>/dev/null | sort); do
  IFS=$'\t' read -r _ name ip mac < "$f"
  zeig_zeile "$name" "$ip" "$mac"
done

echo
lc=$(ls "$TMP"/linux-* 2>/dev/null | wc -l)
wc_=$(ls "$TMP"/windows-* 2>/dev/null | wc -l)
echo "$lc von $(echo $linux_pcs | wc -w) Linux-Servern, $wc_ von $(echo $win_pcs | wc -w) Windows-PCs erreichbar."
