#!/bin/bash
# sdauffuellen.sh - ergaenzt fehlende Schutzdateien (Ransomware-Kanarienvogel-
# Dateien) in neu entstandenen Verzeichnissen unter genau den unten gelisteten,
# bekannt gleichfoermigen /DATA-Elternverzeichnissen (z.B. neues Mail-Profil,
# neuer Jahresordner unter Patientendokumente/eingelesen). Rein lokal auf
# linux1, kein SSH, kein Kontakt zum eingeschraenkten Backup-Key.
#
# WICHTIG (Lehre aus Fehlversuch 13.7.2026): eine automatische Regel "wenn ein
# Geschwisterverzeichnis schon eine Schutzdatei hat, gilt das Muster fuer alle
# anderen Geschwister" wurde zunaechst direkt unter /DATA angewendet und hat
# dadurch faelschlich 4955 Schutzdateien in voellig unzusammenhaengende
# Verzeichnisse gestreut (u.a. .Trash-0, test, StarMoney alt, tmp) - wieder
# entfernt. Diese Heuristik ist bei den historisch gewachsenen, extrem
# uneinheitlichen Verzeichnissen wie /DATA, /DATA/Patientendokumente,
# /DATA/eigene Dateien, /DATA/shome/gerald grundsaetzlich unsicher (hunderte
# beliebig benannte Ordner nebeneinander). Deshalb jetzt: feste Positivliste
# statt Automatik - neue Eintraege hier nur nach manueller Pruefung ergaenzen.
#
# Aufruf ohne Parameter: nur Trockenlauf (zeigt an, was ergaenzt wuerde).
# Aufruf mit "-e": wirklich schreiben.

ELTERNLISTE=(
  "/DATA/Mail/Thunderbird/Profiles"
  "/DATA/Patientendokumente/eingelesen"
)

SDLISTE=("Schutzdatei_bitte_belassen.doc" "Auch_eine_Schutzdatei_bitte_belassen.jpg" "zusätzliche_Schutzdatei_bitte_belassen.pdf") # muss zu bugem.sh passen
MASTER=/root/bin
LOG=/var/log/sdauffuellen.log

obecht=; [ "$1" = "-e" ] && obecht=1

log() { printf '%s %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$1" >>"$LOG"; }

zaehl=0
for eltern in "${ELTERNLISTE[@]}"; do
  [ -d "$eltern" ] || continue
  vorlage=
  for sib in "$eltern"/*/; do
    sib="${sib%/}"
    [ -f "$sib/${SDLISTE[0]}" ] && { vorlage="$sib"; break; }
  done
  if [ -z "$vorlage" ]; then
    printf "%s: keine Vorlage (keine Schutzdatei in irgendeinem Unterverzeichnis) - ueberspringe\n" "$eltern"
    continue
  fi
  for verz in "$eltern"/*/; do
    verz="${verz%/}"
    [ "$verz" = "$vorlage" ] && continue
    for sd in "${SDLISTE[@]}"; do
      [ -f "$verz/$sd" ] && continue
      [ -f "$MASTER/$sd" ] || continue
      zaehl=$((zaehl+1))
      if [ "$obecht" ]; then
        if cp -p "$MASTER/$sd" "$verz/$sd" 2>/dev/null; then
          [ -f "$vorlage/$sd" ] && {
            chown --reference="$vorlage/$sd" "$verz/$sd" 2>/dev/null
            chmod --reference="$vorlage/$sd" "$verz/$sd" 2>/dev/null
          }
          log "ergaenzt: $verz/$sd (Vorlage: $vorlage)"
        fi
      else
        printf "Simulation: wuerde ergaenzen: %s/%s (Vorlage: %s)\n" "$verz" "$sd" "$vorlage"
      fi
    done
  done
done

if [ "$obecht" ]; then
  log "Lauf beendet ($zaehl ergaenzt)."
  printf "Fertig: %s Datei(en) ergaenzt.\n" "$zaehl"
else
  printf "Trockenlauf beendet: %s Datei(en) wuerden ergaenzt (kein -e angegeben, nichts geschrieben).\n" "$zaehl"
fi
