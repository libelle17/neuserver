#!/bin/bash
# Legt die Benutzer-CA an: privater Schluessel unter /root/ca-pilot (NICHT im Repo!),
# oeffentlicher Schluessel wird ins Repo (ssh-ca/user_ca.pub) kopiert.
# PILOT: Schluessel ohne Passphrase, weil nicht interaktiv erzeugt. Fuer den Echtbetrieb
# die CA auf einem Offline-Medium/gesonderten Rechner fuehren und mit Passphrase schuetzen:
#   ssh-keygen -p -f /root/ca-pilot/user_ca
set -e
DIR=$(dirname "$(readlink -f "$0")")
CAD=${CAD:-/root/ca-pilot}
umask 077
mkdir -p "$CAD"; chmod 700 "$CAD"
if [ -e "$CAD/user_ca" ]; then echo "CA existiert schon: $CAD/user_ca (nichts geaendert)"; exit 0; fi
ssh-keygen -q -t ed25519 -N "" -C "praxis-user-ca-PILOT-$(date +%Y)" -f "$CAD/user_ca"
echo 1000 > "$CAD/serial"; : > "$CAD/issued.log"
cp "$CAD/user_ca.pub" "$DIR/user_ca.pub"; chmod 644 "$DIR/user_ca.pub"
echo "CA angelegt: $CAD/user_ca (privat), $DIR/user_ca.pub (oeffentlich)"
ssh-keygen -lf "$CAD/user_ca.pub"
