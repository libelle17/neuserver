#!/bin/sh
# los.sh – Servereinrichtungs- und Konfigurationsskript
# Copyright Gerald Schade 2018-2026
# Repository: github.com/libelle17/neuserver
#
# Zweck: Automatisierte Einrichtung eines (neuen) Linux-Servers:
#   - Benutzer, Gruppen, Samba, MariaDB, Apache, Drucker
#   - Programme installieren, Laufwerke mounten, Prompt setzen
#   - Konfigurationsdateien verschlüsselt sichern/laden (GitHub)
#   - Fritzbox einbinden, RemotePC installieren, Git-Repos klonen
#
# Aufruf: los.sh [-bs|-bw|-host|-prompt|-mt|-prog|-mariau|-maria|
#                 -mariai|-marianeu|-smb|-must|-fritz|-firebird|
#                 -teamviewer|-remotepc|-ks|-kl|-knl|-cron|-v|-h]
# Ohne Parameter: vollständige Einrichtung
#
# Voraussetzungen:
#   - Root-Rechte
#   - /root/neuserver/vars (von configure erzeugt)
#   - /root/neuserver/gruppe (enthält Gruppenname, z.B. "praxis")
#   - SSH-Schlüssel für GitHub in ~/.ssh/id_ed25519_git
#
# TODO: /home/schade/.wincredentials, /amnt/virtwin...,
#       mysql-Daten auf Reserveserver, systemctl enable autofs
#       (autofs: s. /etc/auto.master, statt cifs)

# ---- Farb-Escapes für Terminalausgaben ----
# Verwendung: printf "%b%s%b\n" "$blau" "Text" "$reset"
blau="\033[1;34m";   # hellblau, für Dateinamen/Werte
dblau="\033[0;34;1;47m"; # dunkelblau auf weißem Hintergrund, für Funktionsnamen
rot="\033[1;31m";    # rot, für Fehler/Warnungen
gruen="\033[0;32m";  # grün, für Erfolgsmeldungen
reset="\033[0m";     # Farbe zurücksetzen

# ---- Globale Variablen ----
prog="";             # aktuell laufendes Programm
obnmr=1;             # ob zypper --no-gpg-checks verwendet werden soll
ftb="/etc/fstab";    # Pfad zur fstab
GITACC=libelle17;    # GitHub-Accountname
AUFRUFDIR=$(pwd);    # Verzeichnis aus dem das Script aufgerufen wurde
# Eigenen Skriptpfad ermitteln (readlink -f für absolute Pfadauflösung):
meingespfad="$(readlink -f "$0")"; # Name dieses Programms samt Pfad
[ "$meingespfad" ]||meingespfad="$(readlink -m "$0")";
meinpfad="$(dirname $meingespfad)"; # Pfad dieses Programms ohne Name
instvz="/root/neuserver"
wzp="$instvz/wurzelplatten"; # Liste gefundener root-Verzeichnisse (für musterserver)
Dw="/root/Downloads";      # lokales Download-Verzeichnis
gruppe=$(cat $instvz/gruppe); # Hauptgruppe (z.B. "praxis")
q0="/DATA/down /DATA/daten/down"; # Suchpfade für Downloads auf DATA-Partition
spf=/DATA/down;            # Server-Pfad für Dateiübertragungen
tdpf="/DATA/turbomed";     # Turbomed-Dokumentenpfad
musr=praxis;               # Standard-Datenbankbenutzer
obschreiben=0;             # 1 = Konfiguration neu schreiben

# ============================================================
# ausf() – zentraler Befehlsausführer mit Logging
# $1 = auszuführender Befehl (Shell-String)
# $2 = Anzeigefarbe (optional; wenn gesetzt wird Befehl immer angezeigt)
# $3 = "direkt" (optional; Ergebnis nicht in $resu speichern,
#      z.B. bei Pipe-Befehlen oder "... && var=1")
# Ergebnis: $ret = Exit-Code, $resu = stdout des Befehls
# Verwendung: ausf "befehl" "${blau}" [direkt]
# Tipp: Sonderzeichen im Befehl maskieren: \ → \\, $ → \$, " → \"
# ============================================================
ausf() {
	[ "$verb" -o "$2" ]&&{ anzeige=$(echo "$2$1$reset\n"|sed 's/%/%%/'); printf "$anzeige";}; # % escapen damit printf es nicht als Formatzeichen interpretiert
	if test "$3"; then 
    eval "$1"; 
  else 
    resu=$(eval "$1"); # Ergebnis in $resu speichern
  fi;
  ret=$?; # Exit-Code merken
  [ "$verb" ]&&{
    printf "ret: $blau$ret$reset"
    [ "$3" ]||printf ", resu: \"$blau$resu$reset\"";
    printf "\n";
  }
} # ausf

# ausfd() – Kurzform von ausf() mit direkt-Flag (kein $resu)
ausfd() {
  ausf "$1" "$2" direkt;
} # ausfd

# Befehlszeilenparameter auswerten
commandline() {
	obneu=0; # 1=Fritzboxbenutzer und Passwort neu eingeben, s.u.
	obteil=0;# nur Teil des Scripts soll ausgeführt werden;
  obbs=0; # bildschirm aufrufen
  obbw=0 # bleibwach: kein Suspend/Hibernate
  obhost=0; # host setzen
  obprompt=0; # prompt setzen
  obmt=0; # nur Laufwerke sollen gemountet werden
  obprog=0; # nur Programme sollen installiert werden
  obtm=0; # ob turbomed installiert werden soll
	obmyuser=0; # nur mysql und Benutzer sollen eingerichtet werden
	obmysql=0; # nur mysql soll eingerichtet werden und ggf. letzte Daten laden
	obmysqlneu=0; # nur mysql mit Neuübertragung der Daten
	obmysqli=0; # nur mysql soll eingerichtet werden, jede Datenbank geprüft
  obsmb=0; # nur smbconf soll aufgerufen werden
  obmust=0; # ob von musterserver kopiert werden soll
  obmustneu=0; # musterserver mit Überschreiben vorhandener Dateien
  obfritz=0; # ob fritzbox eingehaengt werden soll
  obfb=0; # Firebird
  obtv=0; # Teamviewer
  obrpc=0; # RemotePC Fernwartung
  obkonfigsp=0; # Konfiguration sichern
  obkonfiglad=0; # Konfiguration laden
  obkonfignl=0; # Konfiguration neu laden
  obcron=0; # crontab sichern/übernehmen
  gespar="$@"
  verb=0;
	while [ $# -gt 0 ]; do
    para=$(echo "$1"|sed 's;^[-/];;');
		case $para in
			neu|new) obneu=1;obschreiben=1;;
			v|-verbose) verb=1;;
			h|-h|-hilfe|-help|?|-?)
        printf "Programm $blau$0$reset: konfiguriert einen (neuen) Linuxserver, oder ruft mit Befehlszeilenparametern Teile davon auf,\n";
        printf "  zusammengeschrieben von: Gerald Schade 2018-22. Benutzung:\n";
				printf "$blau$0 [-bs ][-host ][-prompt ][-mt ][-prog ][-turbomed ][-mariau ][-maria ][-mariai ][-marianeu ][-smb ][-mus ][-fritz ][-firebird ][-teamviewer ][-v ][-h ]$reset\n";
				printf "  $blau-bs$reset: richtet den Bildschirm ein\n";
        printf "  $blau-bw$reset: verhindert Suspend/Hibernate/Bildschirmschoner\n";
        printf "  $blau-host$reset: richtet den Hostnahmen im LAN ein\n";
        printf "  $blau-prompt$reset: richtet die Eingabeaufforderung ein\n";
        printf "  $blau-mt$reset: konfiguriert /etc/fstab zum Mounten der Laufwerke\n";
        printf "  $blau-prog$reset: lädt notwendige Programme aus dem Repository und von github\n";
        printf "  $blau-turbomed$reset: richtet Turbomed ein\n";
        printf "  $blau-mariau$reset: richtet mariadb ein\n";
        printf "  $blau-maria$reset: richtet mariadb ein und lädt ggf. den Datenbankinhalt aus den jüngsten Dateien in /DATA/sql\n";
        printf "  $blau-marianeu$reset: richtet mariadb ein und lädt den Datenbankinhalt aus den jüngsten Dateien in /DATA/sql\n";
        printf "  $blau-mariai$reset: lädt den Datenbankinhalt aus den jüngsten Dateien in /DATA/sql\n";
        printf "  $blau-smb$reset: richtet Samba ein\n";
        printf "  $blau-must$reset: kopiert vom Musterserver\n";
        printf "  ${blau}-mustneu${reset}: wie -must, aber überschreibt vorhandene Dateien\n";
        printf "  $blau-fritz$reset: hängt die Fritzbox ein\n";
        printf "  $blau-firebird$reset: richtet firebird ein\n";
        printf "  $blau-teamviewer$reset: richtet den Teamviewer ein\n";
        printf "  ${blau}-remotepc${reset}: installiert und richtet RemotePC ein\n";
        printf "  $blau-cron$reset: sichert/überträgt crontab vom Quellserver\n";
        printf "  $blau-ks$reset: sichert Konfigurationsdateien im eigenen Repository\n";
        printf "  $blau-kl$reset: lädt Konfigurationsdateien\n";
        printf "  ${blau}-knl${reset}: lädt Konfigurationsdateien neu (überschreibt vorhandene)\n";
        printf "  $blau-vi$reset: lädt dieses Programm in vi(m).\n";
        printf "  $blau-v$reset: wird gesprächiger\n";
        printf "  $blau-h$reset: zeigt diese Hilfe an\n";
        exit;;
      vi) vi $0 -pNu .exrc;
        exit;;
			*) obteil=1;
				case $para in
          bs) obbs=1;;
          bw) obbw=1;;
          host) obhost=1;;
          prompt) obprompt=1;;
          mt) obmt=1;;
          ks) obkonfigsp=1;;
          kl) obkonfiglad=1;;
          knl) obkonfignl=1;;
          prog) obprog=1;;
          turbomed) obtm=1;;
          mariau) obmyuser=1;;
					maria|mariadb|mysql) obmysql=1;;
					marianeu|mysqlneu) obmysqlneu=1;;
          mariai|mysqli) obmysqli=1;;
          smb) obsmb=1;;
          must) obmust=1;;
          mustneu) obmustneu=1;;
          fritz) obfritz=1;;
          firebird) obfb=1;;
          teamviewer) obtv=1;;
          remotepc|rpc) obrpc=1;;
          cron) obcron=1;;
        esac;;
		esac;
		[ "$verb" = 1 ]&&printf "Parameter: $blau-v$reset => gesprächig\n";
		shift;
	done;
	if [ "$verb" ]; then
		printf "obneu: $blau$obneu$reset\n";
		printf "obschreiben: $blau$obschreiben$reset\n";
    [ $obteil = 1 ]&& printf "obteil: ${blau}1$reset\n" || printf "obteil: ${blau}0$reset\n"
		[ "$obbs" = 1 ]&& printf "obbs: ${blau}1$reset\n"
		[ "$obhost" = 1 ]&& printf "obhost: ${blau}1$reset\n"
		[ "$obprompt" = 1 ]&& printf "obprompt: ${blau}1$reset\n"
		[ "$obmt" = 1 ]&& printf "obmt: ${blau}1$reset\n"
		[ "$obprog" = 1 ]&& printf "obprog: ${blau}1$reset\n"
		[ "$obmyuser" = 1 ]&& printf "obmyuser: ${blau}1$reset\n"
		[ "$obmysql" = 1 ]&& printf "obmysql: ${blau}1$reset\n"
		[ "$obmysqli" = 1 ]&& printf "obmysqli: ${blau}1$reset\n"
		[ "$obmysqlneu" = 1 ]&& printf "obmysqlneu: ${blau}1$reset\n"
		[ "$obsmb" = 1 ]&& printf "obsmb: ${blau}1$reset\n"
		[ "$obmust" = 1 ]&& printf "obmust: ${blau}1$reset\n"
		[ "$obfritz" = 1 ]&& printf "obfritz: ${blau}1$reset\n"
    [ "$obmustneu" = 1 ]&& printf "obmustneu: ${blau}1$reset\n"
    [ "$obtm" = 1 ]&&     printf "obtm: ${blau}1$reset\n"
    [ "$obfb" = 1 ]&&     printf "obfb: ${blau}1$reset\n"
    [ "$obtv" = 1 ]&&     printf "obtv: ${blau}1$reset\n"
    [ "$obrpc" = 1 ]&&    printf "obrpc: ${blau}1$reset\n"
    [ "$obkonfigsp" = 1 ]&&printf "obkonfigsp: ${blau}1$reset\n"
    [ "$obkonfiglad" = 1 ]&&printf "obkonfiglad: ${blau}1$reset\n"
    [ "$obkonfignl" = 1 ]&&printf "obkonfignl: ${blau}1$reset\n"
    [ "$obcron" = 1 ]&&   printf "obcron: ${blau}1$reset\n"
    [ "$obbw" = 1 ]&&     printf "obbw: ${blau}1$reset\n"
	fi;
} # commandline

variablen() {
 printf "${dblau}variablen$reset()\n";
 qverz=/root/neuserver
 [ -s "$instvz/vars" ]||{ echo $instvz/vars fehlt, rufe auf: sh $instvz/configure; sh configure;}
 while :; do
  sed 's/:://;/\$/d;s/=/="/;s/$/"/;s/""/"/g;s/="$/=""/' "$instvz/vars" >"$instvz/shvars"
  . "$instvz/shvars"
  if test "$("$instvz/configure" nuros)" != "$OSNR"; then "$instvz/configure";:;else break;fi;
 done;
 HOMEORIG="$(getent passwd $(logname 2>/dev/null||loginctl user-status|sed -n '1s/\(.*\) .*/\1/p'||whoami)|cut -d: -f6)"; # ~  # $HOME
 loscred="$HOME/.loscred"; # ~  # $HOME
 mypwd="$HOME/.mysqlpwd";
 phppwd="/srv/www/phppwd.php";
 test -f "$loscred"&&. "$loscred";
 srv0=; # zur Sicherheit
 mysqlbef=$(which mariadb 2>/dev/null||which mysql 2>/dev/null||echo mysql);
} # variablen

# VORBEDINGUNG: GPG-Passphrase einmalig setzen:
#   read -s GPGPASS; echo "$GPGPASS" > /root/.gpgpass; chmod 600 /root/.gpgpass
#   Dann /root/.gpgpass in /root/neuserver/.gitignore eintragen!
#
# ============================================================
# Aufruf: los.sh -ks
# ------------------------------------------------------------

konfig_sichern() {
  printf "${dblau}konfig_sichern${reset}()\n";
  KVZB="$instvz/konfig";
  GPGPASS_FILE="$HOME/.gpgpass";

  # GPG-Passphrase prüfen / abfragen:
  if [ ! -f "$GPGPASS_FILE" ]; then
    printf "${rot}GPG-Passphrase fehlt.${reset} Bitte eingeben (wird in ${blau}$GPGPASS_FILE${reset} gespeichert):\n";
    stty -echo; read GPGPASS; stty echo; printf "\n";
    printf "%s" "$GPGPASS" >"$GPGPASS_FILE";
    chmod 600 "$GPGPASS_FILE";
    printf "Gespeichert in ${blau}$GPGPASS_FILE${reset}\n";
  fi;

  mkdir -p "$KVZB/offen" "$KVZB/verschluesselt";

  # ---- 1) Unkritische Dateien – offen sichern ----
  # cp -a statt cp -au: immer den aktuellen $HOME-Stand sichern
  for f in \
    "$HOME/.gitconfig" \
    "$HOME/.gtkrc-2.0" \
    "$HOME/.wget-hsts" \
    ; do
    [ -f "$f" ] && cp -a "$f" "$KVZB/offen/" && \
      printf "gesichert (offen): ${blau}$(basename "$f")${reset}\n";
  done;

  # .vim-Verzeichnis – komplett ersetzen um Doppelkopie zu vermeiden:
  [ -d "$HOME/.vim" ] && {
    rm -rf "$KVZB/offen/.vim";
    cp -a "$HOME/.vim" "$KVZB/offen/.vim";
    printf "gesichert (offen): ${blau}.vim/${reset}\n";
  };

  # KDE kcminputrc – unkritisch:
  [ -f "$HOME/.config/kcminputrc" ] && {
    mkdir -p "$KVZB/offen/config";
    cp -a "$HOME/.config/kcminputrc" "$KVZB/offen/config/";
    printf "gesichert (offen): ${blau}.config/kcminputrc${reset}\n";
  };

  # ---- 2) Sensible Dateien – verschlüsselt sichern ----
  TMPDIR_KRYPT=$(mktemp -d);
  geaendert=;
  for f in \
    "$HOME/.fbcredentials" \
    "$HOME/.tr64cred" \
    "$HOME/.loscred" \
    "$HOME/.mariadbpwd" \
    "$HOME/.mariadbrpwd" \
    "$HOME/.modbpwd" \
    "$HOME/.mysqlpwd" \
    "$HOME/.mysqlrpwd" \
    "$HOME/.sturm" \
    ; do
    [ -f "$f" ] && {
      cp "$f" "$TMPDIR_KRYPT/";
      printf "vorgemerkt (verschlüsselt): ${blau}$(basename "$f")${reset}\n";
      geaendert=1;
    };
  done;

  # .gnupg – komplett (privater GPG-Schlüssel!):
  [ -d "$HOME/.gnupg" ] && {
    cp -a "$HOME/.gnupg" "$TMPDIR_KRYPT/.gnupg";
    printf "vorgemerkt (verschlüsselt): ${blau}.gnupg/${reset}\n";
    geaendert=1;
  };

  # Programmkonfigurationen – in ~/.config/ und ~/  suchen:
  # Programme legen ihre .conf-Dateien je nach Version verschieden ab
  for prog in \
    anrliste auffaell autofax berein dicom fbfax impgl \
    labimp labpath pznbdt termine; do
    # Erst in ~/.config/ suchen, dann in ~/
    for f in "$HOME/.config/${prog}.conf" "$HOME/${prog}.conf"; do
      [ -f "$f" ] && {
        cp "$f" "$TMPDIR_KRYPT/${prog}.conf";
        printf "vorgemerkt (verschlüsselt): ${blau}${prog}.conf${reset} (aus $(dirname $f))\n";
        geaendert=1;
        break; # nur einmal sichern ($.config/ hat Vorrang)
      };
    done;
  done;

  # Alles verschlüsseln:
  if [ "$geaendert" ]; then
    ARCHIV="$TMPDIR_KRYPT/konfig_sensibel.tar";
    tar cf "$ARCHIV" -C "$TMPDIR_KRYPT" \
      $(ls -A "$TMPDIR_KRYPT" | grep -v "konfig_sensibel");
    gpg --batch --yes --passphrase-file "$GPGPASS_FILE" \
      --symmetric --cipher-algo AES256 \
      --output "$KVZB/verschluesselt/sensibel.tar.gpg" \
      "$ARCHIV" && \
      printf "${gruen}verschlüsselt: ${blau}$KVZB/verschluesselt/sensibel.tar.gpg${reset}\n" || \
      printf "${rot}Verschlüsselung fehlgeschlagen!${reset}\n";
  fi;
  rm -rf "$TMPDIR_KRYPT";

  # .gitignore sicherstellen – nur .gpgpass ignorieren:
  GI="$instvz/.gitignore";
  grep -q "^\.gpgpass$" "$GI" 2>/dev/null || printf ".gpgpass\n" >>"$GI";
  sed -i '/^konfig\/verschluesselt\/sensibel\.tar\.gpg$/d' "$GI" 2>/dev/null;

  # ---- 3) Direkt nach GitHub pushen ----
  if [ -d "$instvz/.git" ]; then
    printf "Committe und pushe ${blau}konfig/${reset} nach GitHub ...\n";
    git -C "$instvz" reset HEAD 2>/dev/null||true;
    git -C "$instvz" add konfig/ .gitignore 2>/dev/null;
    if git -C "$instvz" diff --cached --quiet 2>/dev/null; then
      printf "Keine Änderungen in ${blau}konfig/${reset} – kein Commit nötig.\n";
    else
      git -C "$instvz" commit --allow-empty \
        -m "konfig_sichern: $(date '+%Y-%m-%d %H:%M')" && \
        printf "${gruen}Commit erstellt${reset}\n" || \
        printf "${rot}Commit fehlgeschlagen${reset}\n";
    fi;
    git -C "$instvz" fetch origin master 2>/dev/null||true;
    git -C "$instvz" merge -X ours origin/master \
      -m "konfig_sichern: $(date '+%Y-%m-%d %H:%M')" 2>/dev/null||true;
    git -C "$instvz" push 2>&1 && \
      printf "${gruen}GitHub aktualisiert${reset}\n" || \
      printf "${rot}git push fehlgeschlagen – manuell: make git${reset}\n";
  else
    printf "${rot}$instvz ist kein git-Repository – kein push möglich${reset}\n";
  fi;
  printf "${gruen}konfig_sichern abgeschlossen.${reset}\n";
} # konfig_sichern

# ------------------------------------------------------------

