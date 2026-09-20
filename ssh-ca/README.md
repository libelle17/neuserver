# SSH-Zertifikate statt verteilter authorized_keys (Pilot)

## Idee
Eine **CA** signiert die öffentlichen Schlüssel der Administratoren und Nutzer einmal. Jeder Server
vertraut nur noch der CA (eine Zeile `TrustedUserCAKeys`) und einer kleinen Liste, welche
**Rolle** ("Principal") sich als welches Konto anmelden darf. Ein neuer PC oder Nutzer braucht
dann **kein `ssh-copy-id` mehr** auf den Servern, nur eine Signatur.

| Principal | darf sich anmelden als | Datei |
|---|---|---|
| `admin`  | root, sturm, schade | `principals/root`, `principals/sturm`, `principals/schade` |
| `sturm`  | sturm | `principals/sturm` |
| `schade` | schade | `principals/schade` |

Zertifikate haben eine **Laufzeit** (Vorgabe 13 Wochen), eine **Seriennummer** (Widerruf) und
sperren Agent-/Port-/X11-Weiterleitung. Optional: `-O source-address=192.168.178.0/24`.

## Dateien
- `ca_init.sh` – legt die CA an (privat: `/root/ca-pilot/`, **nicht im Repo**; öffentlich: `user_ca.pub`)
- `ca_sign.sh` – signiert einen Schlüssel, führt `issued.log`
- `ca_install_host.sh` – richtet einen Rechner ein (`--dry` Vorgabe, `--apply`, `--remove`, `--status`)
- `ca_make_testbundle.sh` / `ca_pilot_test.sh` – Test an einer **eigenen** sshd-Instanz auf
  127.0.0.1:2222 (15 Fälle: Rollen, abgelaufen, noch nicht gültig, Quelladresse, widerrufen,
  fremde CA, ungezeichneter Schlüssel). Der produktive sshd wird nicht berührt.
- `sshd_ca.conf`, `principals/`, `user_ca.pub` – werden von `ca_install_host.sh` installiert.

## Ablauf des Piloten
1. **Test** (erledigt am 20.9.2026 auf linux1, linux0, linux7: 15/15 bestanden):
   `ca_make_testbundle.sh /pfad/testpaket` und dort `./ca_pilot_test.sh`.
2. **Trockenlauf** je Rechner: `ca_install_host.sh` (ändert nichts, prüft mit `sshd -t`).
3. **Aktivieren** zuerst auf linux0: `ca_install_host.sh --apply`. Es **ergänzt** `authorized_keys`,
   ersetzt sie nicht: bestehende Anmeldungen und Sitzungen bleiben. Auf linux7 wird zuvor
   `Include /etc/ssh/sshd_config.d/*.conf` in `/etc/ssh/sshd_config` ergänzt (Sicherung `.vor-ssh-ca`).
4. **Erstes echtes Zertifikat** (auf dem CA-Rechner):
   `ca_sign.sh /pfad/id_ed25519.pub admin-pc07 admin +13w` → `id_ed25519-cert.pub` neben den
   Schlüssel legen (ssh nimmt es automatisch). **In einer zweiten Sitzung** testen:
   `ssh -v root@linux0` – im Log muss `ED25519-CERT` und `Accepted publickey` stehen.
5. Erst wenn das stabil läuft: linux7, dann linux1. Rückbau jederzeit: `ca_install_host.sh --remove`.

## Betrieb
- **Neuer PC/Nutzer:** Schlüsselpaar dort erzeugen (`ssh-keygen -t ed25519`), `.pub` zur CA bringen,
  `ca_sign.sh` mit passendem Principal, Zertifikat zurückbringen. An den Servern ändert sich nichts.
- **Entzug:** Seriennummer aus `issued.log`, KRL erzeugen (`ssh-keygen -k -f revoked.krl -s user_ca.pub spec`,
  Zeile `serial: N`), nach `/etc/ssh/ca/revoked.krl` verteilen, in `sshd_ca.conf` `RevokedKeys` aktivieren.
  Kurze Laufzeiten (z. B. 4–13 Wochen) sind der wichtigere Schutz, weil sich die Liste nicht auf
  ausgeschaltete Rechner verteilt.
- **Aufgabentrennung:** getrennte Zertifikate für Admin- und Alltagskonten, nie ein Admin-Zertifikat
  auf einem Alltags-PC, der Mails/Browser nutzt.

## Sicherheit / offene Punkte
- **Die CA ist das wertvollste Ziel.** Im Pilot liegt sie ohne Passphrase auf linux1. Im Echtbetrieb:
  auf einem Offline-Medium oder einem separaten, nicht vernetzten Rechner, mit Passphrase
  (`ssh-keygen -p -f /root/ca-pilot/user_ca`). Liegt sie auf einem Rechner, der befallen werden
  kann (linux1!), kann ein Angreifer sich selbst Zertifikate ausstellen.
- Danach: `authorized_keys` auf Notfallschlüssel reduzieren, `PasswordAuthentication no` prüfen
  (derzeit `yes` und `PermitRootLogin yes` auf linux0/1/7).
- **Backup-Weg** bleibt eine Einbahnstraße (`backup_ssh_wrapper.sh`), Zertifikate ersetzen das nicht.
- **Windows (ungetestet):** OpenSSH unter Windows kennt `TrustedUserCAKeys` und `AuthorizedPrincipalsFile`
  in `C:\ProgramData\ssh\sshd_config`; Administratorkonten brauchen strenge Rechte auf den Dateien.
- `ca_install_host.sh --apply` ist auf den Rechnern noch **nicht** ausgeführt (nur Trockenlauf); SELinux
  ist aktiv, die Dateien erhalten per `restorecon` den Standardkontext (bei `--apply` prüfen).
