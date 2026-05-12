#!/bin/bash
# dash geht nicht: --exclude={,abc/,def/} wirkt nicht
# soll alle relevanten Datenen kopieren, fuer z.B. 2 x täglichen Gebrauch
MUPR=$(readlink -f $0); # Mutterprogramm
. ${MUPR%/*}/bul1.sh # LINEINS=linux1ur, buhost festlegen # ./bul1.sh
[ "$buhost"/ = "$LINEINS"/ ]&&ZL=||QL=$LINEINS;
. ${MUPR%/*}/bugem.sh # commandline-Parameter, $ZL aus commandline, $qssh, $zssh festlegen # ./bugem.sh
. ${MUPR%/*}/bustate.sh # Zeitstempel-Verwaltung für inkrementelles Backup
# Falls -q gesetzt: Quellrechner explizit, Zielrechner = lokal
# Überschreibt die Logik aus bul1.sh:
[ "$QL" -a "$QL" != "$LINEINS" -a -z "$ZL" ]&&{
  printf "Explizite Quelle: ${blau}$QL${reset} → Ziel: ${blau}lokal${reset}\n";
  # qssh/zssh werden in bugem.sh nach commandline() gesetzt – hier nochmal überschreiben:
  qssh="ssh $QL";
  zssh="sh -c";
  QmD="$QL:";
  ZmD=;
};
[ "$buhost"/ != "$LINEINS"/ -a "$ZL" ]&&{ printf "Ziel \"$blau$ZL$reset\" wird zurückgesetzt.\n"; ZL=;ZmD=;}
[ "$buhost"/ = "$LINEINS"/ -a -z "$ZL" ] && [ -z "$obhilfe" ] && { printf "${rot}Kein Ziel angegeben. Breche ab$reset.\n";exit;}
# kopiermt "opt/turbomed" ... "" "$OBDEL" PraxisDB/objects.dat 1800
# -----------------------------------------------------------------------
# Inkrementeller Modus (Standard) vs. Vollabgleich:
#   Sonntags (Wochentag 7) oder mit -f (force) → kopiermt (vollständig)
#   Alle anderen Tage                           → kopiermt_delta (nur Änderungen)
# Manueller Vollabgleich: bulinux.sh -e -f
# [ "$(date +%u)" = 7 ] && _bu_vollabgleich=1 || \
   _bu_vollabgleich=;
[ "$obforce" ] && _bu_vollabgleich=1;
if [ "$sdneu" ]; then
  printf "${blau}Schutzdatei-Verteilung${reset}: ${blau}%s${reset}\n" "$SD";
elif [ "$_bu_vollabgleich" ]; then
  printf "${blau}Vollabgleich${reset} (-f)\n";
elif [ "$obdb" ] && [ -z "$obdt" ] && [ -z "$obdt1" ] && [ -z "$obdt2" ]; then
  printf "${blau}Nur Datenbank${reset} (-db)\n";
elif [ "$obdt1" ] && [ -z "$obdt2" ] && [ -z "$obdb" ]; then
  printf "${blau}Nur Konfigdateien+MO${reset} (-dt1)\n";
elif [ "$obdt2" ] && [ -z "$obdt1" ] && [ -z "$obdb" ]; then
  printf "${blau}Nur /DATA${reset} (-dt2)\n";
else
  printf "${blau}Inkrementeller Abgleich${reset} (delta";
  [ "$obdt1" ] && printf ", dt1";
  [ "$obdt2" ] && printf ", dt2";
  [ "$obdb" ]  && printf ", db";
  printf ")\n";
fi;
_bu_fehler=;  # Fehler-Flag
_bu_start=$(date +%s);  # Gesamtstartzeit
# Zeitformat-Hilfsfunktionen
_bu_ts()  { date "+%d.%m.%y %H:%M:%S"; }
_bu_dur() { local s=$(( $(date +%s) - ${1:-$_bu_start} ));
            printf "%02d:%02d:%02d" $((s/3600)) $(((s%3600)/60)) $((s%60)); }
_bu_hdr() { printf "${blau}── %s: %s ──────────────────────────${reset}\n" "$1" "$(_bu_ts)"; }
_bu_ftr() { printf "${blau}── %s: %s  Dauer: %s ────${reset}\n" "$1" "$(_bu_ts)" "$(_bu_dur $2)"; }
# Wrapper: ruft je nach _bu_vollabgleich kopiermt oder kopiermt_delta auf
bukopierfn() { [ "$_bu_vollabgleich" ] && kopiermt "$@" || kopiermt_delta "$@"; }
# -----------------------------------------------------------------------
# dt1-Block: Konfigdateien + MO (nicht DATA)
_bu_ob_dt1() { [ -n "$obdt1" ] || { [ -z "$obdb" ] && [ -z "$obdt2" ]; }; }
# dt2-Block: /DATA-Verzeichnisse
_bu_ob_dt2() { [ -n "$obdt2" ] || { [ -z "$obdb" ] && [ -z "$obdt1" ]; }; }
# db-Block: Datenbank
_bu_ob_db()  { [ -n "$obdb"  ] || { [ -z "$obdt" ] && [ -z "$obdt1" ] && [ -z "$obdt2" ]; }; }
if _bu_ob_dt1; then  # dt1: Konfigdateien + MO
  _bu_ts_dt1=$(date +%s); _bu_hdr "dt1 Beginn";
# auf Rechner mit kleinen Platten weniger kopieren
case "$ZL" in *3|*7|*8)oburz=1;; *)obkurz=;;esac;
# Faxprotokolle und alte Faxe, Linux-Mails
kopiermt "var/spool" ... "" "" "" "" 1
# Editoreinstellungen
kopieros ".vim"
# Berechtigungen zum Mounten der Fritz-Box als cifs-Laufwerk
kopieros ".fbcredentials"
# aktuelle Kopie dieser Datei
kopieros "crontabakt"
# Verzeichnis für den Mailaufruf in /root
kopieros ".getmail"
# Passwort für Verschlüsselung
kopieros ".7zpassw"
# Passwort für Mysql/Mariadb
kopieros ".mysqlpwd"
# Passwort für Mysql/Mariadb-Superuser
kopieros ".mysqlrpwd"
# Passwort für MO-Datenbank-Superuser
kopieros ".modbpwd"
# Passwort für cifs-Mounts
kopiermt home/schade/.wincredentials ... "" "" "" "" 1
kopieros ".sturm"
# Konfigurationsdateien für postfix-Mailprogramm
kopiermt "etc/sysconfig/postfix" ... "" "" "" "" 1
for D in main.cf master.cf sasl_passwd; do
  kopiermt "etc/postfix/$D" ... "" "" "" "" 1
done;
# selbst erstellte Scripte
V=/root/bin/;
altverb=$verb;
verb=1;
if [ "$obecht" ]; then
  ausf "$kopbef -avu $ergae --prune-empty-dirs --include='*/' --include='*.sh' --exclude='*' '$QmD$V' '$ZmD$V'" $dblau;
else
  printf "Befehl wäre: $dblau$kopbef -avu $ergae --prune-empty-dirs --include='*/' --include='*.sh' --exclude='*' '$QmD$V' '$ZmD$V'$reset\n";
fi;
fi; # Ende dt1-A Konfigdateien
verb=$altverb;
# fi;
# kopieros "root/bin" # auskommentiert 29.7.19
# kopieros "root/" # auskommentiert 29.7.19
# DATA-Platte auf Quelle und Ziel mounten
Dt=DATA; 
# $DATAZIEL aus bul1.sh – Zielverzeichnis für /DATA-Kopien:
[ "$DATAZIEL" ] || DATAZIEL=DATA; # Fallback falls bul1.sh alt
DtZ=$DATAZIEL; # Ziel-Äquivalent von $Dt
machssh;
ausf "$qssh 'mountpoint -q /$Dt||mount /$Dt'" $blau;
ausf "$zssh 'mountpoint -q /$DtZ||{ mountpoint -q /$Dt||mount /$Dt;}'" $blau;
# falls die gemountet sind ...
if $qssh "mountpoint -q /$Dt 2>/dev/null" && \
 { $zssh "mountpoint -q /$DtZ 2>/dev/null" || $zssh "test -d /$DtZ 2>/dev/null"; }; then
	_bu_ob_dt1 && {
	  # dt1-B: MO-Daten (von Windows-Share, nicht /DATA)
    mountpoint -q /mnt/wser/mosich||mount /mnt/wser/mosich
    mountpoint -q /mnt/wser/mosich&&{
      mouvz=$(find /mnt/wser/mosich -maxdepth 1 -name "2*" -type d | sort -r | head -1);
      mouvz=${mouvz#/};  # führendes / entfernen
      if [ "$obecht" ]; then
        $zssh "mkdir -p /$DtZ/MO/Sich";
        $zssh "mkdir -p /$DtZ/MO/INDAMED";
      else
        printf "Simulation: mkdir -p /$DtZ/MO/Sich\n";
        printf "Simulation: mkdir -p /$DtZ/MO/INDAMED\n";
      fi;
      bukopierfn "$mouvz"/ /$DtZ/MO/Sich/ "" "" "" 0 1 1 || _bu_fehler=1
      kopiermt mnt/wser/mosich/my.ini /$DtZ/MO/Sich/ "" "" "" 0 1 1
      bukopierfn mnt/wser/indamed/ /$DtZ/MO/INDAMED/ ",dat/,redomed/,Backup/" "" "" 0 1 || _bu_fehler=1
      mostat=$(ssh linux1 ls -t /mnt/wser/indamed/dat/MOSTAT*.gdb|head -n1);
      if test -n "$mostat"; then
        kopiermt ${mostat:1} /$DtZ/MO/INDAMED/dat/ "" "" "" 0 1
      fi
      bukopierfn mnt/wser/indamed/dat/medoffDB /$DtZ/MO/INDAMED/dat/ "" "" "" 0 1 || _bu_fehler=1
      bukopierfn mnt/wser/indamed/dat/files /$DtZ/MO/INDAMED/dat/ "" "" "" 0 1 || _bu_fehler=1
    }
	if ssh linux1 mountpoint -q /mnt/anmmw; then
		kopiermt mnt/anmmw/users/sturm/Documents/Outlook-Dateien /$DtZ/Mail/out "" "" diabetologie@dachau-mail.de.pst 43200 1
	fi;
	}; # Ende dt1-B MO
	_bu_ob_dt1 && _bu_ftr "dt1 Ende  " $_bu_ts_dt1;
	_bu_ob_dt2 && { _bu_ts_dt2=$(date +%s); _bu_hdr "dt2 Beginn"; };
# kopiermt() { # mit test
  # $1 = Verzeichnis auf Quelle
  # $2 = Verzeichnis auf Ziel
  # $3 = excludes
  # $4 = Optionen 
	# $5 = Pfad zur Datei, die als Alterskriterium geprüft werden soll
	# $6 = Zahl der Sekunden Altersunterschied, ab der kopiert werden soll
  # $7 = ob ohne Platzprüfung
  # $8 = ob ohne Schutzdateivergleich
  # vorher müssen ggf. Quellrechner in $QL (z.Zt. nur: leer oder linux1ur) und Zielrechner in $ZL hinterlegt sein

#  ... dann Mail-Verzeichisse kopieren,
 if _bu_ob_dt2; then
# for uverz in $(find /$Dt/Mail/Thunderbird/Profiles -mindepth 1 -maxdepth 1 -type d); do
 for uverz in Praxis Schade Kothny Hammerschmidt Beraterinnen; do
  if test $uverz = Praxis -o ! "$obkurz"; then # wegen Speicherplatz auf linux7
   qverz=$Dt/Mail/Thunderbird/Profiles/$uverz;
	 $qssh "find /$qverz -iname INBOX" |while IFS= read -r inbox; do
     [ "$sdneu" ]||echo inbox: "$inbox";
     # eine Woche
     [ "$obforce" ]&&testdat=||testdat=${inbox##/$qverz/};
		 bukopierfn $qverz ... "" -d "$testdat" 604800 || _bu_fehler=1;
		 break;
   done;
  fi;
 done;
#  ... sodann die folgenden Verzeichisse: 
# for A in sql; do
 for A in eigene\\\ Dateien Patientendokumente turbomed shome TMBack rett down DBBack ifap vontosh Oberanger att mariatrans sql; do
  auslass=;
  [ "$obkurz" ]&&case $A in sql|TMBack|DBBack|vontosh|Oberanger|att) auslass=1;; esac;
	[ -z $auslass ]&&{ bukopierfn "$Dt/$A" "$DtZ/$A/" "" "$OBDEL" || _bu_fehler=1; }
#  EXCL=${EXCL}",$A/"; # jetzt in kopiermt schon enthalten
	if [ "$A"/ = sql/ ]; then
		if [ "$obecht" ]; then
#			$zssh "if systemctl list-units --full -all|grep -q 'mariadb.service.*running';then los.sh mysqli;fi;";
      #  ... aus /etc/my.cnf das mariadb-Datenverzeichnis auslesen
      VLM=$(sed -n 's/^[[:space:]]*datadir[[:space:]]*=[[:space:]]*\(.*\)/\1/p' /etc/my.cnf)
      [ "$obforce" ]&&testdat=||testdat=ibdata1;
      # Zeitstempel für inkrementelles Backup aktualisieren (nur bei fehlerfreiem Lauf)
      if [ -z "$_bu_fehler" ]; then
        bustate_update "$ZL";
      else
        printf "${rot}Backup hatte Fehler – Zeitstempel wird nicht aktualisiert!${reset}\n";
        printf "Nächster Lauf prüft ggf. mehr Dateien.\n";
      fi;
    else
			printf "Simulation: los.sh mysqli auf $ZL falls mariadb läuft\n";
		fi;
	fi;
 done;
 EXCL=${EXCL}",TMBackloe/,DBBackloe/,sqlloe/,TMExportloe/,Thunderbird/Profiles/,TMBack0/,TMBacka/,VirtualBox/,VMs/,Documents/,mp4/";
 [ "$obkurz" ]&&EXCL=$EXCL",ausgelagert/,Oberanger/,Mail/Sylpheed,Mail/Exp/,Mail/Mail/,lost+found/,szn4vonAlterPlatte/,DBBack/,TMBack/";
 bukopierfn "$Dt" "$DtZ/" "$EXCL" "-W $OBDEL" || _bu_fehler=1;
 fi; # _bu_ob_dt2 Mail+DATA
 _bu_ob_dt2 && _bu_ftr "dt2 Ende  " $_bu_ts_dt2;
fi; # if $qssh "mountpoint -q /$Dt 2>/dev/null" && { $zssh "mountpoint -q /$DtZ 2>/dev/null" || $zssh "test -d /$DtZ 2>/dev/null"; }; then
# -----------------------------------------------------------------------
# MariaDB-Synchronisation
if _bu_ob_db && [ -z "$sdneu" ]; then
  _bu_ts_db=$(date +%s); _bu_hdr "db  Beginn";
# -----------------------------------------------------------------------
# Gleiche major.minor-Version → rsync des datadir (schnell, Minuten)
# Verschiedene Versionen      → mariadb-dump/import (sicher, langsamer)
# Kein Echtlauf (-e fehlt)    → Simulation
# -----------------------------------------------------------------------
VLM=$(sed -n 's/^[[:space:]]*datadir[[:space:]]*=[[:space:]]*\(.*\)/\1/p' /etc/my.cnf);
[ "$obforce" ] && testdat= || testdat=ibdata1;

if [ -n "$VLM" ]; then
  # Versionen ermitteln (major.minor, z.B. "10.11")
  _bu_ver_q=$(eval "$qssh \
    'mariadbd --version 2>/dev/null || mysqld --version 2>/dev/null'" 2>/dev/null \
    | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1 | cut -d. -f1,2);
  _bu_ver_z=$(mariadbd --version 2>/dev/null || mysqld --version 2>/dev/null \
    | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1 | cut -d. -f1,2);
  printf "MariaDB Quelle ${blau}%s${reset} (%s), Ziel ${blau}%s${reset} (lokal): " \
    "${_bu_ver_q:-unbekannt}" "${QL:-lokal}" "${_bu_ver_z:-unbekannt}";

  if [ -n "$_bu_ver_q" ] && [ -n "$_bu_ver_z" ] && [ "$_bu_ver_q" = "$_bu_ver_z" ]; then
    # ── Gleiche Version: schneller datadir-Sync ────────────────────────
    printf "${blau}gleich → rsync datadir${reset}\n";
    # Rotation der Sicherungskopien:
    #   ${VLM}_1 = aktuelle Kopie (wird gleich neu erstellt)
    #   ${VLM}_2 = Vorversion zur Sicherheit (bleibt erhalten)
    #   ${VLM}_3 und älter = werden gelöscht
    if [ "$obecht" ]; then
      for _i in $(seq 9 -1 3); do
        [ -d "${VLM}_${_i}" ] && {
          rm -rf "${VLM}_${_i}";
          printf "  ${blau}%s_%s${reset} gelöscht\n" "$VLM" "$_i";
        };
      done;
      [ -d "${VLM}_2" ] && {
        rm -rf "${VLM}_2";
        printf "  ${blau}%s_2${reset} gelöscht\n" "$VLM";
      };
      [ -d "${VLM}_1" ] && {
        mv "${VLM}_1" "${VLM}_2";
        printf "  ${blau}%s_1${reset} → ${blau}%s_2${reset} (Vorversion)\n" "$VLM" "$VLM";
      };
    else
      printf "Simulation: %s_3..9 löschen, %s_1 → %s_2\n" "$VLM" "$VLM" "$VLM";
    fi;
    if [ "$obecht" ]; then
      $zssh "systemctl stop mariadb";
      $zssh "systemctl disable mariadb";
      kopiermt "$VLM/" "${VLM}_1" "" "$OBDEL" $testdat 86400 1 1;
      $zssh "systemctl start mariadb";
      $zssh "systemctl enable mariadb";
    else
      printf "Simulation: systemctl stop mariadb\n";
      printf "Simulation: kopiermt %s/ %s_1 ... 1 1\n" "$VLM" "$VLM";
      printf "Simulation: systemctl start mariadb\n";
    fi;

  else
    # ── Verschiedene Versionen: mariadb-dump/import ────────────────────
    printf "${rot}verschieden → mariadb-dump${reset}\n";
    # Datenbanken auf Quelle ermitteln (ohne reine Systemdatenbanken)
    _bu_dbs=$(eval "$qssh \
      'mariadb --defaults-extra-file=/root/.mysqlrpwd -BN \
       -e \"SHOW DATABASES\" 2>/dev/null'" \
      | grep -vE '^(information_schema|performance_schema|sys|mysql)$');
    if [ -z "$_bu_dbs" ]; then
      printf "${rot}Keine Datenbanken auf Quelle gefunden – abgebrochen${reset}\n";
      _bu_fehler=1;
    else
      printf "Datenbanken: ${blau}%s${reset}\n" "$(printf '%s ' $_bu_dbs)";
      if [ "$obecht" ]; then
        _bu_wh_try=0; _bu_wh_ok=;
        while [ "$_bu_wh_try" -le "${_bu_wh_max:-0}" ]; do
          [ "$_bu_wh_try" -gt 0 ] && printf "${blau}DB-Dump Wiederholung %s/%s …${reset}\n" "$_bu_wh_try" "${_bu_wh_max}";
          set -o pipefail;
          ssh -o ServerAliveInterval=60 -o ServerAliveCountMax=10 "$QL" \
          "mariadb-dump --defaults-extra-file=/root/.mysqlrpwd \
            --default-character-set=UTF8 -c -K \
            --routines --events --triggers \
            --single-transaction --skip-lock-tables --skip-add-locks --quick \
            --ignore-table=faxeinp.tmph --ignore-table=mysql.transaction_registry --add-drop-database \
            --databases $(printf '%s ' $_bu_dbs)" \
        | awk '
            /^\/\/ \-\- Current Database:/ || /^\-\- Current Database:/ {
              db=$4; gsub(/`/,"",db);
              printf "\n  \033[34mDatenbank: %-20s\033[0m\n", db > "/dev/stderr"
            }
            /^\-\- Table structure for table/ {
              tbl=$NF; gsub(/`/,"",tbl);
              printf "    Struktur:  %-30s\r", tbl > "/dev/stderr"
            }
            /^\-\- Dumping data for table/ {
              tbl=$NF; gsub(/`/,"",tbl);
              printf "    Daten:     \033[34m%-30s\033[0m\r", tbl > "/dev/stderr"
            }
            { print }
        ' \
        | mariadb --defaults-extra-file=/root/.mysqlrpwd \
            --init-command="SET SESSION foreign_key_checks=0; SET SESSION unique_checks=0; SET SESSION sql_log_bin=0;";
          _bu_ps=("${PIPESTATUS[@]}");
          set +o pipefail;
          # Dump exit 0/2=OK, exit 3=Lost Connection (→ Retry falls -wh gesetzt)
          if { [ "${_bu_ps[0]}" = 0 ] || [ "${_bu_ps[0]}" = 2 ]; } \
               && [ "${_bu_ps[1]}" = 0 ] && [ "${_bu_ps[2]}" = 0 ]; then
            printf "${blau}Import erfolgreich${reset} (Dump=${_bu_ps[0]})\n";
            _bu_wh_ok=1; break;
          elif { [ "${_bu_ps[0]}" = 3 ] || [ "${_bu_ps[0]}" = 5 ]; } \
               && [ "$_bu_wh_try" -lt "${_bu_wh_max:-0}" ]; then
            printf "${rot}Verbindungsverlust (Dump=${_bu_ps[0]}) – warte 10s, Versuch %s/%s${reset}\n" \
              "$((_bu_wh_try+1))" "${_bu_wh_max}";
            sleep 10;
          else
            printf "${rot}Import fehlgeschlagen (Dump=${_bu_ps[0]} Awk=${_bu_ps[1]} Import=${_bu_ps[2]})${reset}\n";
            _bu_fehler=1; break;
          fi;
          _bu_wh_try=$((_bu_wh_try + 1));
        done;
        [ -z "$_bu_wh_ok" ] && [ -z "$_bu_fehler" ] && _bu_fehler=1;
        # ── Abschlussmeldung Datenbankvergleich ──────────────────────────
        printf "\n${blau}── Datenbankabgleich Abschluss ────────────────${reset}\n";
        printf "  Dump: %b  Awk: %b  Import: %b\n" \
          "$([ "${_bu_ps[0]}" = 0 ] && printf "${blau}OK${reset}" || printf "${rot}FEHLER${reset}")" \
          "$([ "${_bu_ps[1]}" = 0 ] && printf "${blau}OK${reset}" || printf "${rot}FEHLER${reset}")" \
          "$([ "${_bu_ps[2]}" = 0 ] && printf "${blau}OK${reset}" || printf "${rot}FEHLER${reset}")";
        for _db in $_bu_dbs; do
          case $_db in information_schema|performance_schema|sys|mysql) continue;; esac;
          _tabs_z=$(mariadb --defaults-extra-file=/root/.mysqlrpwd -BN \
            -e "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='$_db' AND table_type='BASE TABLE';" 2>/dev/null);
          if [ -n "$QL" ]; then
            _tabs_q=$(ssh "$QL" "mariadb --defaults-extra-file=/root/.mysqlrpwd -BN \
              -e 'SELECT COUNT(*) FROM information_schema.tables WHERE table_schema=\"$_db\" AND table_type=\"BASE TABLE\";'" 2>/dev/null);
          else
            _tabs_q=;
          fi;
          _col=$(mariadb --defaults-extra-file=/root/.mysqlrpwd -BN \
            -e "SELECT CONCAT(table_name,'.',column_name) FROM information_schema.columns WHERE table_schema='$_db' AND column_name REGEXP 'zeit|time|datum' ORDER BY table_name,ordinal_position LIMIT 1;" 2>/dev/null);
          if [ -n "$_col" ]; then
            _tbl=${_col%%.*}; _feld=${_col##*.};
            _ts_z=$(mariadb --defaults-extra-file=/root/.mysqlrpwd -BN \
              -e "SELECT MAX(\`$_feld\`) FROM \`$_db\`.\`$_tbl\`;" 2>/dev/null);
            if [ -n "$QL" ]; then
              _ts_q=$(ssh "$QL" "mariadb --defaults-extra-file=/root/.mysqlrpwd -BN \
                -e 'SELECT MAX(\`$_feld\`) FROM \`$_db\`.\`$_tbl\`;'" 2>/dev/null);
            else
              _ts_q=;
            fi;
            printf "  %-16s Tab Z/Q: %s/%s  MAX(%-12s) Z: %-20s Q: %s\n" \
              "$_db" "${_tabs_z:--}" "${_tabs_q:--}" "$_feld" "${_ts_z:--}" "${_ts_q:--}";
          else
            printf "  %-16s Tab Z/Q: %s/%s\n" "$_db" "${_tabs_z:--}" "${_tabs_q:--}";
          fi;
        done;
        printf "${blau}────────────────────────────────────────────────────────${reset}\n";
      else
        printf "Simulation: ssh %s mariadb-dump ... %s | mariadb --init-command=...\n" \
          "$QL" "$(printf '%s ' $_bu_dbs)";
      fi;
    fi;
  fi;
fi;
  _bu_ftr "db  Ende  " $_bu_ts_db;
fi; # MariaDB-Block
#  ... und kopieren:
_bu_ftr "Gesamt Ende" $_bu_start;
exit; # Ende





# kopieretc "samba" # auskommentiert 29.7.19
# kopieretc "hosts" # hier muesste noch eine Zeile geaendert werden!
# kopieretc "vsftpd.conf" # auskommentiert 29.7.19
# kopieretc "my.cnf" # auskommentiert 29.7.19
# kopieretc "fstab.cnf" # auskommentiert 29.7.19
kopiermt "gerade" "/" "" "$OBDEL"
kopiermt "ungera" "/" "" "$OBDEL"
# VLM="var/lib/mysql";
VLM=$(sed -n 's/^[[:space:]]*datadir[[:space:]]*=[[:space:]]*\(.*\)/\1/p' /etc/my.cnf)
[ "$obforce" ]&&testdat=||testdat=ibdata1;
kopiermt "$VLM/" "${VLM}_1" "" "$OBDEL" $testdat 86400;
# kopieretc "openvpn" # auskommentiert 29.7.19
scp $PROT $ANDERER:/var/log/
if mountpoint -q /$Dt && ssh $ANDERER mountpoint -q /$Dt 2>/dev/null; then
 scp $PROT $ANDERER:/$Dt/
fi;
if [ "$buhost"/ != "$LINEINS"/ ]; then
	NES=~/neuserver;
	echo Rufe los.sh auf;
	LOS=los.sh;
	if test -d $NES -a -f $NES/$LOS; then
		echo Rufe mysqlneu auf;
		cd $NES;
		sh $LOS mysqlneu -v;
		cd -;
		echo Fertig mit mysqlneu;
	fi;
	echo Fertig mit los.sh;
fi;
echo `date +%Y:%m:%d\ %T` "nach Kopieren" >> $PROT
echo Fertig;
# exit
# echo `date +%Y:%m:%d\ %T` "vor /etc/hosts" >> $PROT
# rsync $QL:/etc/samba $QL:/etc/hosts $QL:/etc/vsftpd*.conf $QL:/etc/my.cnf $QL:/etc/fstab $ZL/etc/ -avuz # keine Anführungszeichen um den Stern!
gutenacht;
[ "$verb" ]&&printf "\n${rot} ziemlich am Schluss von $MUPR$reset\n";
