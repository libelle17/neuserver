#!/bin/bash
# bupull_wrapper_mitarbeit.sh - ENTWURF fuer einen ZWEITEN, vom Automatik-Schluessel getrennten
# Zugang fuer die beaufsichtigte Mitarbeit einer Claude-Instanz auf linux0 (oder linux7), wenn
# Gerald dort bewusst eine Schwesterinstanz gestartet hat (s. Bericht an Gerald, 22.9.2026,
# Antwort auf "Sicherheit passwortloser Zugriff linux0->linux1").
#
# STAND 22.9.2026: NUR VORBEREITET. Schluessel erzeugt (/root/.ssh/id_ed25519_mitarbeit[.pub]),
# NICHT in authorized_keys eingetragen, privater Schluessel nirgendwo hinkopiert, nichts im
# Repository (Schluessel sind wie ueblich nicht versioniert). Erst einsetzen, wenn Gerald das wuenscht.
#
# UNTERSCHIED zum Automatik-Schluessel (bupull_wrapper_streng.sh):
#   - Der ist eine ENGE ERLAUBNISLISTE (nur bekannte Sicherungsbefehle) fuer den unbeaufsichtigten,
#     taeglichen Cron-Betrieb - genau dort darf ein kompromittiertes linux0 NICHTS anrichten koennen.
#   - Dieser hier ist eine WEITE VERBOTSLISTE (fast alles erlaubt, wie bisher im Lernmodus) fuer die
#     Mitarbeit einer beaufsichtigten Instanz - sie braucht git, sed, cat, crontab usw., das laesst
#     sich nicht sinnvoll auf eine Erlaubnisliste eindampfen, ohne die Mitarbeit unmoeglich zu machen.
#   - Die Sicherheit kommt hier NICHT vom Wrapper, sondern davon, dass der Zugang (a) ein eigener,
#     vom Automatik-Schluessel getrennter Schluessel ist, (b) nur eingetragen wird, waehrend Gerald
#     eine Sitzung bewusst gestartet hat (Empfehlung: mit expiry-time wie bei zugang_gewaehren.sh,
#     z.B. 24h), (c) protokolliert wird wie der bisherige Lernmodus, (d) eine kurze, harte
#     Verbotsliste hat: das Aendern der SSH-Absicherung selbst und offensichtlich zerstoererische
#     Muster sind auch hier nie erlaubt.
#
# Verbotsliste (nicht vollstaendig gegen einen entschlossenen Angreifer mit dieser Zugangsstufe -
# das ist kein Ersatz fuer die Trennung der Schluessel selbst, nur eine zusaetzliche Bremse):
#   - alles unter /root/.ssh/, /etc/ssh/, sshd-Konfiguration, PAM
#   - /etc/shadow, /etc/passwd, /etc/sudoers* (lesen wie schreiben)
#   - "authorized_keys" oder "sshd_config" als Text irgendwo im Befehl (deckt auch Umwege ab)
#   - dieser Wrapper und bupull_wrapper_streng.sh selbst (/root/bin/bupull_wrapper*.sh),
#     backup_ssh_wrapper.sh - damit sich der Zugang nicht selbst freischalten kann
#   - rm -rf / bzw. auf /, /DATA, /root, /etc ohne weiteren Pfad (grobe Musterpruefung)
#   - curl/wget mit Pipe in eine Shell ("| sh", "| bash")
#   - systemctl stop/disable sshd/postfix (Verfuegbarkeit)
#
# Testschema: teste_wrapper_mitarbeit.sh (Attrappen, wie bei den anderen Wrappern).

LOG=/var/log/backup_pull_wrapper_mitarbeit.log
CMD="$SSH_ORIGINAL_COMMAND"
QUELLE="${SSH_CONNECTION%% *}"
printf '%s [%s] %s\n' "$(date '+%F %T')" "${QUELLE:-?}" "${CMD:-<interaktive Sitzung>}" >>"$LOG" 2>/dev/null

verboten() {
  local c="$1"
  case "$c" in
    *"/.ssh/"*|*"/etc/ssh/"*|*"/etc/shadow"*|*"/etc/passwd"*|*"/etc/sudoers"*) return 0;;
    *"authorized_keys"*|*"sshd_config"*) return 0;;
    *"bupull_wrapper.sh"*|*"bupull_wrapper_streng.sh"*|*"bupull_wrapper_mitarbeit.sh"*|*"backup_ssh_wrapper.sh"*) return 0;;
    *"rm "*"-rf"*|*"rm "*"-fr"*)
      case "$c" in *" /"|*" /DATA"|*" /DATA/"|*" /root"|*" /root/"|*" /etc"|*" /etc/") return 0;; esac;;
    *"| sh"*|*"|sh"*|*"| bash"*|*"|bash"*) return 0;;
    *"systemctl stop sshd"*|*"systemctl disable sshd"*|*"systemctl stop postfix"*|*"systemctl disable postfix"*) return 0;;
  esac
  return 1
}

if [ -z "$CMD" ]; then
  SH="${SHELL:-/bin/bash}"
  exec -a "-${SH##*/}" "$SH"
fi
if verboten "$CMD"; then
  printf '%s [%s] ABGELEHNT-VERBOTSLISTE: %s\n' "$(date '+%F %T')" "${QUELLE:-?}" "$CMD" >>"$LOG" 2>/dev/null
  echo "abgelehnt (Verbotsliste des Mitarbeit-Zugangs): $CMD" >&2
  exit 1
fi
exec "${SHELL:-/bin/bash}" -c "$CMD"