konfig_laden() {
  printf "${dblau}konfig_laden${reset}()\n";
  KVZB="$instvz/konfig";
  GPGPASS_FILE="$HOME/.gpgpass";

  # $1=neu: vorhandene Dateien überschreiben:
  _ueberschreiben=;
  [ "$1" = "neu" ] && {
    _ueberschreiben=1;
    printf "Modus: ${rot}überschreibe vorhandene Dateien${reset}\n";
  };

  # ---- 0) Aktuelle Konfiguration von GitHub holen ----
  # git show liest direkt aus Remote-Commit ohne Index zu verändern
  # → kein Merge-Konflikt möglich
  if [ -d "$instvz/.git" ]; then
    printf "Hole aktuelle Konfiguration von GitHub ...\n";
    git -C "$instvz" fetch origin master 2>/dev/null;
    if [ $? -eq 0 ]; then
      # sensibel.tar.gpg immer holen:
      git -C "$instvz" show origin/master:konfig/verschluesselt/sensibel.tar.gpg \
        >"$KVZB/verschluesselt/sensibel.tar.gpg" 2>/dev/null && \
        printf "${gruen}sensibel.tar.gpg aktualisiert${reset}\n" || \
        printf "${rot}sensibel.tar.gpg konnte nicht geholt werden – verwende lokalen Stand${reset}\n";
      # Bei -knl: offen/-Verzeichnis ebenfalls holen:
      if [ "$_ueberschreiben" ]; then
        for _gitpfad in $(git -C "$instvz" ls-tree -r --name-only \
            origin/master konfig/offen/ 2>/dev/null); do
          mkdir -p "$instvz/$(dirname "$_gitpfad")";
          git -C "$instvz" show "origin/master:$_gitpfad" \
            >"$instvz/$_gitpfad" 2>/dev/null;
        done;
        printf "${gruen}konfig/offen/ aktualisiert${reset}\n";
      fi;
    else
      printf "${rot}git fetch fehlgeschlagen – verwende lokalen Stand${reset}\n";
    fi;
  else
    printf "${rot}$instvz ist kein git-Repository – kein fetch möglich${reset}\n";
  fi;

  # Hilfsfunktion: Datei kopieren mit/ohne Überschreiben:
  _kopierdatei() {
    _quelle="$1"; _ziel="$2"; _label="${3:-$_ziel}";
    if [ ! -e "$_ziel" ] || [ "$_ueberschreiben" ]; then
      cp -a "$_quelle" "$_ziel";
      chmod 600 "$_ziel" 2>/dev/null;
      [ "$_ueberschreiben" ] && \
        printf "überschrieben: ${blau}$_label${reset}\n" || \
        printf "wiederhergestellt: ${blau}$_label${reset}\n";
    else
      printf "bereits vorhanden: ${blau}$_label${reset} – übersprungen\n";
    fi;
  };

  # ---- 1) Unkritische Dateien wiederherstellen ----
  if [ -d "$KVZB/offen" ]; then
    for f in "$KVZB/offen/".[a-z]*; do
      [ -f "$f" ] || continue;
      ziel="$HOME/$(basename "$f")";
      _kopierdatei "$f" "$ziel";
    done;

    # .vim-Verzeichnis:
    if [ -d "$KVZB/offen/.vim" ]; then
      if [ ! -d "$HOME/.vim" ] || [ "$_ueberschreiben" ]; then
        rm -rf "$HOME/.vim";
        cp -a "$KVZB/offen/.vim" "$HOME/.vim";
        printf "wiederhergestellt: ${blau}$HOME/.vim/${reset}\n";
      else
        printf "bereits vorhanden: ${blau}$HOME/.vim/${reset} – übersprungen\n";
      fi;
    fi;

    # kcminputrc:
    if [ -f "$KVZB/offen/config/kcminputrc" ]; then
      mkdir -p "$HOME/.config";
      _kopierdatei \
        "$KVZB/offen/config/kcminputrc" \
        "$HOME/.config/kcminputrc";
    fi;
  fi;

  # ---- 2) Sensible Dateien entschlüsseln ----
  ARCHIV_GPG="$KVZB/verschluesselt/sensibel.tar.gpg";
  [ -f "$ARCHIV_GPG" ] || {
    printf "${rot}Kein verschlüsseltes Archiv gefunden: ${blau}$ARCHIV_GPG${reset}\n";
    return 0;
  };

  # Passphrase abfragen falls fehlend:
  if [ ! -f "$GPGPASS_FILE" ]; then
    printf "GPG-Passphrase für ${blau}$ARCHIV_GPG${reset} eingeben:\n";
    stty -echo; read GPGPASS; stty echo; printf "\n";
    printf "%s" "$GPGPASS" >"$GPGPASS_FILE";
    chmod 600 "$GPGPASS_FILE";
  fi;

  TMPDIR_KRYPT=$(mktemp -d);
  gpg --batch --yes --passphrase-file "$GPGPASS_FILE" \
    --decrypt "$ARCHIV_GPG" | tar xf - -C "$TMPDIR_KRYPT" 2>/dev/null;
  if [ $? -ne 0 ]; then
    printf "${rot}Entschlüsselung fehlgeschlagen – Passphrase prüfen!${reset}\n";
    rm -rf "$TMPDIR_KRYPT";
    return 1;
  fi;

  # Dateien kopieren:
  mkdir -p "$HOME/.config";
  for f in "$TMPDIR_KRYPT/"* "$TMPDIR_KRYPT/".*; do
    [ -e "$f" ] || continue;
    bn=$(basename "$f");
    [ "$bn" = "." ] || [ "$bn" = ".." ] && continue;
    case "$bn" in
      # Passwort-Dateien nie überschreiben:
      .mysqlpwd|.mysqlrpwd|.mariadbpwd|.mariadbrpwd|.modbpwd)
        if [ ! -e "$HOME/$bn" ]; then
          _kopierdatei "$f" "$HOME/$bn" "sensibel: $HOME/$bn";
        else
          printf "Passwort-Datei ${blau}$HOME/$bn${reset} – nie überschreiben\n";
        fi;;
      # Programmkonfigurationen nach ~/.config/ (dort werden sie erwartet):
      *.conf)
        ziel="$HOME/.config/$bn";
        _kopierdatei "$f" "$ziel" "sensibel: $ziel";;
      # Alle anderen nach $HOME/:
      *)
        ziel="$HOME/$bn";
        _kopierdatei "$f" "$ziel" "sensibel: $ziel";;
    esac;
  done;

  rm -rf "$TMPDIR_KRYPT";
  printf "${gruen}konfig_laden abgeschlossen.${reset}\n";
} # konfig_laden

# ============================================================
# D) In ~/neuserver/Makefile – git-Target ergänzen
# ============================================================
# git: ...
#     sh $(INSTVZ)/los.sh -ks   # Configs sichern vor Push
#     git add konfig/
#     -git add .gitignore
#     ... (rest wie bisher)
#
# wobei INSTVZ=/root/neuserver

# ============================================================
# E) Einmalige Einrichtung – auf linux0 ausführen:
# ============================================================
# printf "Bitte GPG-Passphrase eingeben (mind. 20 Zeichen):\n"
# stty -echo; read GPGPASS; stty echo
# printf "%s" "$GPGPASS" > /root/.gpgpass
# chmod 600 /root/.gpgpass
# # Passphrase sicher aufbewahren (Passwort-Manager o.ä.)!
speichern() {
	printf "${dblau}obschreiben$reset()obschreiben: $obschreiben, loscred: $loscred\n";
	if test $obschreiben -ne 0; then
	  printf "muser=$musr\n"  >"$loscred";
	  printf "mpwd=$mpwd\n"  >>"$loscred";
	  printf "mroot=$mroot\n" >>"$loscred";
	  printf "mrpwd=$mrpwd\n" >>"$loscred";
	  printf "arbgr=$arbgr\n" >>"$loscred";
	  printf "srv0=$srv0\n"   >>"$loscred";

    printf "[client]\n" >"$mypwd";
    printf "user=$musr\n" >"$mypwd";
    printf "password=$musr\n" >"$mypwd";

    printf "<?php " >"$phppwd";
    printf " $user=$musr\n" >>"$phppwd";
    printf " $pwt=$mpwd\n" >>"$phppwd";
    printf "?>" >"$phppwd";
	fi;
} # speichern

bleibwach() {
  printf "${dblau}bleibwach$reset()\n";
  geaendert=;
  # 1) systemd-Targets maskieren – nur wenn noch nicht maskiert
  for tgt in sleep.target suspend.target hibernate.target hybrid-sleep.target; do
    if ! systemctl is-enabled "$tgt" 2>/dev/null | grep -q "masked"; then
      systemctl mask "$tgt" 2>/dev/null;
      printf "maskiert: $blau$tgt$reset\n";
      geaendert=1;
    fi;
  done;
  # 2) logind-Konfiguration – nur schreiben wenn Inhalt abweicht
  KD=/etc/systemd/logind.conf.d;
  KF=$KD/10-nosuspend.conf;
  mkdir -p "$KD";
  NEWINH="[Login]
IdleAction=ignore
HandleLidSwitch=ignore
HandleLidSwitchExternalPower=ignore
HandleSuspendKey=ignore
HandleHibernateKey=ignore";
  if [ ! -f "$KF" ] || [ "$(cat "$KF")" != "$NEWINH" ]; then
    printf "%s\n" "$NEWINH" >"$KF";
    printf "geschrieben: $blau$KF$reset\n";
    geaendert=1;
  else
    printf "unverändert: $blau$KF$reset\n";
  fi;
  # 3) logind nur neu starten wenn etwas geändert wurde
  [ "$geaendert" ] && systemctl restart systemd-logind && \
    printf "${gruen}systemd-logind neu gestartet$reset\n";
} # bleibwach


firebird() {
	printf "${dblau}firebird$reset()\n";
	unset Vorv;
	unset Aktv;
	# zypper se -i firebird >/dev/null 2>&1 && Vorv=1;
	# sleep 10;
	ausfd "$insse FirebirdSS >/dev/null 2>&1 && Aktv=1"; # zypper se -i FirebirdSS >/dev/null 2>&1 && Aktv=1;
	[ "$verb" ]&& echo Vorv: $Vorv;
	[ "$verb" ]&& echo Aktv: $Aktv;
	[ ! $Aktv ]&&{
		ausf "systemctl stop firebird 2>/dev/null && sleep 10";
		ausf "$upr firebird"; # zypper rm
	  ausf "[ -r /usr/lib/libstdc++.so.5 ]||eval $instp ./libstdc++33-32bit-3.3.3-41.1.3.x86_64.rpm"; # zypper in 
		ausf "pkill fbguard";
		ausf "pkill fbserver";
		ausf "eval $insg ./FirebirdSS-2.1.7.18553-0.i686.rpm";
  }
  initfb=/etc/init.d/firebird;
  [ ! -f "$initfb" ]&&{
		ausf "cp ./misc/firebird.init.d.suse $initfb";
		ausf "chown root.root $initfb";
		ausf "chmod 775 $initfb";
		ausf "rm -f /usr/sbin/rcfirebird";
		ausf "ln -s $initfb /usr/sbin/rcfirebird";
		ausf "systemctl daemon-reload";
		ausf "systemctl start firebird";
		ausf "$instp libreoffice-base libreoffice-base-drivers-firebird"; # zypper in 
	}
} # firebird

setzhost() {
  printf "${dblau}setzhost$reset()\n";
  # wenn Hostname z.B. linux-8zyu o.ä., dann korrigieren;
  case $(hostname) in
  *-*|linux|linux.*|localhost*) {
      hostnamectl;
      printf "${blau}gewünschter Servername, dann Enter:$reset "; read srvhier;
      hostnamectl set-hostname "$srvhier";
      export HOST="$srvhier";
      hostnamectl; 
  };
  esac;
  # wake on lan erlauben
  mac=$(ip link show|sed -n '/^[0-9]*: \(eth\|en\)[^:]*:/{n;s/.*link\/ether \([^ ]*\).*/\1/p}'|head -n1);
  [ "$verb" ]&&printf "${blau}mac: ${reset}$mac\n";
  if [ "$mac" ]; then
    dat="/etc/systemd/network/50-wired.link";
    [ "$verb" ]&&printf "${blau}dat: ${reset}$dat\n";
    li=101; for i in $(seq $((li-1)) -1 1); do if [ -f ${dat}_$i ]; then mv ${dat}_$i ${dat}_$li; fi; li=$i; done;
    [ -f $dat ]&&mv $dat ${dat}_1;
    echo "[Match]" >"$dat";
    echo "MACAddress=$mac" >>"$dat";
    echo "" >>"$dat";
    echo "[Link]" >>"$dat";
    echo "NamePolicy=kernel database onboard slot path" >>"$dat";
    echo "MACAddressPolicy=persistent" >>"$dat";
    echo "WakeOnLan=magic" >>"$dat";
  fi;
} # setzhost

setzbenutzer() {
  printf "${dblau}setzbenutzer$reset(), gruppe: $gruppe\n";
  pruefgruppe $gruppe
  setzinstprog;
  $psuch samba 2>/dev/null||$instp samba
  systemctl start smb 2>/dev/null||systemctl start smbd 2>/dev/null;
  systemctl enable smb 2>/dev/null||systemctl enable smbd 2>/dev/null;
  systemctl start nmb 2>/dev/null||systemctl start nmbd 2>/dev/null;
  systemctl enable nmb 2>/dev/null||systemctl enable nmbd 2>/dev/null;
  while read -r zeile <&3; do
    user=${zeile%% \"*};
    comm=\"${zeile#* \"};
    pruefuser $user "$comm";
  done 3<"$instvz/benutzer";
} # setzbenutzer

setzpfad() {
  printf "${dblau}setzpfad$reset()\n";
  RB=/root/bin;
  # 1) /etc/environment (systemweit, wirkt nach nächstem Login)
  EEN=/etc/environment;
  if grep -q "^PATH=" "$EEN" 2>/dev/null; then
    grep -q "$RB" "$EEN" 2>/dev/null || \
      sed -i.bak '/^PATH=/{s/=["'\'']\+\(.*\)["'\'']\+/="\1:'$(echo $RB|sed "s/\//\\\\\//g")'"/}' "$EEN";
  else
    echo PATH=\"$PATH:$RB\" >>"$EEN";
  fi;
  # 2) /etc/profile.d/ (wird bei jedem Login-Shell-Start ausgeführt)
  PPD=/etc/profile.d/rootbin.sh;
  if [ ! -f "$PPD" ] || ! grep -q "$RB" "$PPD" 2>/dev/null; then
    printf '# /root/bin in PATH aufnehmen\ncase ":$PATH:" in\n  *":%s:"*) ;;\n  *) export PATH="$PATH:%s" ;;\nesac\n' "$RB" "$RB" >"$PPD";
    printf "PATH-Ergänzung in $blau$PPD$reset geschrieben.\n";
  fi;
  # 3) /root/.bashrc (sofort für root-Sessions)
  BRC=/root/.bashrc;
  grep -q "$RB" "$BRC" 2>/dev/null || \
    printf '\n# /root/bin in PATH\ncase ":$PATH:" in\n  *":%s:"*) ;;\n  *) export PATH="$PATH:%s" ;;\nesac\n' "$RB" "$RB" >>"$BRC";
  # 4) sofort in laufender Session aktiv
  case ":$PATH:" in
    *":$RB:"*) ;;
    *) export PATH="$PATH:$RB"; printf "PATH sofort um $blau$RB$reset ergänzt.\n";;
  esac;
} # setzpfad

setzprompt() {
	printf "${dblau}setzprompt$reset()\n";
  gesnr=" $(seq 0 1 50|tr '\n' ' ')";
  for fnr in $gesnr; do
    FB="\[$(printf '\033[48;5;253;38;5;0'$fnr'm')\]";
    FBH="\[$(printf '\033[48;5;255;38;5;0'$fnr'm')\]"
    PSh="${FB}Farbe $fnr: \u@\h(."$(ip route get 1.1.1.1 2>/dev/null|awk '{for(i=1;i<=NF;i++) if($i=="src") print $(i+1)}'|cut -d. -f4)"):${FBH}\w${RESET}>"
    [ $obbash -eq 1 ]&&{
      printf "${PSh@P}";
    }||{
      printf "$(echo $PSh|sed 's/\\u/'$(whoami)'/g;s:\\w:'$(pwd|sed "s:/root:~:")':;s:\\h:'$(hostname|sed "s:\..*::")':g;s:\\\[::g;s:\\\]::g;')";
    }
    printf "$reset\n";
  done;
  nr=;
  while true; do
    case $gesnr in *" "$nr" "*)break;;esac;
    printf "Bitte die gewünschte Nummer eingeben: ";read nr;
    obschreiben=1;
  done;
  echo nr: $nr;
  BBL=/etc/bash.bashrc.local;
  echo "FNr=$nr;" >$BBL;
  echo "FB=\"\\[\$(printf '\\e[48;5;253;38;5;0'\$FNr'm')\\]\"" >>$BBL;
  echo "FBH=\"\\[\$(printf '\\e[48;5;255;38;5;0'\$FNr'm')\\]\"" >>$BBL;
  echo "RESET=\"\\[\$(printf '\\e[00m')\\]\"" >>$BBL;
  echo "PS1=\"\${FB}\\u@\\h(.\"\$(ip route get 1.1.1.1 2>/dev/null|awk '{for(i=1;i<=NF;i++) if(\$i==\"src\") print \$(i+1)}'|cut -d. -f4)\"):\${FBH}\\w\${RESET}>\"" >>$BBL;
  echo "export NCURSES_NO_UTF8_ACS=1" >>$BBL;
} # setzprompt

