#!/bin/bash
# Testet die Zertifikats-Anmeldung an einer EIGENEN sshd-Testinstanz (127.0.0.1:2222, eigene
# Konfiguration, eigener Host-Schluessel). Der produktive sshd wird NICHT beruehrt.
# Jede Ablehnung wird mit dem Grund aus dem sshd-Log ausgegeben (Rolle, abgelaufen, widerrufen,
# Quelladresse, fremde CA ...). PerSourcePenalties ist in der Testinstanz aus, sonst wuerde OpenSSH 10
# nach den ersten Fehlversuchen weitere Verbindungen von 127.0.0.1 schon VOR der Pruefung verwerfen.
# Aufruf im entpackten Testpaket (s. ca_make_testbundle.sh), als root:  ./ca_pilot_test.sh
set -u
B=$(dirname "$(readlink -f "$0")"); PORT=${PORT:-2222}
[ "$(id -u)" = 0 ] || { echo "nur als root"; exit 1; }
W=$(mktemp -d /root/ca-test.XXXXXX); chmod 755 "$W"
SP=""; cleanup() { [ -n "$SP" ] && kill "$SP" 2>/dev/null; rm -rf "$W"; }; trap cleanup EXIT
install -d -m 755 "$W/principals"
install -m 644 "$B/user_ca.pub" "$W/user_ca.pub"; install -m 644 "$B/revoked.krl" "$W/revoked.krl"
for f in "$B"/principals/*; do install -m 644 "$f" "$W/principals/$(basename "$f")"; done
ssh-keygen -q -t ed25519 -N "" -f "$W/hostkey"
cat > "$W/sshd_config" <<EOT
Port $PORT
ListenAddress 127.0.0.1
HostKey $W/hostkey
PidFile $W/sshd.pid
TrustedUserCAKeys $W/user_ca.pub
AuthorizedPrincipalsFile $W/principals/%u
RevokedKeys $W/revoked.krl
AuthorizedKeysFile none
PubkeyAuthentication yes
PasswordAuthentication no
KbdInteractiveAuthentication no
UsePAM no
PermitRootLogin yes
AllowAgentForwarding no
X11Forwarding no
LogLevel VERBOSE
PerSourcePenalties no
MaxAuthTries 6
EOT
sshd -t -f "$W/sshd_config" || { echo "Testkonfiguration ungueltig"; exit 2; }
/usr/sbin/sshd -D -e -f "$W/sshd_config" >"$W/sshd.log" 2>&1 & SP=$!
for i in $(seq 1 30); do ss -ltn 2>/dev/null | grep -q "127.0.0.1:$PORT " && break; sleep 0.3; done
ss -ltn | grep -q "127.0.0.1:$PORT " || { echo "Testinstanz startet nicht:"; tail -5 "$W/sshd.log"; exit 2; }
echo "Host: $(hostname)   Testinstanz 127.0.0.1:$PORT   $(sshd -V 2>&1 | head -1)"
fehl=0; gesamt=0
try() { # Schluessel Konto erwartet(OK|DENY)
  local k=$1 u=$2 exp=$3 out rc got cert="" L0 grund=""
  gesamt=$((gesamt+1))
  [ -f "$B/k_$k-cert.pub" ] && cert="-o CertificateFile=$B/k_$k-cert.pub"
  L0=$(wc -l <"$W/sshd.log")
  out=$(ssh -v -p "$PORT" -i "$B/k_$k" $cert -o IdentitiesOnly=yes -o IdentityAgent=none -o BatchMode=yes \
        -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout=6 \
        "$u@127.0.0.1" 'id -un' 2>"$W/client.err"); rc=$?
  [ "${DEBUG:-}" = "$k" ] && { echo "--- Client-Debug ($k) ---"; grep -E -i 'identity file|certificate|Offering|Skipping|skipping|will attempt|Authentication' "$W/client.err" | cut -c1-150; echo "--- Server-Log ($k) ---"; sleep 0.4; tail -n +$((L0+1)) "$W/sshd.log" | cut -c1-170; }
  if grep -q 'Offering public key.*-CERT' "$W/client.err"; then off=ja; else off=nein; fi
  if [ $rc = 0 ] && [ "$out" = "$u" ]; then got=OK; else got=DENY; fi
  sleep 0.4
  if [ "$got" = DENY ]; then grund=$(tail -n +$((L0+1)) "$W/sshd.log" | grep -E -i 'certificate|principal|revoked|refused|Failed publickey' | head -1 | sed -E 's/^.*(sshd(-session)?\[[0-9]+\]: )//' | cut -c1-95); fi
  if [ "$got" = "$exp" ]; then st="ok    "; else st="FEHLER"; fehl=$((fehl+1)); fi
  printf '%s  %-8s als %-6s erwartet %-4s ergab %-4s Zert. angeboten: %-4s %s\n' "$st" "$k" "$u" "$exp" "$got" "$off" "$grund"
}
try admin   root   OK;   try admin   sturm  OK;   try admin   schade OK
try sturm   sturm  OK;   try sturm   root   DENY; try sturm   schade DENY
try schade  schade OK;   try schade  root   DENY; try schade  sturm  DENY
try expired root   DENY; try notyet  root   DENY; try srcaddr root   DENY
try revoked root   DENY; try fremd   root   DENY; try plain   root   DENY
echo "Ergebnis: $([ $fehl = 0 ] && echo "ALLE $gesamt PRUEFUNGEN BESTANDEN" || echo "$fehl von $gesamt FEHLERHAFT")"
exit $fehl
