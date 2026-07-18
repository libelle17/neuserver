#!/bin/bash
# platz.sh - Notfallmaßnahme bei vollem Root-Dateisystem: wenn "df /" 100%
# belegten Platz meldet, werden hängende postdrop-Prozesse (Teil der
# Postfix-Mailzustellung, kann bei vollem "/" blockieren und selbst weiter
# Platz/Prozesse binden) beendet - zunächst normal (SIGTERM), ab dem 3. von
# insgesamt 5 Versuchen mit steigendem Nachdruck per SIGKILL (-9). Wenn auf
# Laufwerk / der verbrauchte Platz 100% ist, dann geratenerweise postdrop
# abbrechen. Aufruf ohne Parameter, typischerweise per Cron regelmäßig.
par=;
for iru in $(seq 1 1 5); do
  [ $iru = 3 ]&&par="-9";
  [ $(df /|awk '/\//{print $5*1}') = 100 ]&&ps -Alf|grep postdrop|grep -v grep|pkill $par postdrop;
done;