mountlaufwerke() {
printf "${dblau}mountlaufwerke$reset()\n";
# Laufwerke einhängen
# in allen nicht auskommentierten Zeilen Leerzeichen durch einen Tab ersetzen
# fstb=$(sed -n '/^#/!{s/[[:space:]]\+/\t/g;p}' $ftb); # "^/$Dvz\>" ginge auch
ausf "sed -n '/^#/!{s/[[:space:]]\+/\t/g;p}' $ftb"; # "^/$Dvz\>" ginge auch
fstb=$resu;
# blkvar=$(lsblk -bisnPfo NAME,SIZE,FSTYPE,LABEL,UUID,MOUNTPOINT -x SIZE|grep -v 'raid_member\|FSTYPE="" LABEL=""\|FSTYPE="swap"');
ausf "lsblk -bisnPfo NAME,SIZE,FSTYPE,LABEL,UUID,MOUNTPOINT -x SIZE|grep -v 'raid_member\|FSTYPE=\"\" LABEL=\"\"\|FSTYPE=\"swap\"'";
blkvar=$resu;
# bisherige Labels DATA, DAT1 usw. und bisherige Mounpoints /DATA, /DAT1 usw. ausschließen 
# z.B. "2|1|3|A"
# bishDAT=$(echo "$blkvar"|awk '/=\"DAT/{printf substr($4,11,length($4)-11)"|";}/=\"\/DAT/{printf substr($6,17,length($6)-17)"|";}'|awk '{print substr($0,0,length($0)-1);}'); # "<- dieses Zeichen steht nur hier fuer die vi-Faerbung
# echo bishDAT: $bishDAT;
# bishwin=$(echo "$blkvar"|awk '/=\"win/{printf substr($4,11,length($4)-11)"|";}/=\"\/win/{printf substr($4,17,length($6)-17)"|";}'|awk '{print substr($0,0,length($0)-1);}');
for N in DAT win; do
  if [ $N = DAT ]; then par=6; else par=4; fi;
  ausf "echo \"\$blkvar\"|awk '/=\\\""$N"/{printf substr(\$4,11,length(\$4)-11)\"|\";}/=\\\"\\/"$N"/{printf substr(\$"$par",17,length(\$6)-17)\"|\";}'|awk '{print substr(\$0,0,length(\$0)-1);}'";
  if [ $N = DAT ]; then bishDAT=$resu; else bishwin=$resu; fi;
done;
# echo bishDAT: $bishDAT;
# echo bishwin: $bishwin;
istinfstab=0;
Dnamnr="A"; # 0=DATA, 1=DAT1, 2=DAT2 usw # linux name nr
wnamnr=1;
# Laufwerke mit bestimmten Typen und nicht-leerer UUID absteigend nach Größe
# ausf "lsblk -o NAME,SIZE,FSTYPE,LABEL,UUID,MOUNTPOINT -b -i -x SIZE -s -n -P -f|grep -v ':\|swap\|efi\|fat\|iso\|FSTYPE=\"\"\|FSTYPE=\".*_member\"\|UUID=\"\"\|MOUNTPOINT=\"/\"'|tac";
ausf "lsblk -o NAME,SIZE,FSTYPE,LABEL,UUID,MOUNTPOINT,TYPE -bidnspPx SIZE|tac";
fstabteil=$resu;
nochmal=1;
while test "$nochmal"; do # wenn eine Partition neu erstellt werden musste
  unset nochmal;
  ausf "lsblk -o NAME,SIZE,FSTYPE,LABEL,UUID,MOUNTPOINT,TYPE,PARTTYPE,PTTYPE -bidnspPx SIZE|tac";
  fstabteil=$resu;
# echo fstabteil: "$fstabteil";
  [ "$verb" ]&&printf "fstab-Teil:\n$blau$fstabteil$reset\n";
  [ "$fstabteil" ]||return;
  ges=" ";
while read -r zeile; do
#	echo "Hier: " $zeile;
	dev=$(echo $zeile|cut -d\" -f2);
	fty=$(echo $zeile|cut -d\" -f6);
	lbl=$(echo $zeile|cut -d\" -f8);
	uid=$(echo $zeile|cut -d\" -f10);
	mtp=$(echo $zeile|cut -d\" -f12|sed 's/[[:space:]]//g');
	typ=$(echo $zeile|cut -d\" -f14);
	pty=$(echo $zeile|cut -d\" -f16);
	ptt=$(echo $zeile|cut -d\" -f18);
  case "$fty" in swap|iso9660|fat|*_member) continue;; esac;
  case "$typ" in rom) continue;; esac;
  case "$mtp" in /|/boot/efi) continue;; esac;
  case "$lbl" in EFI) continue;; esac;
  [ "$uid" ]||continue;
  if test -z "$fty"; then
		[ "$pty" = 0xf ]&&continue; # Partitionstabelle
    case "$typ" in disk|part)
      if test "$ptt"/ != gpt/ -a "$ptt"/ != dos/; then
	      echo "Hier nochmal: " $zeile
	      ausf "mke2fs -t ext4 $dev"; 
	      nochmal=1;
	      continue;
      fi;
    esac;
  fi;
  printf "${blau}zeile$reset: $zeile\n";
  if [ "$uid" ]; then
  umbenenn=;
  if [ "$lbl" ]; then
    case $ges in 
      *" "$lbl" "*) 
        fertig=;
        for i in $(seq 1 1 500); do
          case $ges in *" "${lbl}_$i" "*);;*)fertig=1;ges="$ges${lbl}_$i ";;esac;
          [ "$fertig" ]&&break;
        done;
        printf "doppelter Name bei uid: $blau$uid$reset, mtp: $blau$mtp$reset, lbl: $blau$lbl$reset => $rot${lbl}_$i$reset\n";
        lbl=${lbl}_$i;
        umbenenn=1;;
    esac;
  else
			case "$fty" in 
				ext*|btrfs|reiserfs)
					while :;do	
						abbruch=0;
						# wenn der geplante Buchstabe noch nicht vergeben: Abbruch von while planen
						[ -z "$bishDAT" ]&&abbruch=1|| eval "case "$Dnamnr" in "$bishDAT"):;;*)false;;esac;"||abbruch=1;
						[ $abbruch -eq 1 ]&&break;
						[ "$Dnamnr" = "A" ]&&Dnamnr=1||Dnamnr=$(expr $Dnamnr + 1 );
					done;
					lbl="DAT"$Dnamnr;;
				ntfs*|exfat*|vfat)
					while :;do	
						abbruch=0;
						[ -z "$bishwin" -o "$bishwin"ß = "|ß" ]&&abbruch=1|| eval "case "$wnamnr" in "$bishwin"):;;*)false;;esac;"||abbruch=1;
						[ $abbruch -eq 1 ]&&break;
						wnamnr=$(expr $wnamnr + 1 );
					done;
					lbl="win"$wnamnr;;
			esac;
      printf "fehlender Name bei uid: $blau$uid$reset, mtp: $blau$mtp$reset, => lbl: $rot$lbl$reset\n";
      umbenenn=1;
  fi;
  [ "$lbl" ]&&ges="$ges$lbl ";
	if [ "$umbenenn" ]; then
		case "$fty" in ext*|btrfs|reiserfs|ntfs*|exfat*|vfat)
			case $fty in 
				ext*)
					printf "${rot}e2label $dev $lbl$reset\n";
          e2label $dev "$lbl" 2>/dev/null||e2label $(echo $dev|sed 's/-/\//') "$lbl";;
				btrfs)
					printf "${rot}btrfs filesystem label $dev $lbl$reset\n";
          mtp=$(findmnt -n -o TARGET $dev 2>/dev/null);
          if [ "$mtp" ]; then
            btrfs filesystem label "$mtp" "$lbl";
          else
            btrfs filesystem label "$dev" "$lbl";
          fi;;
        reiserfs)
					printf "${rot}reiserfstune -l $lbl $dev$reset\n";
          reiserfstune -l "$lbl" $dev 2>/dev/null || \
            printf "${rot}reiserfstune nicht verfügbar (ReiserFS in Kernel 6.6+ entfernt)$reset\n";;          
				ntfs*)
          printf "${rot} ntfs3 label $dev $lbl$reset\n";
          ntfslabel $dev "$lbl" 2>/dev/null || \
            python3 -c "import struct; ..." 2>/dev/null || \
            printf "${rot}ntfslabel nicht verfügbar – Label manuell setzen$reset\n";;          
				exfat*)
					printf "${rot} exfatlabel $dev $lbl$reset\n";
					exfatlabel $dev "$lbl";;
				vfat)
					printf "${rot} mache vfat Label$reset\n";
					eingehaengt=0;
					mountpoint -q $dev&&{ eingehaengt=1; umount $dev;};
					env MTOOLS_SKIP_CHECK=1 mlabel -i $dev ::x;
					dosfslabel $dev "$lbl";
					test $eingehaengt -eq 1&&mount $dev;;
			esac;
    esac;
	fi;
	# printf "zeile: $blau$zeile$reset\n"
	# echo "mtp: \"$mtp\"";
  case $lbl in 
   DAT*|wrz*|win*)
	   [ "$mtp" ]||mtp="/"$(echo $lbl|sed 's/[[:space:]]//g');;
   *)
   	 [ "$mtp" ]||mtp="/mnt/"$(echo $lbl|sed 's/[[:space:]]//g');;
  esac;
	[ "$mtp" -a ! -d "$mtp" ]&&mkdir -p "$mtp";
	if test -z "$lbl"; then
		ident="UUID="$uid;
	else 
		ident="LABEL="$lbl;
	fi;
	idohnelz=$(printf "$ident"|sed 's/[[:space:]]/\\\\040/g');
	obinfstab "$idohnelz" "$uid" "$dev";
	printf "Mountpoint: $blau$mtp$reset istinfstab: $blau$istinfstab$reset\n";
	if test $istinfstab -eq 0; then
    eintr="\t $mtp\t $fty\t user,acl,exec,nofail,x-systemd.device-timeout=15\t 1\t 2";
    [ "$fty" = vfat ]&&eintr="\t $mtp\t $fty\t user,exec,nofail,x-systemd.device-timeout=15\t 1\t 2";
    # Nachher – ntfs3 bevorzugen, ntfs-3g als Fallback:
    if test "$fty" = ntfs; then
      if grep -q ntfs3 /proc/filesystems 2>/dev/null; then
        eintr="\t $mtp\t ntfs3\t uid=0,gid=0,umask=022,nofail,x-systemd.device-timeout=15\t 0\t 0";
      else
        eintr="\t $mtp\t ntfs-3g\t user,users,gid=users,fmask=133,dmask=022,locale=de_DE.UTF-8,nofail,x-systemd.device-timeout=15\t 1\t 2";
      fi;
    fi;
		eintr=$idohnelz$eintr;
		printf "$eintr\n" >>$ftb;
		printf "\"$blau$eintr$reset\" in $blau$ftb$reset eingetragen.\n";
	fi;
 fi; # [ "$uid" ]
	# byt=$(echo $zeile|cut -d\" -f4);
	#   altbyt=$byt; byt=$(echo $z|cut -d' ' -f2); [ "$byt" -lt "$altbyt" ]&&gr=ja||gr=nein; echo "      byt: "$byt "$gr";
done << EOF
$fstabteil;
EOF
done; # nochmal
  if grep -q "user_xattr" "$ftb" 2>/dev/null; then
    sed -i 's/,user_xattr//g;s/user_xattr,//g;s/user_xattr//g' "$ftb";
    printf "${gruen}user_xattr aus $blau$ftb$reset entfernt.\n";
  fi;
  awk '/^[^#;]/ && !/ swap / && $2 != "none" {print $2}' "$ftb" | while read mtp; do
    [ -d "$mtp" ] || { mkdir -p "$mtp"; printf "Verzeichnis angelegt: $blau$mtp$reset\n"; };
  done;
  mount -a -t nobind,nocifs,nonfs,nonfs4 2>/dev/null||true;
  grep "^//" /etc/fstab 2>/dev/null | grep cifs | while read mline; do
    srv=$(echo "$mline"|sed 's|//\([^/]*\)/.*|\1|');
    mtp=$(echo "$mline"|awk '{print $2}');
    ping -c1 -W2 "$srv" >/dev/null 2>&1 && \
      mount "$mtp" 2>/dev/null && \
      printf "gemountet: $blau$mtp$reset\n" || \
      printf "Server $blau$srv$reset nicht erreichbar – $blau$mtp$reset übersprungen\n";
  done;
  awk '/^[^#;]/ && !/ swap /{printf "%s ",$1;system("mountpoint "$2);}' $ftb;
} # mountlaufwerke


# pruefgruppe() – legt Gruppe $1 an falls noch nicht vorhanden
pruefgruppe() {
    [ "$1" ]&&{ grep -q "^$1:" /etc/group||groupadd $1;}||echo Aufruf pruefgruppe ohne Gruppe!
} # pruefgruppe

# pruefuser() – legt Linux- und Samba-Benutzer $1 an falls noch nicht vorhanden
# $1 = Benutzername, $2 = Kommentarfeld (GECOS)
# Fragt interaktiv nach Passwort wenn Benutzer fehlt
pruefuser() {
	printf "${dblau}pruefuser$reset($1)\n";
		id -u "$1" >/dev/null 2>&1 &&obu=0||obu=1;  # obu=1: Linux-User fehlt
		pdbedit -L|grep "^$1:" &&obs=0||obs=1;       # obs=1: Samba-User fehlt
		passw="";
		if test $obu -eq 1 -o $obs -eq 1; then {
			while test -z "$passw"; do
				printf "Bitte gewünschtes Passwort für Linux-Benutzer $blau$1$reset eingeben: "; read passw;
			done;
		} fi;
		if test $obu -eq 1; then {
			printf "erstelle Linux-Benutzer $blau$1$reset\n";
			useradd -p $(openssl passwd -1 $passw) -c"$2" -g "$gruppe" "$1"; # zuweisen: passwd "$1"; löschen: userdel $1
		} fi;
    groups $1|grep -q praxis||usermod -aG praxis $1  # zur Praxis-Gruppe hinzufügen
    pruefgruppe www
    groups $1|grep -q www||usermod -aG www $1        # zur www-Gruppe hinzufügen
		if test $obs -eq 1; then {
				printf "erstelle Samba-Benutzer $blau$1$reset\n"; # löschen: pdbedit -x -u $1
				printf "$passw\n$passw"|smbpasswd -as $1; # prüfen: smbclient -L //localhost/ -U $1
		} fi;
} # pruefuser

# obinfstab() – prüft ob Gerät bereits in fstab eingetragen ist
# $1 = LABEL=xxx oder LABEL=xxx\040... (mit Leerzeichen kodiert)
# $2 = UUID des Geräts
# $3 = Gerätedatei z.B. /dev/sda1
# Ergebnis: $istinfstab=1 wenn gefunden, =0 wenn nicht
obinfstab() {
	printf "${dblau}obinfstab$reset($blau$1$reset, $blau$2$reset, $blau$3$reset)\n";
	istinfstab=0;
  sdev=${3##*/}; # nur der Gerätename ohne Pfad (z.B. "sda1")
	while read -r zeile; do
		vgl=$(printf "$zeile"|cut -f1|sed 's/ /\\\\040/g')  # Leerzeichen als \040 kodieren
		if test "$vgl" = "$(echo $(echo $1)|sed 's/ //g')"; then istinfstab=1; break; fi;
		if test "$vgl" = "$1"; then istinfstab=1; break; fi;
		if test "$vgl" = "UUID=$2";then istinfstab=1; break; fi;
		if test "$vgl" = "$3";then istinfstab=1; break; fi;
		# auch /dev/disk/by-id/-Pfade prüfen:
		for dbid in $(find /dev/disk/by-id -lname "*$sdev"); do
			if test "$vgl" = "$dbid";then istinfstab=1; break; fi;
		done;
		if test $istinfstab -eq 1; then break; fi;
	done << EOF
$fstb
EOF
} # obinfstab

# obprogda() – prüft ob Programm $1 in Standardpfaden vorhanden ist
# Ergebnis: $prog = gefundener Pfad, Return 0 wenn gefunden, 1 wenn nicht
obprogda() {
 printf "${dblau}obprogda$reset(${blau}$1$reset)\n";
 prog="";
 for verz in /usr/local/bin /usr/bin /usr/local/sbin /usr/sbin /sbin /bin /usr/libexec /run; do
	 prog="$verz/$1";
	 if test -f "$prog"; then return 0; fi;
 done;
 prog=$(which "$1" 2>/dev/null);
 if test -f "$prog"; then return 0; fi;
 return 1;
} # obprogda



# ============================================================
# ersetzeprog() – übersetzt distro-unabhängige Paketnamen in
# distro-spezifische Namen anhand von $OSNR
# $1 = generischer Paketname (z.B. "mariadb", "boost-devel")
# Ergebnis: $sprog = tatsächlich zu installierender Paketname
#           leerer $sprog = Paket auf diesem System nicht verfügbar
# Wird von doinst() aufgerufen
# ============================================================

ersetzeprog() {
  printf "${blau}ersetzeprog($reset$1): -> "
  sprog="";
  eprog=$1;
  while true; do
  case $OSNR in
  1|2|3) # mint, ubuntu, debian
    if [ "$1" = mariadb ]; then eprog="mariadb-server"; break; fi;
    if [ "$1" = hylafax ]; then eprog="hylafax-server"; break; fi;
    if [ "$1" = "hylafax+" ]; then eprog="hylafax+-server"; break; fi;
    if [ "$1" = "hylafax hylafax-client" ]; then eprog="hylafax-server hylafax-client"; break; fi;
    if [ "$1" = "hylafax+ hylafax+-client" ]; then eprog="hylafax+-server hylafax+-client"; break; fi;
    if [ "$1" = "kernel-source" ]; then eprog="linux-source-$(uname -r|cut -d. -f1,2)"; break; fi;
    if [ "$1" = tiff ]; then eprog="libtiff-tools"; break; fi;
    if [ "$1" = "libxslt-tools" ]; then eprog="xsltproc"; break; fi;
    if [ "$1" = imagemagick ]; then eprog="imagemagick imagemagick-doc"; break; fi;
    if [ "$1" = "libreoffice-base" ]; then eprog="libreoffice-common libreoffice-base"; break; fi;
    if [ "$1" = "libcapi20-2" ]; then eprog="libcapi20-dev"; break; fi;
    if [ "$1" = "tesseract-ocr-traineddata-english" ]; then eprog="tesseract-ocr-eng"; break; fi;
    if [ "$1" = "tesseract-ocr-traineddata-german" ]; then eprog="tesseract-ocr-deu"; break; fi;
    if [ "$1" = "tesseract-ocr-traineddata-orientation_and_script_detection" ]; then eprog="tesseract-ocr-osd"; break; fi;
    if [ "$1" = "poppler-tools" ]; then eprog="poppler-utils"; break; fi;
    if [ "$1" = "boost-devel" ]; then eprog="libboost-dev libboost-system-dev libboost-filesystem-dev"; break; fi;
    if [ "$1" = "openssh" ]; then eprog="openssh-server openssh-client"; break; fi;
    # exfatprogs heißt auf älteren Debian/Ubuntu noch exfat-utils
    if [ "$1" = "exfatprogs" ]; then
      dpkg -s exfatprogs >/dev/null 2>&1 || eprog="exfat-utils"; break;
    fi;
    eprog=$(echo "$eprog"|sed 's/-devel/-dev/g');
    ;;
  5|6) # fedora, fedoraalt
    if [ "$1" = mariadb ]; then eprog="mariadb-server"; break; fi;
    if [ "$1" = "kernel-source" ]; then eprog="kernel-devel-$(uname -r)"; break; fi;
    if [ "$1" = "libwbclient0" ]; then eprog="libwbclient"; break; fi;
    if [ "$1" = tiff ]; then eprog="libtiff-tools"; break; fi;
    if [ "$1" = libtiff5 ]; then eprog="libtiff"; break; fi;
    if [ "$1" = "libcapi20-2" ]; then eprog="isdn4k-utils"; break; fi;
    if [ "$1" = "libcapi20-3" ]; then eprog=""; break; fi;
    if [ "$1" = "capiutils" ]; then eprog=""; break; fi;
    if [ "$1" = imagemagick ]; then eprog="ImageMagick ImageMagick-doc"; break; fi;
    if [ "$1" = "libxslt-tools" ]; then eprog="libxslt"; break; fi;
    if [ "$1" = "libreoffice-base" ]; then eprog="libreoffice-filters libreoffice-langpack-de"; break; fi;
    if [ "$1" = "tesseract-ocr" ]; then eprog="tesseract"; break; fi;
    if [ "$1" = "tesseract-ocr-traineddata-english" ]; then eprog=""; break; fi;
    if [ "$1" = "tesseract-ocr-traineddata-german" ]; then eprog="tesseract-langpack-deu tesseract-langpack-deu_frak"; break; fi;
    if [ "$1" = "tesseract-ocr-traineddata-orientation_and_script_detection" ]; then eprog=""; break; fi;
    if [ "$1" = "poppler-tools" ]; then eprog="poppler-utils"; break; fi;
    if [ "$1" = "openssh" ]; then eprog="openssh openssh-server openssh-clients"; break; fi;
    if [ "$1" = "exfatprogs" ]; then eprog="exfatprogs"; break; fi;
    ;;
  4) # openSUSE
    if [ "$1" = "redhat-rpm-config" ]; then eprog=""; break; fi;
    if [ "$1" = "kernel-source" ]; then eprog="kernel-devel"; break; fi;
    if [ "$1" = "libffi-devel" ]; then eprog="libffi$(gcc --version|head -n1|sed "s/.*) \(.\).\(.\).*/\1\2/")-devel"; break; fi;
    # liblept5 heißt auf openSUSE 16.0 libleptonica6
    if [ "$1" = "liblept5" ]; then eprog="libleptonica6"; break; fi;
    # phpPgAdmin nicht mehr in Repos verfügbar
    if [ "$1" = "phpPgAdmin" ]; then eprog=""; break; fi;
    # p7zip-full gibt es auf openSUSE nicht, nur p7zip
    if [ "$1" = "p7zip-full" ]; then eprog=""; break; fi;
    # exfatprogs heißt auf openSUSE 16.0 exfatprogs (korrekt)
    if [ "$1" = "exfatprogs" ]; then eprog="exfatprogs"; break; fi;
    # libgsasl nicht in offiziellen openSUSE 16.0 Repos
    if [ "$1" = "libgsasl" ]; then eprog=""; break; fi;
    if [ "$1" = "libgsasl-devel" ]; then eprog=""; break; fi;      
    ;;
  8) # manjaro
    if [ "$1" = "libwbclient0" ]; then eprog="libwbclient"; break; fi;
    ;;
  esac;
  break;
  done;
  [ -z "$sprog" ]&&sprog="$eprog";
  printf " $sprog\n";
} # ersetzeprog

