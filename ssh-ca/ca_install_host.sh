#!/bin/bash
# Richtet die SSH-CA-Anmeldung auf DIESEM Rechner ein (als root).
#   ca_install_host.sh            Trockenlauf (Vorgabe): prueft und zeigt, was passieren wuerde
#   ca_install_host.sh --apply    installieren, sshd neu einlesen (bestehende Sitzungen bleiben)
#   ca_install_host.sh --remove   Rueckbau (Drop-in entfernen, sshd neu einlesen)
#   ca_install_host.sh --status   zeigt die wirksamen sshd-Einstellungen
# Ergaenzt authorized_keys, ersetzt sie nicht -> kein Aussperr-Risiko. Nach --apply IMMER in
# einer ZWEITEN Sitzung testen, bevor die erste geschlossen wird.
set -u
DIR=$(dirname "$(readlink -f "$0")")
ZD=/etc/ssh/ca; DROP=/etc/ssh/sshd_config.d/60-ssh-ca.conf
MODE=${1:---dry}
[ "$(id -u)" = 0 ] || { echo "nur als root"; exit 1; }
HAUPT=/etc/ssh/sshd_config; [ -f "$HAUPT" ] || HAUPT=/usr/etc/ssh/sshd_config
NEEDINC=0; grep -Eq '^[[:space:]]*Include[[:space:]]+/etc/ssh/sshd_config\.d/' "$HAUPT" || NEEDINC=1
rot=$'\e[1;31m'; blau=$'\e[1;34m'; res=$'\e[0m'

case "$MODE" in
--status)
  sshd -T 2>/dev/null | grep -E '^(trustedusercakeys|authorizedprincipalsfile|revokedkeys|authorizedkeysfile|permitrootlogin|passwordauthentication) '
  ls -la "$ZD" "$DROP" 2>&1 | head -12; exit 0;;
--dry)
  [ -f "$DIR/user_ca.pub" ] || { echo "user_ca.pub fehlt (erst ca_init.sh)"; exit 1; }
  T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
  install -d "$T/ca/principals"; cp "$DIR/user_ca.pub" "$T/ca/"; cp "$DIR"/principals/* "$T/ca/principals/"
  # Pruefkonfiguration: Direktiven GANZ OBEN (unterhalb von Match-Bloecken waeren sie unzulaessig)
  { sed "s#/etc/ssh/ca#$T/ca#g" "$DIR/sshd_ca.conf"; cat "$HAUPT"; } > "$T/sshd_config"
  echo "Hauptkonfiguration : $HAUPT   (Include fuer sshd_config.d vorhanden: $([ $NEEDINC = 0 ] && echo ja || echo "NEIN, wird bei --apply oben ergaenzt"))"
  echo "Wuerde anlegen      : $ZD/user_ca.pub, $ZD/principals/{$(ls "$DIR/principals" | tr '\n' ',' | sed 's/,$//')}, $DROP"
  if sshd -t -f "$T/sshd_config" 2>"$T/err"; then echo "${blau}sshd-Syntaxpruefung mit den neuen Direktiven: OK${res}"; else echo "${rot}sshd -t FEHLER:${res}"; cat "$T/err"; exit 1; fi
  echo "Zum Aktivieren: $0 --apply"; exit 0;;
--apply)
  [ -f "$DIR/user_ca.pub" ] || { echo "user_ca.pub fehlt"; exit 1; }
  BAK="$HAUPT.vor-ssh-ca"
  rueckbau() { rm -f "$DROP"; [ -f "$BAK" ] && cp -p "$BAK" "$HAUPT"; }
  install -d -m 755 "$ZD" "$ZD/principals" /etc/ssh/sshd_config.d
  install -m 644 -o root -g root "$DIR/user_ca.pub" "$ZD/user_ca.pub"
  for f in "$DIR"/principals/*; do install -m 644 -o root -g root "$f" "$ZD/principals/$(basename "$f")"; done
  install -m 644 -o root -g root "$DIR/sshd_ca.conf" "$DROP"
  command -v restorecon >/dev/null 2>&1 && restorecon -R "$ZD" "$DROP" 2>/dev/null
  if [ $NEEDINC = 1 ]; then cp -p "$HAUPT" "$BAK"; sed -i '1i Include /etc/ssh/sshd_config.d/*.conf' "$HAUPT"; echo "Include in $HAUPT ergaenzt (Sicherung: $BAK)"; fi
  if ! sshd -t; then echo "${rot}sshd -t fehlgeschlagen -> Rueckbau${res}"; rueckbau; sshd -t; exit 1; fi
  systemctl reload sshd && echo "${blau}sshd neu eingelesen. JETZT in zweiter Sitzung mit Zertifikat testen.${res}"
  sshd -T | grep -E '^(trustedusercakeys|authorizedprincipalsfile) '; exit 0;;
--remove)
  rm -f "$DROP"; [ -f "$HAUPT.vor-ssh-ca" ] && cp -p "$HAUPT.vor-ssh-ca" "$HAUPT" && rm -f "$HAUPT.vor-ssh-ca"
  rm -rf "$ZD"; sshd -t && systemctl reload sshd && echo "Rueckbau erledigt."; exit 0;;
*) sed -n '2,8p' "$0"; exit 1;;
esac
