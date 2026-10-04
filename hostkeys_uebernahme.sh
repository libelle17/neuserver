#!/bin/bash
# hostkeys_uebernahme.sh - bereitet die Sicherungsrechner linux0/linux7 auf eine Uebernahme vor
# (uebernahme.sh): Uebernimmt z.B. linux0 die Identitaet von linux1 (Hostname linux1, IP 192.168.178.21),
# meldet er sich per ssh mit SEINEM eigenen Rechnerschluessel. Die anderen Rechner kennen fuer "linux1" aber
# nur den Schluessel des echten linux1 -> "REMOTE HOST IDENTIFICATION HAS CHANGED", alle Sicherungen von
# "linux1" stuenden still. Dieses Skript traegt deshalb in /root/.ssh/known_hosts die schon bekannten
# Schluessel der Uebernahme-Kandidaten linux0 und linux7 ZUSAETZLICH unter "linux1,192.168.178.21" ein
# (alle Schluesseltypen). ssh akzeptiert fuer einen Namen jeden eingetragenen Schluessel; fremde Schluessel
# werden weiter abgelehnt. Idempotent; wird von wecklauf.sh bei jedem Fensterlauf aufgerufen.
# Eingerichtet 4.10.2026.
# Aufruf: hostkeys_uebernahme.sh [-e]   ohne -e nur anzeigen
obecht=; [ "$1" = -e ] && obecht=1;
KH=/root/.ssh/known_hosts; [ -f "$KH" ] || exit 0;
vorh=$(ssh-keygen -F linux1 -f "$KH" 2>/dev/null; ssh-keygen -F 192.168.178.21 -f "$KH" 2>/dev/null);
neu=0;
for k in linux0 linux7; do # nur Namens-Eintraege (IP-Eintraege koennen veraltete Schluessel enthalten)
  while read -r _ typ key _; do
    [ -n "$key" ] || continue;
    printf '%s\n' "$vorh" | grep -qF "$typ $key" && continue;
    if [ "$obecht" ]; then
      echo "linux1,192.168.178.21 $typ $key" >> "$KH";
    else
      echo "wuerde eintragen: linux1,192.168.178.21 $typ (Schluessel von $k)";
    fi;
    vorh="$vorh
x $typ $key"; neu=$((neu+1));
  done < <(ssh-keygen -F "$k" -f "$KH" 2>/dev/null | grep -v '^#');
done;
[ "$obecht" ] && [ "$neu" -gt 0 ] && echo "hostkeys_uebernahme.sh: $neu Schluessel unter linux1 eingetragen";
exit 0;