setzinstprog() {
 printf "${dblau}setzinstprog$reset(), OSNR: $OSNR\n"
 case $OSNR in
  1|2|3) # Debian, Ubuntu, Mint
    S=/etc/apt/sources.list;F='^[^#]*cdrom:';grep -qm1 $F $S && test 0$(sed -n '/^[^#]*ftp.*debian/{=;q}' $S) -gt 0$(sed -n '/'$F'/{=;q}' $S) &&
          ping -qc 1 www.debian.org >/dev/null 2>&1 && sed -i.bak '/'$F'/{H;d};${p;x}' $S;:;
    psuch="dpkg -s ";
    instp="apt-get install";
    instyp="apt-get -y --force-yes --reinstall install ";
    insg="apt-get --allow-unauthenticated -y install ";
    insse="apt search installed ";
    upr="apt-get -f install;apt-get purge ";
    upru="apt-get -f install;apt-get --auto-remove purge ";
    udpr="apt-get -f install;dpkg -r --force-depends ";
    uypr="apt-get -f install;apt-get -y --auto-remove purge ";
    upd="apt update;apt upgrade;";
    compil="install build-essential linux-headers-`uname -r`";
    dev="dev";;
  4) # openSUSE
    psuch="rpm -q ";
    dev="devel";
    udpr="rpm -e --nodeps ";
    instp="zypper -n --gpg-auto-import-keys in ";
    # Korrektur: "-y" ist kein gültiges zypper-Flag; "-f" erzwingt Neuinstallation
    instyp="zypper -n --gpg-auto-import-keys in -f ";
    insg="zypper --no-gpg-checks -n in ";
    insse="zypper se -i ";
    upr="zypper -n rm ";
    upru="zypper -n rm -u ";
    uypr="zypper -n rm -u ";
    # Korrektur: "zypper patch" schlägt bei Tumbleweed/16.0 fehl → dup als Fallback
    upd="zypper patch 2>/dev/null || zypper dup";
    # Korrektur: Repo-URL mit sed für Leerzeichen im Distro-Namen (openSUSE Leap → openSUSE_Leap)
    _osnname=$(cat /etc/*-release 2>/dev/null|grep ^NAME=|cut -d'"' -f2|sed 's/ /_/');
    _osnver=$(cat /etc/*-release 2>/dev/null|grep ^VERSION_ID=|cut -d'"' -f2);
    repos="zypper lr | grep 'g++\\|devel_gcc'>/dev/null 2>&1 ||zypper ar http://download.opensuse.org/repositories/devel:";
    repos="${repos}gcc/${_osnname}_${_osnver}/devel:gcc.repo;";
    # Korrektur: "make" zu compil ergänzt
    compil="make gcc gcc-c++";;
  5) # Fedora
    psuch="rpm -q ";
    dev="devel";
    udpr="rpm -e --nodeps ";
    instp="dnf install ";
    instyp="dnf -y install ";
    insg="dnf --nogpgcheck install ";
    upr="dnf remove ";
    upru="dnf autoremove ";
    uypr="dnf -y remove ";
    upd="dnf update";;
  6) # RHEL/CentOS
    psuch="rpm -q ";
    dev="devel";
    udpr="rpm -e --nodeps ";
    instp="yum install ";
    instyp="yum -y install ";
    insg="yum --nogpgcheck install ";
    upr="yum remove ";
    upru="yum autoremove ";
    uypr="yum -y remove ";
    upd="yum update";;
  7) # Mandriva/Mageia
    psuch="rpm -q ";
    dev="devel";
    udpr="rpm -e --nodeps ";
    instp="urpmi --auto ";
    instyp="urpmi --auto --force ";
    insg="urpmi bumblebee-nonfree-release ";
    upr="urpme ";
    upru="urpme ";
    uypr="urpme --auto --force ";
    upd="urpmi.update -a";;
  8) # Manjaro/Arch
    psuch="pacman -Qi";
    instp="pacman -S ";
    instyp="pacman -S --noconfirm ";
    upr="pacman -R ";
    upru="pacman -R -s ";
    uypr="pacman -R -s --noconfirm ";
    udpr="pacman -R -d -d ";
    upd="pacman -Syu";
    compil="gcc linux-headers-`uname -r`";;
 esac;
} # setzinstprog

# -----------------------------------------------------------------------
# Hinweis: In proginst() folgende Zeilen ergänzen (nach doinst p7zip):
#
#   doinst exfatprogs;   # exFAT-Datenträger labeln (mountlaufwerke)
#   doinst mtools;       # vfat mlabel
#   doinst dosfstools;   # vfat dosfslabel / mkfs.fat
#
# Und die ISDN-Repo-URL in proginst() von hartcodiertem
# "openSUSE_Leap_15.2" auf dynamisch umstellen:
#
#   _isdnver=$(cat /etc/*-release 2>/dev/null|grep ^VERSION_ID=|cut -d'"' -f2)
#   _isdnname=$(cat /etc/*-release 2>/dev/null|grep ^NAME=|cut -d'"' -f2|sed 's/ /_/')
#   zypper lr home_mnhauke_ISDN >/dev/null 2>&1 || {
#     zypper addrepo \
#       "https://download.opensuse.org/repositories/home:mnhauke:ISDN/${_isdnname}_${_isdnver}/home:mnhauke:ISDN.repo"
#     zypper refresh;
#   }
# -----------------------------------------------------------------------


# ============================================================
# doinst() – installiert Paket $1 falls noch nicht vorhanden
# $1 = generischer Paketname (wird durch ersetzeprog() übersetzt)
# $2 = alternative Programmdatei zum Prüfen ob bereits installiert (optional)
# Verwendet $psuch (rpm -q / dpkg -s) und $instp (zypper in / apt-get)
# aus setzinstprog() – muss vorher aufgerufen worden sein
# ============================================================
doinst() {
	printf "${blau}doinst($reset$1)\n"
	ersetzeprog "$1";
	[ "$2" ]&&obprogda "$2"&&return 0;
  #	printf "eprog: $blau$eprog$reset sprog: $blau$sprog$reset\n";
  [ -z "$sprog" ] && { printf "kein Paket für $blau$1$reset auf diesem System\n"; return 0; }
  for prog in $sprog; do
    printf "$psuch $prog: "
    $psuch "$prog" >/dev/null 2>&1&&{ echo gefunden; return 0; }
    printf "installiere $blau$prog$reset\n";
    if [ $OSNR -eq 4 -a $obnmr -eq 1 ]; then
      obnmr=0;
      zypper mr -k --all;
    fi;
    $instp "$prog";
  done;
  printf "Fertig mit ${blau}doinst($reset$1)\n"
} # doinst

datadirsetzen() {
  printf "${dblau}datadirsetzen${reset}()\n";
  if ! mountpoint -q /DATA 2>/dev/null; then
    printf "${rot}/DATA nicht gemountet – MariaDB wird nicht gestartet!${reset}\n";
    systemctl stop mariadb 2>/dev/null||true;
    systemctl stop mysql 2>/dev/null||true;
    return 1;
  fi;
  # Aktuellen datadir ermitteln:
  _aktuell=$(sed -n 's/^[[:space:]]*datadir[[:space:]]*=[[:space:]]*//p' /etc/my.cnf 2>/dev/null|head -1);
  [ -z "$_aktuell" ]&&_aktuell=$(readlink -f /var/lib/mysql 2>/dev/null||echo /var/lib/mysql);
  _ziel=$(readlink -f /var/lib/mysql 2>/dev/null);

  if [ "$_aktuell" = "/DATA/mysql" ] || [ "$_ziel" = "/DATA/mysql" ]; then
    printf "datadir bereits ${blau}/DATA/mysql${reset} – nichts zu tun.\n";
  else
    printf "Verschiebe datadir von ${blau}$_aktuell${reset} nach ${blau}/DATA/mysql${reset} ...\n";
    systemctl stop mariadb 2>/dev/null||systemctl stop mysql 2>/dev/null||true;
    if [ -d /DATA/mysql ] && [ "$(ls -A /DATA/mysql 2>/dev/null)" ]; then
      printf "${blau}/DATA/mysql${reset} bereits vorhanden und nicht leer – überspringe Verschieben.\n";
    elif [ -d "$_aktuell" ] && [ ! -L "$_aktuell" ]; then
      mv "$_aktuell" /DATA/mysql;
      printf "Verschoben: ${blau}$_aktuell${reset} -> ${blau}/DATA/mysql${reset}\n";
    else
      mkdir -p /DATA/mysql;
      printf "Verzeichnis ${blau}/DATA/mysql${reset} angelegt.\n";
    fi;
    chown mysql:mysql /DATA/mysql;
    chcon -R -t mysqld_db_t /DATA/mysql/ 2>/dev/null||true;
    semanage fcontext -a -t mysqld_db_t "/DATA/mysql(/.*)?" 2>/dev/null||true;
    restorecon -Rv /DATA/mysql/ 2>/dev/null||true;
    # my.cnf anpassen:
    if grep -q "^[[:space:]]*datadir" /etc/my.cnf; then
      sed -i 's|^[[:space:]]*datadir.*|datadir=/DATA/mysql|' /etc/my.cnf;
    else
      sed -i '/^\[mysqld\]/a datadir=/DATA/mysql' /etc/my.cnf;
    fi;
    printf "datadir=/DATA/mysql in ${blau}my.cnf${reset} gesetzt.\n";
  fi;

  # Symlink entfernen falls vorhanden, leeres Verzeichnis sicherstellen:
  [ -L /var/lib/mysql ]&&rm /var/lib/mysql;
    # Leeres Verzeichnis anlegen falls fehlend (systemd braucht es):
  [ -d /var/lib/mysql ]||{ mkdir -p /var/lib/mysql; chown mysql:mysql /var/lib/mysql; };

  # systemd-Override: MariaDB nur starten wenn /DATA gemountet:
  _od=/etc/systemd/system/mariadb.service.d/require-data.conf;
  if [ ! -f "$_od" ]; then
    mkdir -p "$(dirname $_od)";
    printf "[Unit]\nRequiresMountsFor=/DATA\nConditionPathIsMountPoint=/DATA\n" >"$_od";
    printf "[Service]\nExecStart=\nExecStart=/usr/sbin/mariadbd --defaults-file=/etc/my.cnf --user=mysql --socket=/run/mysql/mysql.sock\n" >"$_od";
    systemctl daemon-reload;
    printf "systemd-Schutz aktiv: MariaDB startet nur wenn ${blau}/DATA${reset} gemountet.\n";
  else
    printf "systemd-Schutz bereits vorhanden: ${blau}$_od${reset}\n";
  fi;
} # datadirsetzen

pruefmroot() {
	printf "${dblau}pruefmroot$reset()\n";
	while true; do
		[ "$mroot" ]&&break;
		printf "Mariadb: Admin: ";[ $obbash -eq 1 ]&&read -rei root mroot||read mroot;
		obschreiben=1;
	done;
	while true; do
		[ "$mrpwd" ]&&break;
		printf "Mariadb:$1 Passwort für '$mroot': ";read mrpwd;
		printf "Mariadb: erneut$2 Passwort für '$mroot': ";read mrpwd2;
		[ "$mrpwd/" = "$mrpwd2/" ]|| unset mrpwd;
		obschreiben=1;
		# hier könnten noch Einträge wie "plugin-load-add=cracklib_password_check.so" in "/etc/my.cnf.d/cracklib_password_check.cnf" 
		# auskommentiert werden und der Service neu gestartet werden
	done;
	printf "${dblau}Ende pruefmroot$reset()\n";
} # pruefmroot

fragmusr() {
  while true; do
    [ "$musr" ]&&break;
    #			echo $0 $SHELL $(ps -p $$ | awk '$1 != "PID" {print $(NF)}') $(ps -p $$) $(ls -l $(which sh));
    printf "Mariadb Standardbenutzer: ";[ $obbash -eq 1 ]&&read -rei "$gruppe" musr||read musr;
    obschreiben=1;
  done;
} # fragmusr

fragmpwd() {
  while true; do
    [ "$mpwd" ]&&break;
    printf "Mariadb: neues Passwort für '$musr': ";read mpwd;
    printf "Mariadb: erneut das Passwort für '$musr': ";read mpwd2;
    [ "$mpwd/" = "$mpwd2/" ]|| unset mpwd;
    obschreiben=1;
  done;
} # fragmpwd

richtmariadbein() {
	printf "${blau}richtmariadbein$reset()\n"
	# Mariadb
	case $OSNR in
		1|2|3)
			db_systemctl_name="mysql";;
		4|5|6|7)
			db_systemctl_name="mariadb";;
	esac;
	for iru in 1 2; do
		systemctl is-enabled $db_systemctl_name >/dev/null 2>&1 ||systemctl enable $db_systemctl_name;
		systemctl start $db_systemctl_name >/dev/null 2>&1;
		minstalliert=1; # 1 = installiert, alle Kriterien sind erfüllt
		mysqld=".*/\(mysqld\|mariadbd\)";
		mysqlben="mysql";
#		mysqlbef=$(which mariadb 2>/dev/null||which mysql 2>/dev/null||echo mysql); # jetzt in variablen
    wosuch=; for wo in /usr/sbin /usr/bin /usr/libexec; do [ -d $wo ]&&wosuch=$wosuch" "$wo; done;
		! find $wosuch -executable -size +1M -regex "$mysqld" 2>/dev/null|grep -q .&&minstalliert=0;
    [ "$verb" ]&& echo 1 minstalliert: $minstalliert;
    [ $minstalliert -eq 1 ]&& obprogda $mysqlbef || minstalliert=0;
    [ "$verb" ]&& echo 2 minstalliert: $minstalliert;
    [ $minstalliert -eq 1 ]&& grep -q "^$mysqlben" /etc/passwd || minstalliert=0;
    [ "$verb" ]&& echo 3 minstalliert: $minstalliert;
    [ $minstalliert -eq 1 ]&& $mysqlbef -V >/dev/null|| minstalliert=0;
    [ "$verb" ]&& echo 4 minstalliert: $minstalliert;
    [ $minstalliert -eq 1 ]&&break;
    [ "$verb" ]&& echo 5 minstalliert: $minstalliert;
		instmaria;
	done;
	if [ $minstalliert -eq 1 ]; then
		datadir=$(sed 's/#.*$//g' $($mysqlbef --help|sed -n '/Default options/{n;p}') 2>/dev/null|grep datadir|cut -d= -f2|sed 's/^[[:space:]]*//'|tail -n1);
		if [ -z "$datadir" ]; then
			mycnfpfad="$(find /etc /etc/mysql $MYSQL_HOME -name my.cnf -printf '%p\n' -quit 2>/dev/null)";
			[ -z "$mycnfpfad" ]&&mycnfpfad="$(find $HOME -name .my.cnf -printf '%p\\n' -quit)";
			if [ "$mycnfpfad" ]; then
				for aktdir in $(sed 's/#.*$//g' "$mycnfpfad"| grep '!includedir' | sed 's/^[ \t]//g' | cut -d' ' -f2-);do
					mycnfpfad="$mycnfpfad $(find $aktdir -not -type d)";
				done;
			fi;
			for aktzz in $mycnfpfad; do
				datadir=$(sed 's/#.*$//g' "$aktzz"|grep datadir|cut -d= -f2|sed 's/^[[:space:]]*//'|tail -n1);
				[ "$datadir" ]&&break;
			done;
		fi;
    backup /etc/my.cnf;
		cp -an $instvz/my.cnf /etc/;
    # datadir aus der lokalen Datei zurückübertragen
    [ -f /etc/my.cnf_0 ]&&{
      dad=$(sed -n '/^[[:space:]]*datadir[[:space:]]*=/p' /etc/my.cnf_0 2>/dev/null);
      [ "$dad" ]&&sed -i "s}^[[:space:]]*datadir[[:space:]]*=.*}$dad}" /etc/my.cnf;
    }
    chown mysql:mysql /etc/my.cnf;
		[ -z "$datadir" ]&&datadir="/var/lib/mysql";
		[ -e "$datadir" -a ! -d "$datadir" ]&&rm -f "$datadir";
		if ! [ -d "$datadir" ]; then
			printf "datadir $blau$datadir$reset fehlt – MariaDB initialisiert beim ersten Start\n";
			systemctl start $db_systemctl_name;
			sleep 3;
		fi;
		until $mysqlbef -e'\q' 2>/dev/null; do
      sleep 1;
    done;
			pruefmroot " neues" " das neue";
      # MariaDB 10.4+: IDENTIFIED BY in GRANT nicht mehr erlaubt -> CREATE USER + GRANT
      # Ersten Zugang über Unix-Socket-Root ohne Passwort:
      ausf "$mysqlbef -u root -e\"CREATE USER IF NOT EXISTS '$mroot'@'localhost' IDENTIFIED BY '$mrpwd'\"" "${blau}";
      ausf "$mysqlbef -u root -e\"SET PASSWORD FOR '$mroot'@'localhost' = PASSWORD('$mrpwd')\"" "${blau}";
      ausf "$mysqlbef -u root -e\"GRANT ALL ON *.* TO '$mroot'@'localhost' WITH GRANT OPTION\"" "${blau}";
      ausf "$mysqlbef -u root -e\"CREATE USER IF NOT EXISTS '$mroot'@'%' IDENTIFIED BY '$mrpwd'\"" "${blau}";
      ausf "$mysqlbef -u root -e\"SET PASSWORD FOR '$mroot'@'%' = PASSWORD('$mrpwd')\"" "${blau}";
      ausf "$mysqlbef -u root -e\"GRANT ALL ON *.* TO '$mroot'@'%' WITH GRANT OPTION\"" "${blau}";
      ausf "$mysqlbef -u root -e\"SET NAMES 'utf8' COLLATE 'utf8_unicode_ci'\"" "${blau}";
      ausf "$mysqlbef -u root -e\"CREATE USER IF NOT EXISTS 'mysql'@'localhost' IDENTIFIED BY '$mrpwd'\"" "${blau}";
      ausf "$mysqlbef -u root -e\"SET PASSWORD FOR 'mysql'@'localhost' = PASSWORD('$mrpwd')\"" "${blau}";
      ausf "$mysqlbef -u root -e\"GRANT ALL ON *.* TO 'mysql'@'localhost' WITH GRANT OPTION\"" "${blau}";
      ausf "$mysqlbef -u root -e\"CREATE USER IF NOT EXISTS 'mysql'@'%' IDENTIFIED BY '$mrpwd'\"" "${blau}";
      ausf "$mysqlbef -u root -e\"SET PASSWORD FOR 'mysql'@'%' = PASSWORD('$mrpwd')\"" "${blau}";
      ausf "$mysqlbef -u root -e\"GRANT ALL ON *.* TO 'mysql'@'%' WITH GRANT OPTION\"" "${blau}";      
      ausf "$mysqlbef -u root -e\"FLUSH PRIVILEGES\"" "${blau}";
      test "$mpwd"||echo Bitte gleich Passwort für mysql-Benutzer "$musr" eingeben:
    $mysqlbef -u"$musr" -p"$mpwd" -e'\q' 2>/dev/null;
    erg=$?;
    if test "$erg" -ne "0"; then
    # erg: 1= andere Zahl von Eintraegen, 0 = 2 Eintraege
#     test "$mrpwd"||echo Bitte gleich Passwort für mysql-Benutzer "$mroot" eingeben:
     erg=$($mysqlbef --defaults-extra-file=~/.mysqlrpwd -e"select count(0)!=2 from mysql.user where user='$musr' and host in ('%','localhost')"|tail -n1|head -n1);
    fi;
    test "$mpwd"||echo Bitte gleich Passwort für mysql-Benutzer "$musr" eingeben:
    $mysqlbef -u"$musr" -p"$mpwd" -e'\q' 2>/dev/null;
    erg=$?;
    if test "$erg" -ne "0"; then
      fragmusr;
      fragmpwd;
      test "$mpwd"||echo Bitte gleich Passwort für mysql-Benutzer "$musr" eingeben:
      $mysqlbef -u"$musr" -p"$mpwd" -e'\q' 2>/dev/null;
      erg=$?;
      if test "$erg" -ne "0"; then
      # erg: 1= andere Zahl von Eintraegen, 0 = 2 Eintraege
#       test "$mrpwd"||echo Bitte gleich Passwort für mysql-Benutzer "$mroot" eingeben:
       erg=$($mysqlbef --defaults-extra-file=~/.mysqlrpwd -e"SELECT COUNT(0)=2 FROM mysql.user WHERE user='$musr' AND host IN('%','localhost')"|tail -n1|head -n1);
      fi;
      if test "$erg" -ne "0"; then
        echo Benutzer "$musr"  war schon eingerichtet;
      else
          pruefmroot;
#          test "$mrpwd"||echo Bitte gleich Passwort für mysql-Benutzer "$mroot" eingeben:
          ausf "$mysqlbef --defaults-extra-file=~/.mysqlrpwd -hlocalhost -e\"CREATE USER IF NOT EXISTS '$musr'@'localhost' IDENTIFIED BY '$mpwd'\"" "${blau}";
          ausf "$mysqlbef --defaults-extra-file=~/.mysqlrpwd -hlocalhost -e\"SET PASSWORD FOR '$musr'@'localhost' = PASSWORD('$mpwd')\"" "${blau}";
          ausf "$mysqlbef --defaults-extra-file=~/.mysqlrpwd -hlocalhost -e\"GRANT ALL ON *.* TO '$musr'@'localhost' WITH GRANT OPTION\"" "${blau}";
          ausf "$mysqlbef --defaults-extra-file=~/.mysqlrpwd -hlocalhost -e\"CREATE USER IF NOT EXISTS '$musr'@'%' IDENTIFIED BY '$mpwd'\"" "${blau}";
          ausf "$mysqlbef --defaults-extra-file=~/.mysqlrpwd -hlocalhost -e\"SET PASSWORD FOR '$musr'@'%' = PASSWORD('$mpwd')\"" "${blau}";
          ausf "$mysqlbef --defaults-extra-file=~/.mysqlrpwd -hlocalhost -e\"GRANT ALL ON *.* TO '$musr'@'%' WITH GRANT OPTION\"" "${blau}";
          ausf "$mysqlbef --defaults-extra-file=~/.mysqlrpwd -hlocalhost -e\"FLUSH PRIVILEGES\"" "${blau}";
      fi;
      echo datadir: $datadir;
      echo Jetzt konfigurieren;
    fi;
	fi;   # if [ $minstalliert -eq 1 ]; then
  firewall mysql;
  [ "$verb" ]&& echo minstalliert: $minstalliert;
} # richtmariadbein

