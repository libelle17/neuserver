#!/bin/bash
# phpwacht.sh - Mail, sobald openSUSE die PHP-Korrektur gegen "PHP2Shell" (CVE-2026-109618/-109619) anbietet.
#
# Eingerichtet 22.10.2026. Betroffen ist PHP bis 8.4.26 (mod_php, hoechstes Risiko); behoben ab FIXVERSION.
# Bis zum Update sind die von aussen freigegebenen Ports 8008/8443 (vhosts.d/fachliches-extern.conf) in
# firewalld auf 192.168.178.0/24 beschraenkt; nach dem Update wieder oeffnen:
#   for p in 8008 8443; do firewall-cmd --permanent --zone=public --remove-rich-rule="rule family=\"ipv4\" \
#     source address=\"192.168.178.0/24\" port port=\"$p\" protocol=\"tcp\" accept"; \
#     firewall-cmd --permanent --zone=public --add-port=$p/tcp; done; firewall-cmd --reload
#
# Aufruf:  phpwacht.sh [-n] [-t]
#   -n   nur anzeigen, nichts mailen, Zustand nicht veraendern
#   -t   Testmail (immer senden, Betreff mit TEST)
# Mails: einmal, wenn das Update im Repository erscheint; einmal, wenn es installiert ist (dann ist der
# cron-Eintrag ueberfluessig). Laeuft nur auf linux1.
EMPFAENGER="diabetologie@dachau-mail.de"
FIXVERSION=8.4.27
ZUSTAND=${PHPWACHT_ZUSTAND:-/var/lib/phpwacht}
NUR_ANZEIGEN=; TESTMAIL=
for a in "$@"; do case "$a" in -n) NUR_ANZEIGEN=1;; -t) TESTMAIL=1;; *) sed -n '2,16p' "$0"; exit 1;; esac; done
h=$(hostname); [ "${h%%.*}" = linux1 ] || { echo "phpwacht.sh laeuft nur auf linux1"; exit 0; }
mailen() { printf '%s\n' "$2" | mail -s "$1" "$EMPFAENGER"; }
# istneu VERSION - wahr, wenn VERSION >= FIXVERSION
istneu() { [ "$(printf '%s\n%s\n' "$FIXVERSION" "$1" | sort -V | head -1)" = "$FIXVERSION" ]; }

INST=$(rpm -q --qf '%{VERSION}' php8 2>/dev/null)
zypper -q --non-interactive refresh -r repo-oss >/dev/null 2>&1
REPO=$(zypper -q --non-interactive se -s -x php8 2>/dev/null | awk -F'|' '$6 ~ /repo-oss/ {gsub(/ /,"",$4); sub(/-.*/,"",$4); print $4}' | sort -V | tail -1)
[ -z "$REPO" ] && { echo "$(date '+%F %T') FEHLER: php8 nicht im Repository gefunden (zypper?)" >&2; exit 2; }
echo "$(date '+%F %T') installiert: $INST, neueste im Repository: $REPO, behoben ab: $FIXVERSION"

STAND=offen
istneu "$REPO" && STAND=verfuegbar
istneu "$INST" && STAND=installiert
ALT=$(cat "$ZUSTAND/stand" 2>/dev/null)
case "$STAND" in
  verfuegbar)  BETREFF="linux1: PHP-Sicherheitsupdate $REPO verfuegbar - bitte einspielen"
               TEXT="Das Update gegen PHP2Shell (CVE-2026-109618/-109619) ist da (installiert: $INST).

  zypper ref && zypper up 'php8*' apache2-mod_php8 && systemctl restart apache2 && php -v

Danach die Ports 8008/8443 wieder freigeben (Befehl im Kopf von /root/bin/phpwacht.sh).";;
  installiert) BETREFF="linux1: PHP $INST installiert - PHP2Shell behoben"
               TEXT="PHP $INST ist installiert. Falls noch nicht geschehen: apache2 neu starten, Ports 8008/8443
wieder freigeben (Befehl im Kopf von /root/bin/phpwacht.sh) und den phpwacht-Eintrag aus der crontab nehmen.";;
esac
[ "$TESTMAIL" ] && { BETREFF="TEST phpwacht: ${BETREFF:-noch kein Update (installiert $INST, Repository $REPO)}"; TEXT=${TEXT:-Testmail}; }
if [ "$NUR_ANZEIGEN" ]; then echo "Stand: $STAND (zuletzt gemeldet: ${ALT:-nichts})"; exit 0; fi
if [ "$TESTMAIL" ] || { [ "$STAND" != offen ] && [ "$STAND" != "$ALT" ]; }; then
  mailen "$BETREFF" "$TEXT" && echo "Mail gesendet an $EMPFAENGER: $BETREFF"
fi
[ "$TESTMAIL" ] || { mkdir -p "$ZUSTAND"; echo "$STAND" > "$ZUSTAND/stand"; }
