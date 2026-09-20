#!/bin/bash
# Erzeugt (auf dem CA-Rechner) ein Testpaket mit Wegwerf-Schluesseln und -Zertifikaten fuer
# ca_pilot_test.sh. Der private CA-Schluessel verlaesst den CA-Rechner NICHT.
#   ca_make_testbundle.sh <Zielverzeichnis>
set -e
DIR=$(dirname "$(readlink -f "$0")"); CAD=${CAD:-/root/ca-pilot}; OUT=${1:?Zielverzeichnis angeben}
rm -rf "$OUT"; mkdir -p "$OUT/principals"; chmod 700 "$OUT"
cp "$DIR/user_ca.pub" "$OUT/"; cp "$DIR"/principals/* "$OUT/principals/"; cp "$DIR/ca_pilot_test.sh" "$OUT/"
ssh-keygen -q -t ed25519 -N "" -C fremd-ca -f "$OUT/evil_ca"
n=900000
mk() { # Name Principals Gueltigkeit [weitere ssh-keygen-Optionen]
  local name=$1 pr=$2 val=$3 ca=${CA_OVERRIDE:-$CAD/user_ca}; shift 3
  ssh-keygen -q -t ed25519 -N "" -C "test-$name" -f "$OUT/k_$name"
  n=$((n+1)); ssh-keygen -q -s "$ca" -I "test-$name" -n "$pr" -V "$val" -z $n "$@" "$OUT/k_$name.pub"
  echo $n > "$OUT/serial_$name"
}
mk admin admin +1d
mk sturm sturm +1d
mk schade schade +1d
mk expired admin -3d:-2d
mk notyet admin +1d:+2d
mk srcaddr admin +1d -O source-address=192.0.2.0/24
mk revoked admin +1d
CA_OVERRIDE=$OUT/evil_ca mk fremd admin +1d
ssh-keygen -q -t ed25519 -N "" -C test-plain -f "$OUT/k_plain"
printf 'serial: %s\n' "$(cat "$OUT/serial_revoked")" > "$OUT/krl.spec"
ssh-keygen -q -k -f "$OUT/revoked.krl" -s "$DIR/user_ca.pub" "$OUT/krl.spec"
rm -f "$OUT/evil_ca" "$OUT/evil_ca.pub"
echo "Testpaket: $OUT ($(ls "$OUT" | wc -l) Dateien)"