proginst() {
	printf "${dblau}proginst$reset()\n"
  [ "$psuch" ]||{ echo psuch nicht zugewiesen, OSNR: $OSNR, breche ab; exit; }
	# fehlende Programme installieren
  # postfix, ist wohl schon datei
	doinst htop;
  # nmap seit openSUSE 16.0 im non-free-Repository
  if [ $OSNR -eq 4 ]; then
    zypper modifyrepo --enable openSUSE:repo-non-oss 2>/dev/null||true;
    zypper refresh-services --with-repos 2>/dev/null||true;
  fi
	doinst nmap;
	doinst vsftpd;
	doinst openssh;
	doinst zsh;
	doinst curl;
	doinst cifs-utils;
  # convmv liegt im M17N-Repository, nicht in Standard-Repos
  if [ $OSNR -eq 4 ]; then
  _osnver=$(grep ^VERSION_ID= /etc/os-release 2>/dev/null|cut -d'"' -f2);
  zypper lr M17N >/dev/null 2>&1 || {
    zypper addrepo "https://download.opensuse.org/repositories/M17N/${_osnver}/M17N.repo";
    zypper --gpg-auto-import-keys refresh;
  }
  fi
  doinst convmv; # fuer Turbomed
  doinst chrony; # fuer stutzeDBBack.sh
#  doinst libvmime1; # fuer stutzeDBBack.sh
#  doinst libvmime-devel; # fuer stutzeDBBack.sh
  doinst cmake;
  doinst libgsasl;
  doinst gtk3-devel;
  doinst dash;
  setzgitssh;
  doinst git;
  doinst lsb-release;
  doinst docker;
  doinst gparted;
  doinst liblept5; # fuer ocrmypdf; pillow?
  doinst dash;
  doinst lsb-release;
  doinst p7zip;
  doinst p7zip-full;
  doinst exfatprogs;   # exFAT-Datenträger labeln (mountlaufwerke)
  doinst mtools;       # vfat mlabel
  doinst dosfstools;   # vfat dosfslabel / mkfs.fat
  doinst apache2;
  doinst apache2-mod_php8;
  doinst php8-mysql;
  doinst postgresql;
  doinst postgresql-contrib;
  doinst postgresql-server;
#  doinst phpPgAdmin;
  doinst gnutls-devel; # fuer vmime
  doinst libgsasl-devel; # fuer vmime
  doinst doxygen; # fuer alle moegelichen cmake
  doinst fetchmail;
  doinst virtualbox virtualbox-host-source virtualbox-guest-tools; 
  doinst e2fsprogs-devel; # wg. fehler et/com_err.h missing
#  _isdnurl=$(curl -s "https://download.opensuse.org/repositories/home:mnhauke:ISDN/" | grep -o 'href="[^"]*16[^"]*\.repo"' | head -1 | cut -d'"' -f2);
#  if [ "$_isdnurl" ]; then
#    zypper lr home_mnhauke_ISDN >/dev/null 2>&1 || \
#      zypper ar "https://download.opensuse.org/repositories/home:mnhauke:ISDN/${_isdnurl}" home_mnhauke_ISDN;
#  else
#    printf "${rot}ISDN-Repo für OpenSUSE 16.0 nicht gefunden – CAPI übersprungen$reset\n";
#  fi; 
#5.2/home:mnhauke:ISDN.repo
#  doinst i4l-base;
#  doinst libcapi20-2;
  doinst libcapi20-3;
  doinst capi4linux-devel;
  # curlftpfs liegt im filesystems-Repository
  if [ $OSNR -eq 4 ]; then
    _osnver=$(grep ^VERSION_ID= /etc/os-release 2>/dev/null|cut -d'"' -f2);
    zypper lr filesystems >/dev/null 2>&1 || {
      zypper addrepo "https://download.opensuse.org/repositories/filesystems/${_osnver}/filesystems.repo";
      zypper --gpg-auto-import-keys refresh;
    }
  fi
  doinst curlftpfs; # fuer autofax

# fuer fbfax:
# zypper addrepo https://download.opensuse.org/repositories/openSUSE:Leap:15.2/standard/openSUSE:Leap:15.2.repo
# zypper in /DATA/down/i4l-base-2011.8.29-lp152.8.37.x86_64.rpm
# zypper in /DATA/down/ppp-userpass-2011.8.29-lp152.8.37.x86_64.rpm
# zypper in /DATA/down/libcapi20-2-2011.8.29-lp152.8.37.x86_64.rpm
# zypper in /DATA/down/capi4linux-2011.8.29-lp152.8.37.x86_64.rpm
# zypper in /DATA/down/capi4linux-devel-2011.8.29-lp152.8.37.x86_64.rpm 
  # einmal ging das erst nach zypper up und Neustart des Computers
  # Datei -> Einstellungen -> Zusatzpakete -> Extensionpack auswählen
  # dann VirtualBox aufrufen, Add, die z.B. Wind10.vdi-Datei auswählen; File -> Host Network Manager, Create
  D=/etc/sysconfig/apache2;DN=${D}_neu;[ -f $D ]&&{
       sed 's:APACHE_CONF_INCLUDE_FILES="":APACHE_CONF_INCLUDE_FILES="/etc/apache2/httpd.conf.local":' $D >$DN;
       for dt in php8 version; do
         grep "^APACHE_MODULES=\".* $dt" $DN||sed -i 's:^\(APACHE_MODULES=\"[^"]*\):\1 '$dt':' $DN;
       done;
       cmp -s $D $DN &&{
         rm $DN;
       :;}||{
         mv $D ${D}.bak;
         mv $DN $D;
       }
  }
  # httpd.conf.local anlegen falls fehlend und SELinux-Kontext setzen:
  HCL=/etc/apache2/httpd.conf.local;
  [ -f "$HCL" ]||{ touch "$HCL"; chmod 644 "$HCL"; printf "angelegt: $blau$HCL$reset\n";}
  chcon -t httpd_config_t "$HCL" 2>/dev/null||true;
  semanage fcontext -a -t httpd_config_t "$HCL" 2>/dev/null||true;
  chown wwwrun:www -R /srv/www/htdocs;
  a2enmod php8;
  systemctl enable apache2;
  systemctl restart apache2;
  case $OSNR in
   4) # suse
#    zypper lr|grep home_Alexander_Pozdnyakov >/dev/null||zypper ar https://download.opensuse.org/repositories/home:Alexander_Pozdnyakov/openSUSE_Leap_$(lsb-release -r|cut -f2)/home:Alexander_Pozdnyakov.repo;; # auskommentiert 5.2.22
  esac;
  doinst tesseract-ocr 
  doinst tesseract-ocr-traineddata-german
  # putty auch fuer root erlauben:
	D=/etc/ssh/sshd_config;
  if test -f "$D"; then
    W=PermitRootLogin;
    if ! grep "^$W[[:space:]]*Yes$" $D; then
      if grep "^$W" $D; then
        sed -i "/^$W/c$W Yes" $D;
      elif grep "^#$W" $D; then
        sed -i "/^#$W/a$W Yes" $D;
      fi;
    fi;
  else
    cvz=/etc/ssh/sshd_config.d;
    cnfd=51-permit-root-login.conf;
    mkdir -p "$cvz/";
    if grep -q "^PermitRootLogin" $cvz/$cnfd; then
      # Wenn Zeile existiert (egal ob yes oder no), auf yes ändern
      sed -i 's/^PermitRootLogin.*/PermitRootLogin yes/' $cvz/$cnfd;
    else
      # Wenn Zeile nicht existiert, anfügen
      echo "PermitRootLogin yes" >> $cvz/$cnfd;
    fi
  fi
systemctl reload sshd 2>/dev/null || systemctl reload ssh 2>/dev/null ||true;  
D=/etc/profile.local;S=NCURSES_NO_UTF8_ACS;W=1;[ -f "$D" ]&&grep "$S" "$D"||echo "$S"="$W" >>"$D";
D=/etc/profile.local;S=TERM;W=xterm-utf8;[ -f "$D" ]&&grep "$S" "$D"||echo "# $S"="$W # geht auch" >>"$D";
# dazu noch /.bashrc 
# export LESS_TERMCAP_mb=$'\e[0;31m'     # begin bold => rot
# export LESS_TERMCAP_md=$'\e[1;34m'     # begin blink -> blau
# export LESS_TERMCAP_so=$'\e[01;44;37m' # begin reverse video
# export LESS_TERMCAP_us=$'\e[0;36m'    # begin underline -> tuerkis
# export LESS_TERMCAP_me=$'\e[0m'        # reset bold/blink
# export LESS_TERMCAP_se=$'\e[0m'        # reset reverse video
# export LESS_TERMCAP_ue=$'\e[0m'        # reset underline
# export GROFF_NO_SGR=1                  # for konsole and gnome-terminal
# TERM=xterm-256color
# NCURSES_NO_UTF8_ACS=1;

# dazu noch /etc/bash.bashrc.local:
# GRUEN="\[$(tput setaf 2)\]"
# ROT="\[$(printf '\e[1;31m')\]"
# RESET="\[$(tput sgr0)\]"
# PS1="${GRUEN}\u@\h: \w${RESET}>"

# fehlt: /etc/environment festlegen
# für Windows-Rechner:
# in Windows 10:
# Systemeinstellungen -> App & Features -> Optionale Features 
# in Windows-Server 2019:
# in Einstellungen -> Apps & Features -> Optionale Features wird OpenSSH-Server installiert, in services.msc auf automatisch gestellt und gestartet
# oder: Get-Service -Name sshd | Set-Service -StartupType Automatic und Start-Service sshd
# in c:\programdata\ssh\sshd_config die letzten beiden Zeilen (Match Group Administrators AuthorizedKeysFile __PROGRAMDATA__/ssh/administrators_authorized_keys) auskommentieren (dann wird .ssh durch Verwendung angelegt )
# "ssh-keygen -t ed25519" ohne passphrase
# public keys an authorized_keys anhängen, diese auf %userprofile%\.ssh\ verteilen:
# von der powershell aus:
# "$ak=Get-Content -Path $env:USERPROFILE\.ssh\id_ed25519.pub"
# wenn der Benutzer auf dem Server "schade" ist:
# "$vz="c:\users\sturm\.ssh";$rps="powershell New-Item -Force -ItemType Directory -Path $vz;Add-Content -Force -Path $vz\authorized_keys -Value '$ak'""
# "ssh sturm@szn4 $rPs"
# (dann erfolgt vom eigenen PC aus "ssh sturm@szn4" ohne Passwortabfrage)
# Benutzer wechseln mit "runas /user:sturm cmd"
# Kopieren auf fremden Windows-Rechne:
# scp .ssh\authorized_keys administrator@szn4:c:/users/sturm/.ssh/
# scp .ssh\authorized_keys root@linux0:/root/.ssh/
# scp .ssh\authorized_keys root@linux0:/home/sturm/.ssh/


  D=/var/log/journal;[ -d $D ]||mkdir -p $D;
	case $OSNR in
	1|2|3) # mint, ubuntu, debian
		sshd=ssh;;
	4|5|6|7) # opensuse, fedora, mageia
		sshd=sshd;;
	esac;
	systemctl enable $sshd;
	systemctl restart $sshd;
	doinst git;
  VORVZ=$(pwd);
  zypper rm -y libicu-devel; # muss vor vmime-Build weg (ICU 77 inkompatibel mit vmime 0.9.2)
  [ -s /usr/local/include/vmime/vmime.hpp ]||{
    D=vmime;
    cd $HOME;
    [ -d "$HOME/$D" ]||git clone git+ssh://git@github.com:libelle17/$D.git;
    cd $HOME/$D;
    mkdir -p build;
    cd build;
    cmake -DVMIME_BUILD_SAMPLES=OFF ..;
    cmake --build .;
    cmake --install .;
  }
  doinst libicu-devel; # nach vmime-Build wieder installieren
  # eigene Programme holen:
  for D in autofax anrliste dicom fbfax impgl labimp termine vmparse2 auffaell berein labpath pznbdt; do
    cd $HOME;
    [ -s "$HOME/$D/kons.cpp" -o -d "$HOME/$D/cmake" ]||{ 
      [ -d "$HOME/$D" ]&&{
        find "$HOME/$D" -ls
        printf "Soll das Verzeichnis $HOME/$D zum Neuholung von git gelöscht werden (jyJYnN)? ";read obloe;
        case $obloe in 
         [jyJY]*) rm -rf "$HOME/$D";;
        esac;
      }
      echo hole $D; git clone git+ssh://git@github.com/libelle17/$D.git;
    };
    cd $HOME/$D;
    if [ -d cmake ]; then
     [ -d build ]||mkdir build;
     cd build;
     [ -f Makefile ]||cmake ..;
     make;
     make install;
    else
      [ -f vars ]||sh configure;
      [ -s $D ]||make;
      [ -s /usr/bin/$D ]||make install;
    fi;
    git remote set-url origin  git+ssh://git@github.com/libelle17/$D.git
  done;
  konfig_laden;
  cd $VORVZ;
} # proginst

postfix() {
# in /etc/postfix/master.cf eintragen oder unkommentieren:
#  tlsmgr unix - - n 1000? 1 tlsmgr
# in /etc/postfix/main.cf eintragen oder unkommentieren:
#  inet_protocols = all
#  relayhost = [smtp.gmail.com]:587
#  smtp_sasl_auth_enable = yes
#  smtp_sasl_password_maps = hash:/etc/postfix/sasl_passwd
#  smtp_use_tls = yes
#  smtp_tls_security_level = may
#  smtp_tls_CAfile = /etc/ssl/ca-bundle.pem
#  smtp_tls_CApath = /etc/postfix/ssl/cacerts
#  smtp_tls_session_cache_database = btree:/var/lib/postfix/smtp_tls_session_cache
#  relay_domains = $mydestination hash:/etc/postfix/relay # ohne Komma
#  # always_bcc = mailarchive@localhost
# in sasl_passwd ergänzen:
#  [smtp.gmail.com]:587 meine.mail@gmail.com:meinpasswort
# systemctl restart postfix
# mail schicken mit: echo "Inhalt"|mail -s "Titel" an.wen@provider.com
 echo postfix muss noch geschrieben werden;
} # postfix

bildschirm() {
  printf "${dblau}bildschirm$reset()\n"
  delay=250;  # Millisekunden bis Wiederholung beginnt
  rate=27;    # Wiederholungen pro Sekunde

  # 1) KDE Plasma (5+6): kcminputrc für alle Benutzer direkt schreiben
  for v in /root $(find /home -mindepth 1 -maxdepth 1 -type d); do
    d="$v/.config/kcminputrc"
    mkdir -p "$v/.config"
    # [Keyboard]-Abschnitt anlegen falls fehlend
    grep -q '^\[Keyboard\]' "$d" 2>/dev/null || printf '\n[Keyboard]\n' >>"$d"
    # RepeatDelay setzen oder einfügen
    if grep -q '^RepeatDelay=' "$d" 2>/dev/null; then
      sed -i "s/^RepeatDelay=.*/RepeatDelay=$delay/" "$d"
    else
      sed -i '/^\[Keyboard\]/a RepeatDelay='"$delay" "$d"
    fi
    # RepeatRate setzen oder einfügen
    if grep -q '^RepeatRate=' "$d" 2>/dev/null; then
      sed -i "s/^RepeatRate=.*/RepeatRate=$rate/" "$d"
    else
      sed -i '/^\[Keyboard\]/a RepeatRate='"$rate" "$d"
    fi
    printf "Keyboard-Repeat in $blau$d$reset gesetzt.\n"
  done

  # 2) kwriteconfig6/kwriteconfig5 als laufender Benutzer (falls X/Wayland aktiv)
  aktusr=$(logname 2>/dev/null||loginctl user-status 2>/dev/null|sed -n '1s/\(.*\) .*/\1/p'||who|head -n1|awk '{print $1}')
  for kwrite in kwriteconfig6 kwriteconfig5; do
    if which $kwrite >/dev/null 2>&1; then
      su -l "$aktusr" -c "$kwrite --file kcminputrc --group Keyboard --key RepeatDelay $delay" 2>/dev/null&&\
      su -l "$aktusr" -c "$kwrite --file kcminputrc --group Keyboard --key RepeatRate  $rate"  2>/dev/null&&\
      printf "${blau}$kwrite$reset: RepeatDelay=$delay, RepeatRate=$rate gesetzt.\n"
      break
    fi
  done

  # 3) X11: xset (nur wenn DISPLAY gesetzt, d.h. X läuft)
  if [ "$DISPLAY" ]; then
    xset r rate $delay $rate 2>/dev/null&&printf "${blau}xset r rate$reset $delay $rate gesetzt.\n"
  fi

  # 4) GNOME/Cinnamon (gsettings als eingeloggter Benutzer)
  for SITZ in gnome.desktop cinnamon.settings-daemon; do
    su -l "$aktusr" -c "gsettings set org.$SITZ.peripherals.keyboard repeat-interval $((1000/rate)) 2>/dev/null" 2>/dev/null
    su -l "$aktusr" -c "gsettings set org.$SITZ.peripherals.keyboard delay $delay 2>/dev/null" 2>/dev/null
  done

  # 5) TTY/Konsole: kbdrate (gilt für Textkonsole, unabhängig von X/Wayland)
  if which kbdrate >/dev/null 2>&1; then
    kbdrate -d $delay -r $rate 2>/dev/null&&printf "${blau}kbdrate$reset -d $delay -r $rate gesetzt.\n"
  fi
  # dauerhaft in /etc/vconsole.conf
  vconsole=/etc/vconsole.conf
  if [ -f "$vconsole" ]; then
    grep -q '^RATE=' "$vconsole" && sed -i "s/^RATE=.*/RATE=$rate/" "$vconsole" || echo "RATE=$rate" >>"$vconsole"
  fi

} # bildschirm

sambaconf() {
	printf "${dblau}sambaconf$reset()\n"
  mkdir -p /obslaeuft
  mkdir -p /opt/turbomed
  mkdir -p /srv/www/htdocs
  zustarten=0;
	etcsamba="/etc/samba";[ -d "$etcsamba" ]||mkdir -p $etcsamba;
	smbconf="smb.conf";
	zusmbconf="$etcsamba/$smbconf";
  muster=$(find /usr/share/samba /etc/samba -name "smb.conf*" ! -name "smb.conf" 2>/dev/null | head -1);
  [ -z "$muster" ] && muster="/usr/share/samba/$smbconf";
	smbvars="$instvz/awksmb.inc";
	workgr=$(sed -n '/WORKGROUP/{s/[^"]*"[^"]*"[^"]*"\([^"]*\)".*/\1/p}' "$smbvars");
	[ "$arbgr" ]||{ printf "Arbeitsgruppe des Sambaservers: ";[ $obbash -eq 1 ]&&read -rei "$workgr" arbgr||read arbgr;};
	[ "$arbgr/" = "$workgr/" ]||sed -i '/WORKGROUP/{s/\([^"]*"[^"]*"[^"]*"\)[^"]*\(.*\)/\1'$arbgr'\2/}' $smbvars;
	[ ! -f "$zusmbconf" -a -f "$muster" ]&&{ echo cp -ai "$muster" "$zusmbconf";cp -ai "$muster" "$zusmbconf";};
	S2="$instvz/awksmbap.inc"; # Samba-Abschnitte, wird dann ein Include für awksmb.sh (s.u)
    # Pfade für hardcodierte Shares anlegen und SELinux-Kontext setzen
  for pfad in /opt/turbomed /srv/www/htdocs /obslaeuft; do
    if [ ! -d "$pfad" ]; then
      mkdir -p "$pfad"
      printf "Verzeichnis $blau$pfad$reset angelegt.\n"
    fi
    semanage fcontext -a -t samba_share_t "${pfad}(/.*)?" 2>/dev/null||true
    restorecon -Rv "$pfad" 2>/dev/null||true
  done
  awk -v z=0 '
    function drucke(s1,s2,avail) {
      printf " A[%i]=\"[%s]\"; P[%i]=\"%s\"; avail[%i]=%i;\n",z,s1,z,s2,z,avail;
      z=z+1;
    }
    BEGIN {
      printf "# diese Datei wird durch los.sh vor Gebrauch ueberschrieben.\n";
      printf "BEGIN {\n";
      drucke("turbomed","/opt/turbomed",1);
      drucke("php","/srv/www/htdocs",1);
      drucke("obslaeuft","/obslaeuft",1);
    }
  $3~"^ext|^ntfs|^btrfs$|^reiserfs$|^vfat$|^exfat|^cifs$" &&$2!="/" \
  &&$2!~/^\/var(\/|$)|^\/root(\/|$)|^\/boot(\/|$)|^\/usr(\/|$)|^\/proc(\/|$)|^\/sys(\/|$)/ \
  &&/^[^#]/ {
       n=$2;
       if (n~"efi") {
         sub(".*/","",n);
       } else {
         gsub("/mnt/","",n);
         gsub("/","",n);
         if (n=="DATA") n="daten";
       }
       if (f[n]==0){
         drucke(n,$2,0);
         f[n]=1;
       }
     }
     END{
# Folgendes entwickelt in chr.awk:
     cmd="find /etc/auto.master.d -type f";
     while ((cmd|getline d1)>0) {
       while ((getline d2 < d1)>0) {
         if (d2 !~ /^#.*/){
           if (split(d2,arr," ")>1) {
             vors=arr[1];
             gsub(".*/","",vors);
             gsub("^amnt","",vors);
             while ((getline d3 < arr[2])>0) {
               if (d3 !~ /^#.*/) {
                 gsub("\\s.*","",d3);
                 drucke(vors d3,arr[1]"/"d3,0);
               }
             }
           }
         }
       }
       close(d1);
     }
     close(cmd);
     printf "};\n";
    }
   ' $ftb >$S2;
	AWKPATH="$instvz" awk -f $instvz/awksmb.sh "$zusmbconf" >"$instvz/$smbconf";
	firewall samba;

	if ! diff -q "$instvz/$smbconf" "$zusmbconf" ||[ $zustarten = 1 ]; then  
		backup "$etcsamba/smb" "$zusmbconf"
		cp -a "$instvz/$smbconf" "$zusmbconf";
    [ -f /etc/samba/smbusers ] || touch /etc/samba/smbusers;
		for serv in smbd smb nmbd nmb; do
			systemctl list-units --full -all 2>/dev/null|grep "\<$serv.service"&& systemctl restart $serv 2>/dev/null;
		done;
	fi;
  # SELinux-Kontexte für Samba-Logverzeichnis sicherstellen
  # (update-samba-security-profile kann /var/log falsch labeln)
  chcon -R -t samba_log_t /var/log/samba/ 2>/dev/null||true
  chcon -t auditd_log_t /var/log/audit/ 2>/dev/null||true
  chcon -t auditd_log_t /var/log/audit/audit.log 2>/dev/null||true
} # sambaconf

firewall() {
	printf "${dblau}firewall$reset() $1\n";
	while [ $# -gt 0 ]; do
		para="$1";
	  p1="";p2="";p3="";p4="";p5="";p6="";p7="";	
		case $para in
			samba) p1=Samba; p2=samba_export_all_ro; p3=samba_export_all_rw; p4=samba; p5="samba-server"; p6="samba-client"; p7=samba;;
			http) p1="80/tcp"; p2=httpd_can_network_connect; p3=httpd_can_network_connect_db;p4=http;p5=http;;
			https) p1="443/tcp"; p2=httpd_can_connect_ftp; p3=httpd_can_sendmail;p4=https;p5=https;;
			dhcp) p1="67,68/udp"; p2=dhcpc_exec_iptables; p3=dhcpd_use_ldap;p4=dhcp;p5=dhcp;;
			dhcpv6) p1="-"; p2="-"; p3="-";p4=dhcpv6;p5=dhcpv6;;
			dhcpv6c) p1="-"; p2="-"; p3="-";p4=dhcpv6-client;p5=dhcpv6-client;;
			postgresql) p1=5432;p2=postgresql_selinux_unconfined_dbadm;p3=selinuxuser_postgresql_connect_enabled;p4=postgresql;p5=postgresql;;
			ssh) p1=22/tcp;p2=ssh_use_tcpd;p3=ssh_keysign;p4=ssh;p5=sshd;;
			smtp) p1=25/tcp;p2="-";p3="-";p4=smtp;p5=smtp;;
			imap) p1=143/tcp;p2="-";p3="-";p4=imap;p5=imap;;
			imaps) p1=993/tcp;p2="-";p3="-";p4=imaps;;
			pop3) p1=110/tcp;p2="-";p3="-";p4=pop3;p5=pop3;;
			pop3s) p1=995/tcp;p2="-";p3="-";p4=pop3s;;
			vsftp) p1="20,21,990,40000:50000/tcp";p2="-";p3="-";p4="20/tcp,21/tcp,10090-10100/tcp";p5=vsftp;;
			mysql) p1=3306;p2=mysql_connect_any;p3=allow_user_mysql_connect;p4=mysql;p5=mysql;;
			rsync) p1=rsync;p2="-";p3="-";p4=rsyncd;p5="rsync-server";;
			turbomed) p1="6001/tcp";p2="-";p3="-";p4="6001/tcp";p5="6001/tcp";;
			firebird) p1="3050/tcp";p2="-";p3="-";p4="3050/tcp";p5="3050/tcp";;# soll nach speedguide.net Vulnerabilität haben
			# vpn: 1701
			*) printf "firewall: Unbekannter Parameter $blau$para$reset\n";;
		esac
		tufirewall $p1 $p2 $p3 $p4 $p5 $p6 $p7;
		shift;
	done;
} # firewall

# $1 = ufw allow .., $2 $3 = setsebol -P ..=1, $4 = firewall-cmd --permanent --add-service=.., $5 $6 $7 = /etc/sysconfig/SuSEfirewall2
tufirewall() {
	printf "${dblau}tufirewall$reset($1 $2 $3 $4 $5 $6 $7 $8 $9 ${10})\n";
	zustarten=0;
	# 1) ufw
	if [ "$1" != "-" ]; then
		if which ufw >/dev/null 2>&1; then
			if [ -z "$ufwret" ]; then
				ausf "systemctl list-units --full -all 2>/dev/null|grep ufw.service";
				ufwstatus="$resu";
				echo ufwstatus: $ufwstatus;
				ufwret="$ret";
				echo ufwret: $ufwret;
			else 
				[ "$verb" ]&& echo ufwret vorhanden: $ufwret;
			fi;
			if [ $ufwret -eq 0 ]; then
				if ! ufw status|grep "^$1[[:space:]]*ALLOW" >/dev/null; then
					ausf "ufw show added|grep \"allow $1\$\" >/dev/null 2>&1 ||{ printf \"${blau}ufw allow $1$reset\n\"; ufw allow \"$1\";}";
					if $(echo $ufwstatus|grep -q " active "); then
						systemctl restart ufw;
						zustarten=1;
					fi;
				else
					printf "$1 in ufw schon erlaubt\n";
				fi;
			fi;
		else
			[ "$verb" ]&& echo kein ufw;
		fi;
	else
		[ "$verb" ]&& echo kein ungleich -;
	fi;
	# 2) sebool
	if which setsebool >/dev/null 2>&1 && getsebool >/dev/null 2>&1; then
		for ro in $2 $3; do
			if [ "$ro" != "-" ]; then
				rostatus=$(getsebool -a|grep $ro|sed 's/^[^>]*>[[:space:]]*\([^[:space:]]*\).*/\1/');
				[ -z "$rostatus" -o "$rostatus" = "off" ]&&{ setsebool -P $ro=1; zustarten=1;}
			fi;
		done;
	fi;
	# fehlt evtl: noch: semanage fcontext –at samba_share_t "/finance(/.*)?"
	# und: restorecon /finance

	# 3) firewalld
	if [ "$4" != "-" ]; then
		if which firewall-cmd >/dev/null 2>&1; then
			ausf "systemctl 2>/dev/null|grep firewalld.service";
			fwstatus="$resu";
			[ "$verb" ]&& echo firewalld.service gefunden.
			[ "$verb" ]&& echo Parameter 4: "$4", ret: "$ret";
		#		echo $fwstatus;
			if [ $ret -eq 0 ]; then
				ausf "firewall-cmd --list-services 2>/dev/null";
				services="$resu";
				if [ $ret = 0 ]; then
						case "$4" in [0-9]*/*) was=port;; *) was=service;; esac;
						if [ $was = service ]; then
							ausf "echo \"$services\"|grep -qE \"(^|\s)$4(\s|$)\"";
							if [ ! $ret = 0 ]; then
								ausf "firewall-cmd --get-services|grep -E \"(^|\s)$4(\s|$)\"";
								if [ $ret = 0 ]; then
#									printf "${blau}firewall-cmd --permanent --add-$was=$4$reset\n";
									ausf "firewall-cmd --permanent --add-$was=$4" "${blau}";
									reload=1;
								fi;
							fi;
						else
							ausf "firewall-cmd --list-ports 2>/dev/null";
							ports="$resu";
							for p in $(echo $4|tr ',' ' '); do
								ausf "echo \"$ports\"|grep -qE \"(^|\s)$p(\s|$)\"";
								if [ ! $ret = 0 ]; then
									ausf "firewall-cmd --permanent --add-$was=$p" "${blau}";
									reload=1;
								fi;
							done;
						fi;
						zustarten=1;
						[ "$reload" ]&&{ ausf "firewall-cmd --reload"; unset reload; };
				fi;
			fi;
		fi;
	fi;
	# 4) SuSEFirewall2
	ausf "systemctl list-units --full -all|grep SuSEfirewall2.service";
	susestatus="$resu";
	[ "$verb" ]&& echo susestatus: $susestatus, ret: $ret;
	if [ $ret -eq 0 ]; then
	 # das folgende abgewandelt aus kons.cpp
   susefw="/etc/sysconfig/SuSEfirewall2";
	 if [ -f "$susefw" ]; then
		 for endg in EXT INT DMZ; do
			 for prart in "$5" "$6" "$7"; do
				 if [ "$prart" ]; then
				   prartu=$(echo "$prart"|sed 's/\//\\\//g');
					 # echo grep "^FW_CONFIGURATIONS_$endg=\".*$prart" $susefw;
					 nichtfrei=$(grep "^FW_CONFIGURATIONS_$endg=\".*$prart[ "\""]" $susefw);
					 # echo $nichtfrei $endg $prart $prartu;
					 if [ -z "$nichtfrei" ]; then
						 # echo bearbeite $nichtfrei $endg $prart $prartu;
						 sed -i.bak$i "s/\(^FW_CONFIGURATIONS_$endg=\".*\)\(\".*$\)/\1 $prartu\2/g" $susefw;
					 fi;
				 fi;
			 done;
		 done;
		 if $(echo $susestatus|grep -q " active "); then
			systemctl restart SuSEfirewall2;
			zustarten=1;
		 fi;
	 fi
	fi
} # tufirewall

fritzbox() {
  printf "${dblau}fritzbox${reset}()\n";

  # Fritz!Box erreichbar prüfen:
  ipv4=; ipv6=; ipv=;
  ping -c1 fritz.box >/dev/null 2>&1;
  if [ $? -ne 0 ]; then
    printf "%bfritz.box nicht erreichbar%b\n" "$rot" "$reset";
    return 0;
  fi;

  # IP-Adressen per getent ermitteln – sauber ohne ping-Ausgabe parsen:
  ipv4=$(getent hosts fritz.box | awk '{print $1}' | grep -v ':' | head -1);
  ipv6=$(getent hosts fritz.box | awk '{print $1}' | grep ':'   | head -1);
  # IPv4 bevorzugen (CIFS mit IPv6 oft unzuverlässig):
  [ "$ipv4" ] && ipv=$ipv4 || ipv=$ipv6;
  printf "ipv: %b%s%b\n" "$blau" "$ipv" "$reset";

  # Fritz!Box-Namen per TR-064 ermitteln:
  desc=$(curl --connect-timeout 5 "http://$ipv:49000/tr64desc.xml" 2>/dev/null);
  if [ -z "$desc" ]; then
    printf "%bTR-064 nicht erreichbar%b – verwende 'fritz.box' als Namen\n" \
      "$rot" "$reset";
    fbname="fritz.box";
  else
    fbname=$(echo "$desc"|sed -n '/friendlyName/{s/^[^>]*>\([^<]*\).*/\1/;p;q}');
  fi;
  printf "fbname: %b%s%b\n" "$blau" "$fbname" "$reset";
  # Leerzeichen im Namen für Mountpoint ersetzen:
  fbnameklein=$(echo "$fbname"|tr '[:upper:]' '[:lower:]'|tr ' ' '_');
  mkdir -p "/mnt/$fbnameklein";

  # Credentials prüfen / abfragen:
  credfile="$HOME/.fbcredentials";
  if [ ! -f "$credfile" ]; then
    printf "Bitte Fritzbox-Benutzer eingeben: "; read fbuser;
    printf "Bitte Passwort fuer %b%s%b eingeben: " "$blau" "$fbuser" "$reset";
    stty -echo; read fbpwd; stty echo; printf "\n";
    printf "username=%s\npassword=%s\n" "$fbuser" "$fbpwd" >"$credfile";
    chmod 600 "$credfile";
    printf "Credentials gespeichert in %b%s%b\n" "$blau" "$credfile" "$reset";
  fi;

  # Prüfen ob Eintrag schon in fstab:
  if grep -q "//$ipv4\|//$ipv6\|$fbnameklein" "$ftb" 2>/dev/null; then
    printf "Fritz!Box bereits in %b%s%b eingetragen.\n" "$blau" "$ftb" "$reset";
    # Trotzdem versuchen zu mounten falls noch nicht gemountet:
    mountpoint -q "/mnt/$fbnameklein" || mount "/mnt/$fbnameklein" 2>/dev/null||true;
    return 0;
  fi;

  # Unmounten falls noch gemountet:
  umount "/mnt/$fbnameklein" 2>/dev/null||true;

  # SMBv3 → SMBv2.1 → SMBv2.0 → SMBv1 versuchen:
  _gemountet=;
  for _vers in 3.0 2.1 2.0 1.0; do
    mount "//$ipv/$fbname" "/mnt/$fbnameklein" \
      -t cifs \
      -o "nofail,vers=$_vers,credentials=$credfile" \
      >/dev/null 2>&1 && {
      _gemountet=1;
      printf "Mount erfolgreich mit %bSMB %s%b\n" "$blau" "$_vers" "$reset";
      umount "/mnt/$fbnameklein" 2>/dev/null||true;
      # fstab-Eintrag schreiben:
      [ "$_vers" = "1.0" ] && { _dump=0; _pass=2; } || { _dump=0; _pass=0; };
      printf "//$ipv/$fbname\t/mnt/$fbnameklein\tcifs\tnofail,vers=%s,credentials=%s\t%s\t%s\n" \
        "$_vers" "$credfile" "$_dump" "$_pass" >>"$ftb";
      printf "fstab-Eintrag geschrieben: %b//%s/%s%b\n" \
        "$blau" "$ipv" "$fbname" "$reset";
      break;
    };
  done;

  [ "$_gemountet" ] || \
    printf "%bMount fehlgeschlagen%b – Credentials oder SMB-Version pruefen\n" \
      "$rot" "$reset";

  # Zusammenfassung:
  printf "Fritz!Box: Name=%b%s%b" "$blau" "$fbname" "$reset";
  [ "$ipv4" ] && printf ", IPv4=%b%s%b" "$blau" "$ipv4" "$reset";
  [ "$ipv6" ] && printf ", IPv6=%b%s%b" "$blau" "$ipv6" "$reset";
  printf "\n";
} # fritzbox


machidpub() {
  # ed25519 bevorzugen – moderner und schneller als rsa:
  for _k in \
    "$HOME/.ssh/id_ed25519_git" \
    "$HOME/.ssh/id_ed25519" \
    "$HOME/.ssh/id_rsa" \
    ; do
    if [ -f "${_k}.pub" ]; then
      idpub="${_k}.pub";
      printf "SSH-Schlüssel gefunden: ${blau}$idpub${reset}\n";
      return 0;
    fi;
  done;
  # Keiner vorhanden – neu generieren:
  printf "Kein SSH-Schlüssel gefunden – generiere ${blau}id_ed25519_git${reset} ...\n";
  mkdir -p "$HOME/.ssh";
  chmod 700 "$HOME/.ssh";
  ssh-keygen -t ed25519 \
    -f "$HOME/.ssh/id_ed25519_git" \
    -C "$(whoami)@$(hostname)@github.com" \
    -N "";
  idpub="$HOME/.ssh/id_ed25519_git.pub";
  printf "Bitte diesen Schlüssel auf ${blau}github.com -> Settings -> SSH keys${reset} eintragen:\n";
  cat "$idpub";
  printf "\nDanach Enter drücken ...\n"; read _dummy;
} # machidpub

setzgitssh() {
  printf "${dblau}setzgitssh$reset()\n";
  GITKEY="$HOME/.ssh/id_ed25519_git";
  # 1) Schlüssel erstellen falls fehlend
  if [ ! -f "$GITKEY" ]; then
    printf "SSH-Schlüssel für GitHub fehlt, erstelle $blau$GITKEY$reset ...\n";
    ssh-keygen -t ed25519 -f "$GITKEY" -C "gerald.schade@gmx.de@github.com" -N "";
    printf "\nBitte diesen Schlüssel auf ${blau}github.com -> Settings -> SSH keys -> New SSH key${reset} eintragen:\n";
    cat "${GITKEY}.pub";
    printf "\nDanach Enter drücken ...\n"; read dummy;
  fi;
  # 2) ssh-agent starten falls nicht aktiv
  if [ -z "$SSH_AUTH_SOCK" ]; then
    eval "$(ssh-agent -s)" >/dev/null;
  fi;
  # 3) Schlüssel laden falls noch nicht geladen
  ssh-add -l 2>/dev/null | grep -q "$GITKEY" || ssh-add "$GITKEY" 2>/dev/null;
  # 4) Dauerhaft in /etc/profile.d/ eintragen
  PPD=/etc/profile.d/ssh-agent-git.sh;
  if [ ! -f "$PPD" ] || ! grep -q "id_ed25519_git" "$PPD" 2>/dev/null; then
    printf '# SSH-Agent fuer GitHub automatisch starten (gesetzt von los.sh)\n' >"$PPD";
    printf 'if [ "$(id -u)" = "0" ] && [ -z "$SSH_AUTH_SOCK" ]; then\n' >>"$PPD";
    printf '  eval "$(ssh-agent -s)" >/dev/null\n' >>"$PPD";
    printf '  ssh-add /root/.ssh/id_ed25519_git 2>/dev/null\n' >>"$PPD";
    printf 'fi\n' >>"$PPD";
    printf "SSH-Agent-Autostart in $blau$PPD$reset eingetragen.\n";
  fi;
  # 5) Verbindung testen
  printf "Teste GitHub-Verbindung ...\n";
  ssh -T git@github.com 2>&1 | grep -q "successfully authenticated" && \
    printf "${gruen}GitHub-Verbindung OK$reset\n" || \
    printf "${rot}GitHub-Verbindung fehlgeschlagen – Schlüssel auf github.com prüfen$reset\n";
} # setzgitssh

musterserver() {
  printf "${dblau}musterserver $1${reset}()\n";
  # $1=neu: rsync auch ausführen wenn Zielverzeichnis bereits existiert
  [ "$1" = "neu" ] && \
    printf "Modus: ${rot}kopiert erneut, falls schon vorhanden${reset}\n";

  # Quellserver abfragen falls nicht gesetzt:
  [ "$srv0" ]||{ printf "Bitte ggf. Server angeben, von dem kopiert werden soll (leer=lokal): "; read srv0; };

  if [ "$srv0" ]; then
    # SSH-Schlüssel austauschen:
    machidpub;
    KS=$HOME/.ssh/authorized_keys;
    test -f "$KS" || touch "$KS";

    # Eigenen Schlüssel auf Quellserver eintragen:
    # Korrektur: xargs -I{} statt veraltetem xargs -i
    <"$idpub" xargs -I{} ssh $(whoami)@$srv0 \
      'umask 077;F='"$KS"';grep -qF "{}" "$F"||echo "{}" >>"$F"' 2>/dev/null||true;

    # Alle Schlüssel vom Quellserver holen (nicht nur id_rsa.pub):
    ssh $(whoami)@$srv0 "for f in ~/.ssh/*.pub; do cat \"\$f\"; done" 2>/dev/null | \
      while IFS= read -r key; do
        [ "$key" ] && { grep -qF "$key" "$KS" || echo "$key" >>"$KS"; };
      done;

    # Credentials vom Quellserver holen – nur wenn noch nicht vorhanden:
    # (konfig_laden stellt sie aus sensibel.tar.gpg wieder her falls vorhanden)
    if [ -f "$instvz/konfig/verschluesselt/sensibel.tar.gpg" ]; then
      printf "konfig-Archiv vorhanden – überspringe scp für Credentials.\n";
    else
      for dt in .fbcredentials .loscred .mysqlpwd .mysqlrpwd .tr64cred; do
        if [ -f "/root/$dt" ]; then
          printf "${blau}/root/$dt${reset} bereits vorhanden – übersprungen\n";
        else
          scp -p "$srv0:/root/$dt" /root/ 2>/dev/null && \
            printf "kopiert: ${blau}/root/$dt${reset}\n" || \
            printf "${rot}scp /root/$dt fehlgeschlagen${reset}\n";
        fi;
      done;
    fi;

  else
    # Kein Quellserver – lokal nach root-Verzeichnis suchen:
    printf "Soll von einem Verzeichnis mit /root kopiert werden (jyJYnN)? "; read obpl;
    case $obpl in
      [jyJY]*)
        altwrz=;
        [ -s "$wzp" ] && {
          ls -l "$wzp";
          printf "Datei ${blau}$wzp${reset} gefunden. Als Quelle verwenden (jyJYnN)? "; read altwrz;
        };
        case $altwrz in
          [jyJY]*) ;;
          *)
            mount --all 2>/dev/null;
            # Korrektur: -xdev um Pseudo-Filesysteme zu überspringen → schneller
            bef="find / -maxdepth 5 -xdev -mount -type d -name 'root' -printf '%p\\n'";
            printf "Suche Verzeichnisse mit ${blau}$(echo "$bef"|sed 's/%/%%/g;s/\\/\\\\/g')${reset} (kann länger dauern)...\n";
            eval "$bef" >"$wzp";
            ;;
        esac;
        if [ -s "$wzp" ]; then
          awk '{print NR" "$0}' "$wzp" >menuwrz;
          # dialog verwenden falls vorhanden, sonst Texteingabe:
          if which dialog >/dev/null 2>&1; then
            FILE=$(dialog --title "gefundene Verzeichnisse mit /root" \
              --menu "Wähle eine" 0 0 0 --file menuwrz 3>&2 2>&1 1>&3);
          else
            printf "${rot}dialog nicht installiert${reset} – bitte Nummer wählen:\n";
            cat menuwrz | head -30;
            printf "Nummer eingeben: "; read FILE;
          fi;
          muwrz="$(awk '/^'"$FILE"' /{print $2}' menuwrz)";
          printf "Als Vorlageverzeichnis wird verwendet: ${blau}$muwrz${reset}\n";
          printf "Ist das richtig? (jyJYnN) "; read best;
          case $best in [jyJY]*) ;; *) muwrz=; ;; esac;
        else
          echo "Keine Verzeichnisse gefunden";
        fi;
        W=;
        ;;
    esac;
  fi; # [ "$srv0" ]

  if [ "$srv0" ]; then
    muwrz="$srv0:$HOME";
  fi;

  if [ "$muwrz" ]; then
    
    # SSH-Optionen für rsync:
    _rsync="rsync -avu -e 'ssh -o StrictHostKeyChecking=accept-new'";

    # .vim – bei -mustneu immer, sonst nur wenn fehlend:
    { [ "$1" = "neu" ] || [ ! -d "$HOME/.vim" ]; } && \
      ausf "$_rsync $muwrz/.vim $HOME/";

    # .vimrc und Shell-Scripts – bei -mustneu immer, sonst nur wenn fehlend:
    { [ "$1" = "neu" ] || [ ! -f "$HOME/bin/.vimrc" ]; } && \
      ausf "$_rsync $muwrz/bin/.vimrc $HOME/bin/";
    { [ "$1" = "neu" ] || [ ! -d "$HOME/bin" ]; } && \
      ausf "$_rsync --include='*/' --include='*.sh' --exclude='*' $muwrz/bin $HOME/";

    # Programmkonfigurationen – nur wenn nicht schon durch konfig_laden vorhanden:
    gesD=;
    for D in anrliste autofax dicom fbfax impgl labimp termine; do
      gesD="$gesD $D.conf";
    done;
    if [ -f "$instvz/konfig/verschluesselt/sensibel.tar.gpg" ]; then
      printf "konfig_laden verwaltet .conf-Dateien – rsync für .config/ übersprungen.\n";
    else
      { [ "$1" = "neu" ] || [ ! -d "$HOME/.config" ]; } && \
        ausf "$_rsync $muwrz/.config/ $HOME/.config/ --include \"$gesD\" --exclude \"*\"";
    fi;
   
    # HylaFAX-Spool:
    vsh=/var/spool/hylafax;
    { [ "$1" = "neu" ] || { [ ! -f "$vsh/sendq/seqf" ] && [ ! -f "$vsh/recvq/seqf" ]; }; } && {
      echo "$vsh fehlt, hole es von $muwrz";
      [ -d "$vsh" ] && ausf "mv -i $vsh ${vsh}_$(date +\"%Y%m%d%H%M%S\")";
      [ "$srv0" ] && \
        ausf "$_rsync $srv0:$vsh/ $vsh/" || \
        ausf "$_rsync ${muwrz%/*}$vsh/ $vsh/";
    };
    # CapiSuite-Spool:
    vsh=/var/spool/capisuite;
    { [ "$1" = "neu" ] || ! find "$vsh/autofaxarch/" -type f 2>/dev/null | grep -q .; } && {
      echo "$vsh fehlt, hole es von $muwrz";
      [ -d "$vsh" ] && ausf "mv -i $vsh ${vsh}_$(date +\"%Y%m%d%H%M%S\")";
      [ "$srv0" ] && \
        ausf "$_rsync $srv0:$vsh/ $vsh/" || \
        ausf "$_rsync ${muwrz%/*}$vsh/ $vsh/";
    };
    # fbfax-Spool:
    vsh=/var/spool/fbfax;
    { [ "$1" = "neu" ] || ! find "$vsh/arch/" -type f 2>/dev/null | grep -q .; } && {
      echo "$vsh fehlt, hole es von $muwrz";
      [ -d "$vsh" ] && ausf "mv -i $vsh ${vsh}_$(date +\"%Y%m%d%H%M%S\")";
      [ "$srv0" ] && \
        ausf "$_rsync $srv0:$vsh/ $vsh/" || \
        ausf "$_rsync ${muwrz%/*}$vsh/ $vsh/";
    };
    
    # Webverzeichnis:
    vsh=/srv/www/htdocs;
    { [ "$1" = "neu" ] || [ ! -f "$vsh/plz/=.Neuer_Patient" ]; } && {
      echo "$vsh fehlt, hole es von $muwrz";
      find "$vsh" -type f 2>/dev/null | grep -q . && \
        ausf "mv -i $vsh ${vsh}_$(date +\"%Y%m%d%H%M%S\")";
      [ "$srv0" ] && \
        ausf "$_rsync $srv0:$vsh/ $vsh/ --exclude \"*Papierkorb*\"" || \
        ausf "$_rsync ${muwrz%/*}$vsh/ $vsh/ --exclude \"*Papierkorb*\"";
      chown wwwrun:www -R $vsh;
      systemctl restart apache2;
    };

  fi; # [ "$muwrz" ]
} # musterserver

#holt Datei $1 entweder aus "/DATA/down /DATA/daten/down" ($q0) oder $srv0 oder $2 auf /root/Downloads (=$Dw); $3 = potentieller hol-Name
hol3() {
	printf "${dblau}hol3($1$reset,$dblau$2$reset,$dblau$3)$reset()\n";
	[ "$3" ]&&hname=$3||hname=$1;
	if ! [ -f "$Dw/$1" ]; then
    pfadda=0;
    for hpf in $q0; do if test -d $hpf; then pfadda=1; break; fi; done;
    if [ "$pfadda" = "0" ]; then for hpf in $q0; do mkdir -p $hpf; break; done; fi;  # dann das erste dort genannte Verzeichnis erstellen 
    echo q0: $q0;
    ausf "find $q0 -maxdepth 1 -name $1 2>/dev/null" "${blau}";
    datei=$resu;
		if test "$datei"; then
      datei=$(readlink -e $datei);
			hpf=${datei%/*};
			ausf "cp -ai \"$hpf/$1\" \"$Dw/\"" "${blau}";
    fi;
    [ -f "$Dw/$1" ]||ausf "ssh \"$srv0\" \"ls \\\"$spf/$1\\\" >/dev/null 2>&1\"&& scp -p \"$srv0:$spf/$1\" \"$Dw/\"&&{ [ -d \"$hpf\" ]&&cp -ai \"$Dw/$1\" \"$hpf/\";};" "${blau}"
    [ -f "$Dw/$1" ]||{
      ausf "wget \"$2/$hname\" -O\"$Dw/$1\";" "${blau}"
      [ -f "$Dw/$1" -a -d "$hpf" ]&&cp -ai "$Dw/$1" "$hpf/";
      [ "$srv0" -a -f "$Dw/$1" ]&&scp -p "$Dw/$1" "$srv0:$spf/";
    }
	fi;
} # hol3

tvversion() {
	 tversion=$(teamviewer --version 2>/dev/null|awk '/^.*Team/{print substr($4,1,index($4,".")-1)}');
	 [ "$tversion" ]||tversion=0;
	 printf "Installierte Teamviewer-Version: $blau$tversion$reset\n";
} # tvversion
# teamviewer15: in /usr/share/applications/org.kde.kdeconnect_open.desktop : -MimeType=*/*; +MimeType=application/octet-stream;

teamviewer15() {
 tuti=0;
 which teamviewer 2>/dev/null ||tuti=1;
 [ $tuti = 0 ]&&[ $(teamviewer --version 2>/dev/null|awk '/^.*Team/{print substr($4,1,index($4,".")-1)}') \< 15 ]&&tuti=1;
 if test $tuti = 1; then
   sudo rpm --import  https://download.teamviewer.com/download/linux/signature/TeamViewer2017.asc;
   wget https://download.teamviewer.com/download/linux/teamviewer-suse.x86_64.rpm;
   sudo sudo zypper install teamviewer-suse.x86_64.rpm; 
 fi;
} # teamviewer15()

teamviewer10() {
	printf "${dblau}teamviewer$reset()\n";
	[ ! -d "$Dw" ]&&mkdir -p "$Dw";
	while true; do
	 tvversion;
	 pgrep -if "/opt/teamviewer.*tvguislave" >/dev/null&&[ "$tversion" = 10 ]&&return;
	 case $tversion in
		 0)
				case $OSNR in
				1|2|3) # mint, ubuntu, debian
					trpm=teamviewer_10.0.95021_i386.deb;
					hname=teamviewer_i386.deb;
					npng=libpng12-0_1.2.54-1ubuntu1.1_i386.deb;
					hol3 "$npng" "http://security.ubuntu.com/ubuntu/pool/main/libp/libpng";
					if ! dpkg -s libpng12-0:i386 >/dev/null 2>&1; then
						dpkg -i "$Dw/$npng";
					fi;
					;;
				4|5|6|7) # opensuse, fedora, mageia
					trpm=teamviewer_10.0.95021.i686.rpm; # der 6er stimmmt hier
					hname=teamviewer.i686.rpm;
					;;
				esac;
				hol3 "$trpm" "https://download.teamviewer.com/download/version_10x" "$hname";
			 if [ -f "$Dw/$trpm" ]; then
				case $OSNR in
				1|2|3) # mint, ubuntu, debian
					printf "${blau}apt install $Dw/$trpm$reset\n";
					apt install $Dw/$trpm;
					apt-mark hold teamviewer:i386;
					# bei Ubuntu funktionierte nur (ohne automatisches Upgrade der Teamviewer-Version):
					tvversion;
					if [ "$tversion" != 10 ]; then
					 apt remove teamviewer teamviewer:i386;
					 apt install libjpeg62:i386 libxtst6:i386;
					 dpkg -i $Dw/$trpm;# ./Downloads/teamviewer_10.0.95021_i386.deb;
					fi;
					;;
				4) # opensuse
#					 printf "${blau}zypper --no-gpg-checks in -l $Dw/$trpm$reset\n";
					 printf "${blau}zypper --gpg-auto-import-keys in -l $Dw/$trpm$reset\n";
					 zypper --gpg-auto-import-keys in -y -l $Dw/$trpm;
					;;
				5) # fedora,
					 printf "${blau}dnf --nogpgcheck install $Dw/$trpm$reset\n";
					 dnf --nogpgcheck install $Dw/$trpm;
					 ;;
				6) # fedoraalt
					 printf "${blau}yum --nogpgcheck install $Dw/$trpm$reset\n";
					 yum --nogpgcheck install $Dw/$trpm;
					 ;;
			  7) # mageia
					;;
				esac;
			 fi;
			 ;;
		 10) break;;
		 *) 
				case $OSNR in
				1|2|3) # mint, ubuntu, debian
					printf "${blau}apt remove teamviewer teamviewer:i386$reset\n";
					apt remove teamviewer teamviewer:i386;
					;;
				4)
					 printf "${blau}zypper rm teamviewer teamviewer:i386$reset\n";
					 zypper rm teamviewer teamviewer:i386; 
					;;
				5|6|7) # opensuse, fedora, mageia
					;;
				esac;
			 continue;;
	 esac;
	done;
# 2) libfreetype
	zvz=/opt/teamviewer/tv_bin/wine/lib;
	zd=$zvz/libfreetype.so.6;
	case $OSNR in
		1|2|3)
					npng=libfreetype6_2.6.1-0.1ubuntu2.3_i386.deb;
					hol3 "$npng" "http://security.ubuntu.com/ubuntu/pool/main/f/freetype";
					zdatei=/opt/teamviewer/tv_bin/wine/lib/libfreetype.so.6.12.1;
					if ! [ -f "$zdatei" ]; then
						cd "$Dw";
            echo ar -xv "$npng";
            ar -xv "$npng";
						tar -xvf data.tar.xz;
						cp -ai $(find usr -type f -name "libfreetype*") /opt/teamviewer/tv_bin/wine/lib/;
						cp -ai $(find usr -type l -name "libfreetype*") /opt/teamviewer/tv_bin/wine/lib/;
						cd -;
						# cp ./libfreetype6_2.6.1-0.1ubuntu2.3_i386/usr/lib/i386-linux-gnu/* /opt/teamviewer/tv_bin/wine/lib;
					fi;
					;;
		4) # opensuse
			while :; do
				[ -f "$zd" ]&&break;
				qd=$Dw/usr/lib/libfreetype.so.6.12.3;
				hol3 "$qd";
				while ! [ -f "$qd" ]; do
					qqd=libfreetype6-32bit-2.6.3-5.3.1.x86_64.rpm;
					# geht auch für Fedora
					hol3 "$qqd" "https://download.opensuse.org/update/leap/$(lsb-release -r|cut -f2)/oss/x86_64";
					cd "$Dw";
					rpm2cpio "$qqd"|cpio -idmv
					cd -;
				done;
				echo cp -ai "$qd" "$zd";
				cp -ai "$qd" "$zd";
			done;;
	esac;
# 3) lxcb
	case $OSNR in
	1|2|3) # mint, ubuntu, debian
		;;
	4) # opensuse
		lxcb=libxcb1-32bit-1.11.1-9.1.x86_64;
		if ! rpm -q "$lxcb" >/dev/null; then
		 echo $? bei rpm -q "$lxcb";
     hol3 "$lxcb.rpm" "http://download.opensuse.org/repositories/openSUSE:/Leap:/$(lsb-release -r|cut -f2):/Update/standard/x86_64";
		 rpm -i --force "$Dw/$lxcb.rpm";
		 zypper addlock "$lxcb";
		fi;
		;;
	5|6|7) # fedora, mageia
		;;
	esac;
	cd - >/dev/null;
	tvconf=/opt/teamviewer/config/global.conf;
	tvh="$instvz/tvglobal.conf";
	systemctl stop teamviewerd
	# einige Felder befüllen (außer Passwörtern und der Gruppenzugehörigkeit), sortieren nach dem Feld hinter dem Typbezeichner, Zeile 1 und 2 umstellen und 2 Leerzeilen einfügen
	AWKPATH="$instvz";cd $instvz;awk -f $instvz/awktv.sh "$tvconf"|sed '/^\s*$/d;'|sort -dt] -k2|sed '1{x;d};2{p;x;p;s/.*//;p}' >"$tvh";cd -;
#	sed -i '/^\s*$/d' "$tvh";
	systemctl start teamviewerd;
	echo nach systemctl start teamviewerd;
	if ! diff "$tvconf" "$tvh" >/dev/null; then
		backup "$tvconf"
		cp -a "$tvh" "$tvconf";
	fi;
} # teamviewer10()

# ============================================================
# Änderungen in los.sh für -remotepc Parameter:
#
# 4) Hauptlogik (nach teamviewer-Zeile):
#      [ $obteil = 0 -o "$obrpc" = 1 ]&&remotepc;
#
# HINWEIS: RemotePC unterstützt auf Wayland nur ausgehende Verbindungen.
# Für eingehende Remote-Kontrolle (Server) muss beim Login Xorg gewählt werden.
# OpenSUSE 16.0 startet standardmäßig mit Wayland – beim Anmeldebildschirm
# unten rechts auf "Plasma (X11)" wechseln falls eingehende Verbindungen nötig.
# ============================================================

remotepc() {
  printf "${dblau}remotepc${reset}()\n";

  # Download-URL: muss manuell von remotepc.com/download geholt werden
  # da Login erforderlich. Alternativ aus /DATA/down oder $srv0 holen.
  _rpcrpm="remotepc-host.rpm";  # Host-Only für Server (empfohlen)
  _rpcurl="https://www.remotepc.com/download";  # Downloadseite

  # Prüfen ob bereits installiert:
  if which remotepc-host >/dev/null 2>&1 || which remotepc >/dev/null 2>&1; then
    _rpcv=$(remotepc-host --version 2>/dev/null || remotepc --version 2>/dev/null || echo "unbekannt");
    printf "RemotePC bereits installiert: %b%s%b\n" "$blau" "$_rpcv" "$reset";
    # Service-Status prüfen:
    if systemctl is-active remotepc-host >/dev/null 2>&1; then
      printf "remotepc-host: %baktiv${reset}\n" "$gruen";
    else
      printf "remotepc-host: %bnicht aktiv%b – starte ...\n" "$rot" "$reset";
      systemctl enable remotepc-host 2>/dev/null||true;
      systemctl start  remotepc-host 2>/dev/null||true;
    fi;
    return 0;
  fi;

  # Wayland-Warnung ausgeben:
  if [ "$WAYLAND_DISPLAY" ] || [ "$(loginctl show-session $(loginctl | grep $(whoami) | awk '{print $1}') -p Type 2>/dev/null | grep wayland)" ]; then
    printf "%bHinweis: Wayland erkannt!%b\n" "$rot" "$reset";
    printf "RemotePC unterstuetzt auf Wayland nur %bausgehende%b Verbindungen.\n" "$blau" "$reset";
    printf "Fuer eingehende Verbindungen beim Login auf %bPlasma (X11)%b wechseln.\n" "$blau" "$reset";
  fi;

  # RPM-Datei suchen:
  _rpmgef=;
  printf "Suche rpm in: ${blau}$q0${reset} und ${blau}$Dw${reset}\n";
  for _suchpfad in $q0 "$Dw"; do
    if [ -f "$_suchpfad/$_rpcrpm" ]; then
      _rpmgef="$_suchpfad/$_rpcrpm";
      printf "RPM gefunden: %b%s%b\n" "$blau" "$_rpmgef" "$reset";
      break;
    fi;
  done;

  # Falls nicht lokal – vom Quellserver holen:
  if [ -z "$_rpmgef" ] && [ "$srv0" ]; then
    printf "Suche %b%s%b auf %b%s%b ...\n" "$blau" "$_rpcrpm" "$reset" "$blau" "$srv0" "$reset";
    for _suchpfad in $q0 "$Dw"; do
      scp -p "$srv0:$_suchpfad/$_rpcrpm" "$Dw/" 2>/dev/null && {
        _rpmgef="$Dw/$_rpcrpm";
        printf "Kopiert von %b%s%b\n" "$blau" "$srv0" "$reset";
        break;
      };
    done;
  fi;

  # Falls immer noch nicht gefunden – Hinweis ausgeben:
  if [ -z "$_rpmgef" ]; then
    printf "%bRemotePC RPM nicht gefunden.%b\n" "$rot" "$reset";
    printf "Bitte %bremotepc-host.rpm%b von %b%s%b herunterladen\n" \
      "$blau" "$reset" "$blau" "$_rpcurl" "$reset";
    printf "und nach %b%s%b kopieren, dann erneut aufrufen.\n" \
      "$blau" "$(echo $q0 | cut -d' ' -f1)" "$reset";
    return 1;
  fi;

  # Installieren:
  printf "Installiere %b%s%b ...\n" "$blau" "$_rpmgef" "$reset";
  case $OSNR in
    4) # OpenSUSE:
      zypper -n --no-gpg-checks install "$_rpmgef" 2>&1;;
    1|2|3) # Debian/Ubuntu:
      _debrpm="${_rpmgef%.rpm}.deb";
      [ -f "$_debrpm" ] && apt-get install -y "$_debrpm" || \
        printf "%bKein .deb gefunden – bitte remotepc-host.deb verwenden%b\n" "$rot" "$reset";;
    5|6) # Fedora/RHEL:
      dnf install -y "$_rpmgef" 2>/dev/null || yum install -y "$_rpmgef";;
    *) zypper -n install "$_rpmgef" 2>/dev/null || rpm -i "$_rpmgef";;
  esac;

  # Nach Installation:
  if which remotepc-host >/dev/null 2>&1; then
    printf "%bRemotePC erfolgreich installiert.%b\n" "$gruen" "$reset";
    # Autostart einrichten:
    systemctl enable remotepc-host 2>/dev/null||true;
    systemctl start  remotepc-host 2>/dev/null||true;
    printf "\nNaechste Schritte:\n";
    printf "  1. %bremotepc-host login%b\n" "$blau" "$reset";
    printf "     oder: %bremotepc-host deploy <Deployment-ID>%b\n" "$blau" "$reset";
    printf "  2. Computer-Name und Personal Key setzen\n";
    printf "  3. Fuer eingehende Verbindungen: beim Login %bPlasma (X11)%b waehlen\n" "$blau" "$reset";
    # Interaktiv konfigurieren falls Deployment-ID bekannt:
    # Deployment-ID nur für Enterprise – für normale Accounts login verwenden:
    if [ -t 0 ]; then
      printf "Enterprise-Account? Deployment-ID eingeben (leer = normaler Account): ";
      read _deployid;
      if [ "$_deployid" ]; then
        remotepc-host deploy "$_deployid";
      else
        printf "Bitte anmelden:\n";
        remotepc-host login;
      fi;
    fi;    
  else
    printf "%bInstallation fehlgeschlagen.%b\n" "$rot" "$reset";
  fi;
} # remotepc


# github() – trägt den eigenen SSH-Schlüssel bei GitHub ein
# und setzt die Remote-URL des Repositories auf SSH um
github() {
	printf "${dblau}github()$reset()\n";
	machidpub;
	# Prüfen ob Schlüssel bereits bei GitHub eingetragen:
	if { key=$(sed 's/.* \(.*\) .*/\1/;s/\//\\\//g;' $idpub);curl https://github.com/$GITACC.keys 2>/dev/null|sed -n '/'$key'/q1';}; then
		echo curl -u "$GITACC" --data '{"title":"'"$(whoami)"'@'"$(hostname)"'","key":"'"$(cat $idpub)"'"}' https://api.github.com/user/keys;
		curl -u "$GITACC" --data '{"title":"'"$(whoami)"'@'"$(hostname)"'","key":"'"$(cat $idpub)"'"}' https://api.github.com/user/keys;
	fi;
	git remote set-url origin git@github.com:$GITACC/$DPROG.git;
} # github

# backup() – rollierende Sicherung einer Datei (bis zu 100 Versionen)
# $1 = Basisdateiname (z.B. /etc/samba/smb.conf)
# $2 = alternative Quelldatei (optional; Standard: $1)
# Erzeugt: $1_0 (aktuell), $1_1 (vorherige), ... $1_100 (älteste)
backup() {
	printf "${dblau}backup$reset($1,$2)\n";
		for i in $(seq 100 -1 0); do
			if [ -s ${1}_$i ]; then
				mv ${1}_$i ${1}_$(echo $i|awk '{print $0+1}') 2>/dev/null;
			fi;
		done;
		[ "$2" ]&&ursp="$2"||ursp="$1";
		[ -s "$ursp" ]&& mv "$ursp" "${ursp}_0";
} # backup

# ============================================================
# 4) In Hauptlogik ersetzen:
#    Vorher: [ $obteil = 0 ]&&cron;
#    Nachher:
#      [ $obteil = 0 -o "$obcron" = 1 ]&&cron;
# ============================================================

cron() {
  printf "${dblau}cron${reset}()\n";
    # Quellserver abfragen falls nicht gesetzt und interaktiv:
  if [ -z "$srv0" ] && [ -t 0 ]; then
    printf "Quellserver (leer lassen für nur lokale Sicherung): ";
    read _srv0eingabe;
    if [ "$_srv0eingabe" ]; then
      srv0="$_srv0eingabe";
      printf "Quellserver: ${blau}$srv0${reset}\n";
    fi;
  fi;
  chier=$instvz/cronhier;

  # 1) Aktuelle crontab sichern:
  backup "$chier";
  crontab -l >"$chier" 2>/dev/null||true;
  printf "crontab gesichert in ${blau}$chier${reset}\n";

  # 2) Crontab vom Quellserver holen (nur wenn $srv0 gesetzt):
  if [ "$srv0" ]; then
    csrv=$instvz/crons$srv0;
    backup "$csrv";
    printf "Hole crontab von ${blau}$srv0${reset} ...\n";
    ssh $(whoami)@$srv0 "crontab -l" >"$csrv" 2>/dev/null;
    if [ $? -ne 0 ]; then
      printf "${rot}SSH-Verbindung zu $srv0 fehlgeschlagen – verwende lokale crontab${reset}\n";
      csrv=$chier;
    else
      printf "crontab von ${blau}$srv0${reset} gesichert in ${blau}$csrv${reset}\n";
    fi;
  else
    printf "${blau}srv0${reset} nicht gesetzt – kein Quellserver, verwende lokale crontab.\n";
    csrv=$chier;
  fi;

  # 3) Arbeitskopie erstellen:
  [ "$srvhier" ]||srvhier=$(uname -n);
  crh=$instvz/cronshier;
  cp -a "$csrv" "$crh";

  # 4) Scripte aus crontab ermitteln die lokal vorhanden sind:
  ca=$instvz/cronbefehle;
  rm -f "$ca";
  touch "$ca";
  # Erklärung:
  # - Kommentarzeilen entfernen
  # - Zeitangaben und @-Direktiven entfernen
  # - An Leerzeichen aufteilen
  # - Ausdrücke mit Sonderzeichen und Leerzeilen entfernen
  # - Abschließende Semikolons entfernen
  # - Nur lesbare Nicht-Verzeichnis-Dateien mit Shebang aufnehmen
  sed -nr '/^#/d;s/^([^ ]+ +){5}|^@[^ ]+ //;s/ /\n/g;p' "$csrv" | \
    sed -r '/^-|[][>$|<:*"`'\''=&\\,}{]|^$/d;s/;$//' | \
    while read zeile; do
      if test -r "$zeile" -a ! -d "$zeile"; then
        if ! grep -Fxq "$zeile" "$ca"; then
          sed -n '/^#!/!q1;q0' "$zeile" && echo "$zeile" >>"$ca";
        fi;
      fi;
    done;
  [ -s "$ca" ] && printf "Gefundene Scripts:\n$(cat $ca)\n" || \
    printf "Keine lokalen Scripts in crontab gefunden.\n";

  # 5) Servernamen in Scripts austauschen (nur wenn Quellserver gesetzt):
  if [ "$srv0" ] && [ "$srv0" != "$srvhier" ]; then
    while read z; do
      if grep -qe "\(\<$srv0\>\|\<$srvhier\>\)" "$z" 2>/dev/null; then
        sed -i.bak \
          's/\<'$srvhier'\>/'${srvhier}'ur/g;s/\<'$srv0'\>/'$srvhier'/g' "$z";
        printf "In ${blau}$z${reset}: ${blau}$srvhier${reset} → ${blau}${srvhier}ur${reset}, ${blau}$srv0${reset} → ${blau}$srvhier${reset}\n";
      else
        [ "$verb" ] && \
          printf "${blau}$z${reset}: kein ${blau}$srvhier${reset} oder ${blau}$srv0${reset} – unverändert\n";
      fi;
    done <"$ca";
  fi;

  # 6) Neue crontab installieren – nur wenn $crh existiert und nicht leer:
  if [ -s "$crh" ]; then
    printf "Installiere crontab aus ${blau}$crh${reset} ...\n";
    crontab <"$crh";
    printf "crontab installiert.\n";
  else
    printf "${rot}$crh leer oder fehlt – crontab nicht installiert${reset}\n";
  fi;
} # cron

tu_turbomed() {
# auch: GDT.ini nach c:\turbomed\Formulare\Karteikarte kopieren
	printf "${dblau}tu_turbomed$reset($1 $2)\n";
	echo Installations-Verzeichnis: $outDir;
	mkdir -p $POET_LICENSE_PATH;
	ausf "cp $license $POET_LICENSE_PATH" "${blau}";
	case $OSNR in 1|2|3)endg=".deb";; 4|5|6|7)endg=".rpm";;esac;
	for D in $archive/*$endg; do $psuch $(basename $D $endg) >/dev/null||$insg $D; done;
  cd ${TMsetup%/*};
  [ "$verb" = 0 ]||echo Setupverzeichnis: ${TMsetup%/*}
  sh TM_setup $1
  ret=$?
  echo $ret;
  [ $ret != 0 -a "$2" ]&&sh TM_setup $2;
  cd -;
  convmv /opt/turbomed/* -r -f iso8859-15 -t utf-8 --notest;
	systemctl daemon-reload;
	for runde in $(seq 1 20);do 
    systemctl show poetd|grep running&&break;
    echo Starten von poetd, Runde: $runde; 
    pkill -9 ptserver;
    systemctl stop poetd;
    systemctl start poetd; 
  done;
  if [ "$muwrz" -a -s "$muwrz/../opt/turbomed/PraxisDB/objects.dat" ]; then
    for S in PraxisDB StammDB DruckDB Dictionary; do
      ausfd "rsync -avu $muwrz/../opt/turbomed/$S /opt/turbomed/";
    done;
    ausfd "rsync -avu $muwrz/../DATA/turbomed /DATA/";
  else
    [ "$srv0" ]||{ printf "Bitte ggf. Server angeben, von dem die Turbomed-Datenbanken kopiert werden sollen: ";read srv0;};
    [ "$srv0" ]&&{ 
      for S in PraxisDB StammDB DruckDB Dictionary; do
        ausfd "rsync -avu $srv0:/opt/turbomed/$S /opt/turbomed/";
      done;
      ausfd "rsync -avu $srv0:/DATA/turbomed /DATA/";
    }
  fi;
  chmod -R 770 /opt/turbomed
  chmod 550 /opt/turbomed
  # Loeschen: sh TM_setup -rm, zypper se FastObj, dann zypper rm -y ... fuer alle Namen; ggf. rm -rf /opt/Fast*, ggf. rm /etc/init.d/poetd
} # tu_turbomed

turbomed() {
	printf "${dblau}turbomed$reset()\n";
	# /DATA/down/CGM_TURBOMED_Version_19.2.1.4087_LINUX.zip
	tmsuch="CGM_TURBOMED*LINUX.zip";
	datei=$(find $q0 -name "$tmsuch" -printf "%f\1%p\n" 2>/dev/null|sort|tail -n1|cut -d $(printf '\001') -f2-);
  [ "$verb" = 1 ]&&echo "Datei: $datei"
	if test -z "$datei"; then echo keine Datei \"$tmsuch\" in \"$q0\" gefunden; return; fi;
	# 19.1.1.3969
  stamm=$(basename "$datei");
  echo Stamm: $stamm;
#	version=$(echo $datei|cut -d_ -f4|cut -d. -f1-2);
	version=$(echo $stamm|cut -d_ -f4|cut -d_ -f4);
	printf "Turbomed-Version: $blau$version$reset\n";
#	outDir="${datei%/*}/TM${version}L";
	outDir="${datei%/*}/TMWin"; # Name wird benötigt für setup
  echo datei: $datei
  echo outDir: $outDir
	[ -d  "$outDir" ]||ionice -c3 nice -n19 7z x $datei -o"$outDir";
#  outDir2=$outDir/linux;
  outDir2=$(find $outDir -type d -name linux);
  echo outDir2: $outDir2
#  [ -d "$outDir2" ]||mv $outDir/* $outDir2;
	instVers=$(find "$outDir2" -name "*OpenSSL*"|sort -r|cut -d- -f4|head -n1);
  TMsetup=$(find $outDir2 -name TM_setup -print -quit)
  echo TMsetup: $TMsetup
  archive=$(find $outDir2 -type d -name archive -print -quit)
  echo archive: $archive
  license=$(find $outDir2 -name license -print -quit)
  echo license: $license

#		POET_LICENSE_PATH="/opt/FastObjects_t7_12.0/runtime/lib";
#		POET_LICENSE_PATH="/opt/$(find $outDir2 -name "*OpenSSL*" -printf "%f\n"|cut -d- -f-2)/runtime/lib";
	POET_LICENSE_PATH=$(grep "POET_LICENSE_PATH=" $TMsetup|cut -d= -f2|sed 's/\"\(.*\)\"/\1/g');
  echo POET_LICENSE_PATH: $POET_LICENSE_PATH
#	if systemctl list-units --all|grep poetd >/dev/null; then
  if [ -s /etc/init.d/poetd ]; then
#		echo "export LD_LIBRARY_PATH=$POET_LICENSE_PATH;$LD_LIBRARY_PATH/../bin/ptsu -help|grep Version|rev|sed 's/^[[:space:]]//'|cut -d' ' -f1|rev;"
		laufVers=$(export LD_LIBRARY_PATH=$POET_LICENSE_PATH;"$LD_LIBRARY_PATH"/../bin/ptsu -help|grep Version|rev|sed 's/^\s*//'|cut -d' ' -f1|rev);
  	echo laufVers: "$laufVers"
	  echo instVers: "$instVers";
#   12.0.2.208
    [ "$laufVers" = "$instVers" ]||{ printf "Turbomed mit $laufVers ggü. $instVers zu alt.\n";tu_turbomed "-uw";};
	else
		printf "Installiere Turbomed neu\n";
		tu_turbomed "-iw" "-uw" # -tw
	fi;
} # turbomed

dbinhalt() {
  VZ=/DATA/sql;
	printf "${dblau}dbinhalt$reset()\n";
#  pruefmroot;
  pd=$instvz/sqlprot.txt;
  [ "$verb" ]&&printf "obschreiben: $blau$obschreiben$reset, loscred: $blau$loscred$reset, Vergleichsdatei: $blau$pd$reset\n";
  datadir=$(sed -n '/^[[:space:]]*datadir[[:space:]]*=/{s;.*=[[:space:]]*\(.*\);\1;p}' /etc/my.cnf);
#  for dt in $(VZ=/DATA/sql;for db in $(find $VZ -maxdepth 1 -name "*--*.sql" -not -name "mysql--*" -not -name "information_schema--*" -not -name "performance_schema--*" -printf "%f\n"|sed 's/^\(.*\)--.*/\1/'|sort -u); do ls $VZ/$db--*.sql -t|head -n1; done); do scp -p $dt linux8:/DATA/sql/; done
  [ "$verb" ]&&printf "datadir: $blau$datadir$reset\n";
  [ "$datadir" ]&& chown mysql:mysql -R "$datadir";
  # alle Rümpfe, jeden einmal
  for db in $(find $VZ -maxdepth 1 -name "*--*.sql" -not -name "mysql--*" -not -name "information_schema--*" -not -name "performance_schema--*" -printf "%f\n"|sed 's/^\(.*\)--.*/\1/'|sort -u); do
    [ "$verb" ]&&printf "Untersuche $blau$db$reset: ";
#    test "$mrpwd"||echo Bitte gleich Passwort für mysql-Benutzer "$mroot" eingeben:
    dbda=$(! $mysqlbef --defaults-extra-file=~/.mysqlrpwd -hlocalhost -e"use \"$db\"" >/dev/null 2>&1;printf $?);
    # wenn "immer" oder Datenbank nicht existiert, dann
    if test "$1"/ = immer/ -o $dbda = 0; then
      [ "$verb" ]&&{ [ "$1"/ = immer ]&&echo immer; [ "$dbda" = 0 ]&&echo dbnichtda;};
#      printf "$blau$db$reset"; if test "$1"/ = immer/; then printf " wird neu gespeichert!\n"; else printf " fehlt als Datenbank!"; fi;
#      Q=$(ls "$VZ/"$db--*.sql -S|head -n1);     # die als jüngste benannte Datei ...
      Q=$(awk -v pfad="$VZ" -v n1="$db--" -v n2=".sql" -f $instvz/awkfdatei.sh);
      Zt=$(echo $Q|sed 's:.*--\([^/]*\)\..*$:\1:;s/[-.]//g'); # Zeit rausziehen
      Sz=$(stat "$Q" --printf="%s\\n");
      [ -f $pd ]||echo "Letzte Datenbankeintragungen:" >$pd;
#      test "$mrpwd"||echo Bitte gleich Passwort für mysql-Benutzer "$mroot" eingeben:
#      mysql -u"$mroot" -p"$mrpwd" -hlocalhost -e"SET session innodb_strict_mode=Off";
      # überprüfen, ob ind $pd schon die gleiche oder eine jüngere Datei eingetragen wurde
      awk '/'$db'=/{\
        gef=1;\
        split($0,teil,"=");\
        zei=teil[2]>'$Zt'?">":teil[2]<'$Zt'?"<":"=";\
        printf "'$blau'"teil[2]"'$reset'"zei"'$blau$Zt$reset' =>";\
        if (zei==">"||zei=="="){\
          print "ueberspringe '$blau$db$reset'";\
          fertig=1;\
          exit\
        }\
       }\
       END{\
        if(fertig)exit 1;\
        if(!gef)printf "'$blau$db$reset' nicht gefunden, ";\
        printf "verarbeite '$blau$db$reset':"\
       }' $pd
      if [ $? = 0 -o $dbda = 0 ]; then
        # ... die auch eine Datenbank enthält
#        ausf "grep '^CREATE DATABASE' \"$Q\""; if test "$resu"; then
        if test "$(grep '^CREATE DATABASE' "$Q")"; then
         LC_NUMERIC=de_DE printf " Stelle sie von \"$blau$Q$reset\" her (Größe: $blau%'.f$reset)!\n" $Sz
         sed -i.bak 's/ROW_FORMAT=FIXED//g' "$Q";
#         ausf "mysql -u\"\$mroot\" -p\"\$mrpwd\" -hlocalhost <\"\$Q\""
#         printf "Q: $blau$Q$reset;";
         ausf "$mysqlbef --defaults-extra-file=~/.mysqlrpwd --skip-lock-tables -hlocalhost <\"$Q\""
         [ $ret = 0 ]&&{
           ausf "sed -i '/^\\($db=\\).*/{s//\\1$Zt/;:a;n;ba;q};\$a$db=$Zt' $pd"
  # oder:        sed -i '/^\('$db'=\).*/{s//\1'$Zt'/;:a;n;ba;q};$a'$db'='$Zt'' $pd
         } 
        else
         printf " Datei \"$Q\" enthaelt aber keine Datenbank!\n";
        fi;
      fi;
    fi;
  done;
	printf "${dblau}Ende dbinhalt$reset()\n";
} # dbinhalt

# ============================================================
# HAUPTLOGIK – hier beginnt die eigentliche Ausführung
# ============================================================
printf "${dblau}$0$reset()${blau} Copyright Gerald Schade$reset\n"
commandline "$@"; # alle Befehlszeilenparameter auswerten
# Prüfen ob bash (read -e) oder sh:
echo a|read -e 2>/dev/null; obbash=$(awk 'BEGIN{print ! '$?'}');
# Root-Rechte sicherstellen:
test "$(id -u)" -eq 0||{ printf "Wechsle zu ${blau}root$reset, bitte ggf. ${blau}dessen$reset Passwort eingeben für Befehl ${blau}su -c $meingespfad \"$gespar\"$reset: ";su -c "$meingespfad $gespar";exit;};
echo Starte mit los.sh...
# Reihenfolge der Funktionsaufrufe:
# $obteil=0: alle Funktionen; $obteil=1: nur die mit gesetztem ob*-Flag
[ $obteil = 0 -o $obbs = 1 ]&&bildschirm;         # Bildschirm/Keyboard einrichten
[ $obteil = 0 -o $obbw = 1 ]&&bleibwach;           # Suspend/Hibernate deaktivieren
variablen;                                          # Variablen aus vars/configure laden
echo osnr: $OSNR;
 [ $obteil = 0 -o $obhost = 1 ]&&setzhost;         # Hostname setzen
 [ $obteil = 0 -o $obsmb = 1 ]&&setzbenutzer;      # Benutzer/Samba einrichten
 setzpfad;                                          # /root/bin in PATH aufnehmen
 [ $obteil = 0 -o $obprompt = 1 ]&&setzprompt;     # Shell-Prompt konfigurieren
 [ $obteil = 0 -o $obfritz = 1 ]&&fritzbox;        # Fritzbox einbinden
 [ $obteil = 0 -o $obmt = 1 ]&&mountlaufwerke;     # Laufwerke in fstab eintragen
 [ "$obteil" = 0 -o "$obprog" = 1 -o "$obmysql" = 1 -o "$obmyuser" = 1 -o "$obmysqlneu" = 1 -o "$obmysqli" = 1 -o "$obsmb" = 1 ]&&setzinstprog; # Paketverwaltungs-Variablen setzen
 [ $obteil = 0 -o $obprog = 1 ]&&proginst;         # Programme installieren + Git-Repos klonen
 [ $obteil = 0 -o $obmyuser = 1 -o $obmysql = 1 -o $obmysqlneu = 1 ]&&richtmariadbein; # MariaDB einrichten
 [ $obteil = 0 -o $obsmb = 1 ]&&sambaconf;         # Samba konfigurieren
 [ $obteil = 0 -o $obmust = 1 ]&&musterserver;     # Dateien vom Musterserver kopieren
 [ "$obmustneu" = 1 ]&&musterserver neu;
 [ $obteil = 0 ]&&firewall http https dhcp dhcpv6 dhcpv6c postgresql ssh smtp imap imaps pop3 pop3s vsftp mysql rsync turbomed; # Firewall-Ports freigeben (Vollaufruf)
 [ $obteil = 0 -o $obtv = 1 ]&&teamviewer15;       # TeamViewer installieren
 [ $obteil = 0 -o "$obcron" = 1 ]&&cron;           # crontab vom Quellserver übernehmen
 [ $obteil = 0 -o $obtm = 1 ]&&turbomed;           # Turbomed-Praxissoftware einrichten
 [ $obteil = 0 -o "$obrpc" = 1 ]&&remotepc;        # RemotePC installieren
 [ $obteil = 0 -o $obkonfigsp = 1 ]&&konfig_sichern;  # Konfiguration verschlüsselt sichern
 [ $obteil = 0 -o $obkonfiglad = 1 ]&&konfig_laden;   # Konfiguration laden (nur fehlende)
 [ $obkonfignl = 1 ]&&konfig_laden neu;               # Konfiguration laden (alles überschreiben)
 [ "$obteil" = 0 -o "$obmysql" = 1 -o "$obmysqli" = 1 -o "$obmysqlneu" = 1 ]&&{ [ "$obmysqli" = 1 -o "$obmysqlneu" = 1 ]&&{ dbinhalt immer;:; }||{ [ "$obmysql" = 1 ]&&dbinhalt; } } # Datenbankinhalt importieren
 [ $obteil = 0 ]&&speichern;                        # Konfiguration in Dateien schreiben
 [                $obfb = 1 ]&&firebird;            # Firebird-Datenbank einrichten
printf "${dblau}Ende von $0$reset\n";

if false; then
	eintr="@reboot mount /$Dvz";
	tmp=vorcrontab;
	if ! crontab -l|sed '^[^#]' >/dev/null 2>&1; then {
		echo "$eintr" >$tmp; crontab <$tmp;
		printf "\"$blau$eintr$reset\" in crontab eingetragen.\n";
	} else {
	crontab -l|grep -q "^$eintr" ||{ crontab -l|sed "/^[^#]/i$eintr" >$tmp;crontab <$tmp;printf "\"$blau$eintr$reset\" in crontab ergänzt.\n";};
} fi;
fi;

