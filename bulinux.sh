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
# Ziel-Reset nur ohne -u (mit -u wird ZL als Quelle nach dem Tausch gebraucht):
[ -z "$obumg" ] && [ "$buhost"/ != "$LINEINS"/ -a "$ZL" ]&&{ printf "Ziel \"$blau$ZL$reset\" wird zurückgesetzt.\n"; ZL=;ZmD=;}
# -u: Richtung umkehren – QL und ZL tauschen
if [ "$obumg" ]; then
  _tmp_ql="$QL"; QL="${ZL}"; ZL="$_tmp_ql"; unset _tmp_ql;
  # QmD/ZmD wurden vor dem Tausch gesetzt – jetzt nachführen:
  QmD=$QL:; QmD=${QmD#:};
  ZmD=$ZL:; ZmD=${ZmD#:};
  # DtZ neu berechnen: basiert auf Zielrechner (ZL) statt buhost
  _zielh="${ZL:-$buhost}";
  case "$_zielh" in *3|*7|*8) DATAZIEL=DATA/DATA;; *) DATAZIEL=DATA;; esac;
  DtZ=$DATAZIEL;
fi;
# Abort-Check: ohne -u braucht linux1 ein ZL; mit -u braucht es ein QL
[ -z "$obumg" ] && [ "$buhost"/ = "$LINEINS"/ -a -z "$ZL" ] && [ -z "$obhilfe" ] && { printf "${rot}Kein Ziel angegeben. Breche ab$reset.\n";exit;}
[ "$obumg" ] && [ -z "$QL" ] && [ -z "$obhilfe" ] && { printf "${rot}Mit -u: Quellrechner fehlt (z.B. bulinux.sh -u -e linux0)$reset.\n";exit;}
# kopiermt "opt/turbomed" ... "" "$OBDEL" PraxisDB/objects.dat 1800
# -----------------------------------------------------------------------
# Inkrementeller Modus (Standard) vs. Vollabgleich:
#   Sonntags (Wochentag 7) oder mit -f (force) → kopiermt (vollständig)
#   Alle anderen Tage                           → kopiermt_delta (nur Änderungen)
# Manueller Vollabgleich: bulinux.sh -e -f
# [ "$(date +%u)" = 7 ] && _bu_vollabgleich=1 || \
   _bu_vollabgleich=;
[ "$obforce" ] && _bu_vollabgleich=1;
# ── Skript-Versionen (Beginn jedes Laufs) ───────────────────────────
printf "Skript-Änderungsdaten: ";
for _f in "$MUPR" "${MUPR%/*}/bugem.sh"; do
  [ -f "$_f" ] || continue;
  _vts=$(stat -c "%y" "$_f" 2>/dev/null | cut -d. -f1);
  printf "%s:%s  " "$(basename $_f)" "${_vts:-?}";
done;
printf "\n";
if [ "$sdneu" ]; then
  printf "${blau}Schutzdatei-Verteilung${reset}: ${blau}%s${reset}\n" "$SD";
elif [ "$obumg" ]; then
  printf "${blau}Umgekehrt${reset} (-u): ${blau}%s${reset} → ${blau}%s${reset}" "${QL:-lokal}" "${ZL:-lokal}";
  [ "$_bu_vollabgleich" ] && printf " (Vollabgleich)" || printf " (delta)";
  printf "\n";
elif [ "$_bu_vollabgleich" ]; then
  printf "${blau}Vollabgleich${reset} (-f)\n";
elif [ "$obdberg" ]; then
  printf "${blau}Datenbankvergleich${reset} (-dberg)\n";
elif [ "$obdb" ] && [ -z "$obdt" ] && [ -z "$obdt1" ] && [ -z "$obdt2" ]; then
  printf "${blau}Nur Datenbank${reset} (-db)\n";
elif [ "$obdt1" ] && [ -z "$obdt2" ] && [ -z "$obdt3" ] && [ -z "$obdb" ]; then
  printf "${blau}Nur Konfigdateien${reset} (-dt1)\n";
elif [ "$obdt2" ] && [ -z "$obdt1" ] && [ -z "$obdt3" ] && [ -z "$obdb" ]; then
  printf "${blau}Nur Windows-Shares${reset} (-dt2)\n";
elif [ "$obdt3" ] && [ -z "$obdt1" ] && [ -z "$obdt2" ] && [ -z "$obdb" ]; then
  printf "${blau}Nur /DATA${reset} (-dt3)\n";
else
  printf "${blau}Inkrementeller Abgleich${reset} (delta";
  [ "$obdt1" ] && printf ", dt1";
  [ "$obdt2" ] && printf ", dt2";
  [ "$obdt3" ] && printf ", dt3";
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
# dt1-Block: Konfigdateien
_bu_ob_dt1() { [ -z "$obdberg" ] && { [ -n "$obdt1" ] || { [ -z "$obdb" ] && [ -z "$obdt2" ] && [ -z "$obdt3" ]; }; }; }
# dt2-Block: Windows-Shares (/mnt/wser, /mnt/anmmw)
_bu_ob_dt2() { [ -z "$obdberg" ] && { [ -n "$obdt2" ] || { [ -z "$obdb" ] && [ -z "$obdt1" ] && [ -z "$obdt3" ]; }; }; }
# dt3-Block: /DATA-Verzeichnisse
_bu_ob_dt3() { [ -z "$obdberg" ] && { [ -n "$obdt3" ] || { [ -z "$obdb" ] && [ -z "$obdt1" ] && [ -z "$obdt2" ]; }; }; }
_bu_ob_db()  { [ -n "$obdb"  ] || { [ -z "$obdt" ] && [ -z "$obdt1" ] && [ -z "$obdt2" ] && [ -z "$obdt3" ]; }; }
if _bu_ob_dt1; then  # dt1: Konfigdateien
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
kopieros ".wser"
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
	_bu_ob_dt1 && _bu_ftr "dt1 Ende  " $_bu_ts_dt1;
	_bu_ob_dt2 && { _bu_ts_dt2=$(date +%s); _bu_hdr "dt2 Beginn"; };
	_bu_ob_dt2 && {
	  # dt2: Windows-Shares (/mnt/wser, /mnt/anmmw)
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
	}; # Ende dt2 Windows-Shares
	_bu_ob_dt2 && _bu_ftr "dt2 Ende  " $_bu_ts_dt2;
	_bu_ob_dt3 && { _bu_ts_dt3=$(date +%s); _bu_hdr "dt3 Beginn"; };
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

 if _bu_ob_dt3; then
# Schreibschutz-Zustand merken und +i aufheben:
# ── chattr: +i-Zustand merken und aufheben ──────────────────────────────
 _bu_chattr_dirs=;
 if [ "$obecht" ]; then
   _bu_chattr_tmp=$(mktemp);
   $zssh "find /$DtZ -mindepth 1 -maxdepth 1 -type d 2>/dev/null" > "$_bu_chattr_tmp";
   while IFS= read -r _d; do
     [ -z "$_d" ] && continue;
     if $zssh "lsattr -d \"$_d\" 2>/dev/null" | grep -q '^....i'; then
       _bu_chattr_dirs="${_bu_chattr_dirs:+${_bu_chattr_dirs}
}$_d";
     fi;
   done < "$_bu_chattr_tmp";
   rm -f "$_bu_chattr_tmp";
   if [ "$_bu_chattr_dirs" ]; then
     printf "${blau}chattr -i${reset} (war gesetzt, wird nach dt3 wiederhergestellt):\n";
     while IFS= read -r _d; do
       [ -z "$_d" ] && continue;
       $zssh "chattr -i \"$_d\"" && printf "  -i: ${blau}%s${reset}\n" "$_d";
     done <<< "$_bu_chattr_dirs";
   else
     printf "${blau}Keine +i-Verzeichnisse unter /$DtZ${reset}\n";
   fi;
 else
   printf "Simulation: chattr-Zustand unter /$DtZ prüfen und ggf. -i setzen\n";
 fi;
 # ── Ende chattr -i ─────────────────────────────────────────────────────── 
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
       # bustate_update: am dt3-Ende (nach finalem Sweep) – nicht hier im sql-Zweig
    else
			printf "Simulation: los.sh mysqli auf $ZL falls mariadb läuft\n";
		fi;
	fi;
 done;
#  ... dann Mail-Verzeichisse kopieren,
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
 # Zeitstempel nach vollständigem dt3-Lauf aktualisieren (gilt für -e und -f)
 if [ "$obecht" ] && [ -z "$_bu_fehler" ]; then
   bustate_update "$ZL";
 elif [ "$obecht" ]; then
   printf "${rot}dt3 hatte Fehler – Zeitstempel nicht aktualisiert!${reset}\n";
   printf "Nächster Lauf prüft ggf. mehr Dateien.\n";
 fi;
 EXCL=${EXCL}",TMBackloe/,DBBackloe/,sqlloe/,TMExportloe/,Thunderbird/Profiles/,TMBack0/,TMBacka/,VirtualBox/,VMs/,Documents/,mp4/";
 [ "$obkurz" ]&&EXCL=$EXCL",ausgelagert/,Oberanger/,Mail/Sylpheed,Mail/Exp/,Mail/Mail/,lost+found/,szn4vonAlterPlatte/,DBBack/,TMBack/";
 bukopierfn "$Dt" "$DtZ/" "$EXCL" "-W $OBDEL" || _bu_fehler=1;
 # Schreibschutz auf Zielverzeichnisse aufheben:
 # ── chattr: +i wiederherstellen wo es vorher gesetzt war ─────────────────
 if [ "$obecht" ]; then
   if [ "$_bu_chattr_dirs" ]; then
     printf "${blau}chattr +i${reset} wiederherstellen:\n";
     while IFS= read -r _d; do
       [ -z "$_d" ] && continue;
       $zssh "chattr +i \"$_d\"" && printf "  +i: ${blau}%s${reset}\n" "$_d";
     done <<< "$_bu_chattr_dirs";
   fi;
 else
   printf "Simulation: chattr +i ggf. wiederherstellen\n";
 fi;
 # ── Ende chattr +i ───────────────────────────────────────────────────────
 fi; # _bu_ob_dt3 Mail+DATA
 _bu_ob_dt3 && _bu_ftr "dt3 Ende  " $_bu_ts_dt3;
fi; # if $qssh "mountpoint -q /$Dt 2>/dev/null" && { $zssh "mountpoint -q /$DtZ 2>/dev/null" || $zssh "test -d /$DtZ 2>/dev/null"; }; then
# -----------------------------------------------------------------------
# MariaDB-Synchronisation
# ═══════════════════════════════════════════════════════════════════════
# Funktion: DB-Ergebnisvergleich (auch standalone mit -dberg aufrufbar)
# Setzt voraus: $_bu_dbs, $QL, $blau, $rot, $reset
# ═══════════════════════════════════════════════════════════════════════
bu_db_erg() {
  printf "\n${blau}── Datenbankabgleich Abschluss ────────────────${reset}\n";
  [ -n "${_bu_ps[*]}" ] && \
    printf "  Dump: %b  Awk: %b  Import: %b\n" \
      "$([ "${_bu_ps[0]}" = 0 ] && printf "${blau}OK${reset}" || printf "${rot}FEHLER${reset}")" \
      "$([ "${_bu_ps[1]}" = 0 ] && printf "${blau}OK${reset}" || printf "${rot}FEHLER${reset}")" \
      "$([ "${_bu_ps[2]}" = 0 ] && printf "${blau}OK${reset}" || printf "${rot}FEHLER${reset}")";
  # Datenbanken ermitteln falls nicht gesetzt (Standalone-Modus)
  if [ -z "$_bu_dbs" ]; then
    _bu_dbs=$(eval "$qssh \
      'mariadb --defaults-extra-file=/root/.mysqlrpwd -BN \
       -e \"SHOW DATABASES\" 2>/dev/null'" \
      | grep -vE '^(information_schema|performance_schema|sys|mysql)$');
  fi;
  # Richtung: ZL gesetzt → lokal=Quelle, ssh ZL=Ziel; QL gesetzt → lokal=Ziel, ssh QL=Quelle
  # Quoting: \"$1\" damit SQL mit einfachen Anführungszeichen korrekt übertragen wird
  _bu_erg_sql_z() {
    if [ -n "$ZL" ]; then
      ssh "$ZL" "mariadb --defaults-extra-file=/root/.mysqlrpwd -BN -e \"$1\"" 2>/dev/null;
    else
      mariadb --defaults-extra-file=/root/.mysqlrpwd -BN -e "$1" 2>/dev/null;
    fi;
  }
  _bu_erg_sql_q() {
    if [ -n "$QL" ]; then
      ssh "$QL" "mariadb --defaults-extra-file=/root/.mysqlrpwd -BN -e \"$1\"" 2>/dev/null;
    elif [ -n "$ZL" ]; then
      mariadb --defaults-extra-file=/root/.mysqlrpwd -BN -e "$1" 2>/dev/null;
    fi;
  }
  # Kopfzeile: $blau/$reset in Formatstring, nicht als %s-Argument
  printf "  ${blau}%-16s | %-7s | %-8s | %-10s | %-10s | %-12s | %-20s | %s${reset}\n" \
    "Datenbank" "Tab Z" "Tab Q" "~Zeilen Z" "~Zeilen Q" "Zeitfeld" "MAX Ziel" "MAX Quelle";
  printf '  '; printf '─%.0s' {1..110}; printf '\n';
  for _db in $_bu_dbs; do
    case $_db in information_schema|performance_schema|sys|mysql) continue;; esac;
    _sql_tabs="SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='$_db' AND table_type='BASE TABLE';"
    _tabs_z=$(_bu_erg_sql_z "$_sql_tabs");
    _tabs_q=$(_bu_erg_sql_q "$_sql_tabs");
    _sql_rows="SELECT COALESCE(SUM(table_rows),0) FROM information_schema.tables WHERE table_schema='$_db' AND table_type='BASE TABLE';"
    _rows_z=$(_bu_erg_sql_z "$_sql_rows");
    _rows_q=$(_bu_erg_sql_q "$_sql_rows");
    # Zeitfeld: erstes Feld mit aktuellem MAX auf Quell-Seite (Q); Z-Seite immer anzeigen
    _col=; _ts_z=; _ts_q=;
    while IFS='.' read -r _tbl _feld; do
      [ -z "$_tbl" ] && continue;
      _sql_ts="SELECT CASE WHEN MAX($_feld) IS NOT NULL AND MAX($_feld) >= DATE_SUB(NOW(),INTERVAL 4 WEEK) THEN MAX($_feld) END FROM $_db.$_tbl;"
      _ts_q=$(_bu_erg_sql_q "$_sql_ts");
      # Nur Q muss aktuell sein (Quelle = autoritativer Stand)
      { [ -z "$_ts_q" ] || [ "$_ts_q" = "NULL" ]; } && continue;
      # Z immer anzeigen (kann älter sein – das ist der Vergleich)
      _ts_z=$(_bu_erg_sql_z "$_sql_ts");
      [ "$_ts_z" = "NULL" ] && _ts_z="(älter 4W)";
      [ -z "$_ts_z" ] && _ts_z="-";
      _col="$_tbl.$_feld"; break;
    done < <(_bu_erg_sql_q \
      "SELECT CONCAT(c.table_name,'.',c.column_name) FROM information_schema.columns c JOIN information_schema.tables t USING(TABLE_CATALOG,TABLE_SCHEMA,TABLE_NAME) WHERE c.table_schema='$_db' /* AND c.column_name REGEXP 'zeit|time|datum|^tag$|' */ AND t.table_type='BASE TABLE'AND c.data_type IN ('datetime','timestamp','date') ORDER BY c.table_name, c.ordinal_position;");
    if [ -n "$_col" ]; then
      printf "  %-16s | %-7s | %-8s | %-10s | %-10s | ${blau}%-12s${reset} | %-20s | %s\n" \
        "$_db" "${_tabs_z:--}" "${_tabs_q:--}" \
        "${_rows_z:--}" "${_rows_q:--}" \
        "$_col" "${_ts_z:--}" "${_ts_q:--}";
    else
      printf "  %-16s | %-7s | %-8s | %-10s | %-10s\n" \
        "$_db" "${_tabs_z:--}" "${_tabs_q:--}" "${_rows_z:--}" "${_rows_q:--}";
    fi;
  done;
  printf '  '; printf '─%.0s' {1..110}; printf '\n';
} # bu_db_erg

# Standalone-Aufruf via -dberg
[ "$obdberg" ] && { machssh; _bu_dbs=; bu_db_erg; exit 0; }

# ═══════════════════════════════════════════════════════════════════════
# MariaDB-Synchronisation
# ═══════════════════════════════════════════════════════════════════════
if _bu_ob_db && [ -z "$sdneu" ]; then
  # ── Versionen der Skript-Dateien (am Anfang sichtbar) ────────────
  printf "Skript-Änderungsdaten: ";
  for _f in "$MUPR" "${MUPR%/*}/bugem.sh"; do
    [ -f "$_f" ] || continue;
    _vts=$(stat -c "%y" "$_f" 2>/dev/null | cut -d. -f1);
    printf "%s:%s  " "$(basename $_f)" "${_vts:-?}";
  done;
  printf "\n";
  _bu_ts_db=$(date +%s); _bu_hdr "db  Beginn";
  # ── Lock AUF linux1 (Quellrechner): verhindert parallele DB-Exporte
  # von beliebigen Rechnern – Lock via $qssh = lokal oder ssh linux1
  _bu_lockfile="/tmp/bulinux_db_${LINEINS}.lock";
  _bu_lock_info_str="${USER:-root}@${HOSTNAME:-$(hostname)} pid=$$ $(date +'%Y-%m-%d %H:%M:%S')";
  # Atomic: set -C (noclobber) schlägt fehl wenn Datei schon existiert
  if ! eval "$qssh '( set -C; printf "%s" "$_bu_lock_info_str" > "$_bu_lockfile" ) 2>/dev/null'"; then
    _bu_lock_info=$(eval "$qssh 'cat "$_bu_lockfile" 2>/dev/null'");
    printf "${rot}DB-Export läuft bereits auf %s${reset} (Lock: ${blau}%s${reset})\n" \
      "${QL:-lokal}" "$_bu_lockfile";
    printf "Gestartet von: ${blau}%s${reset}\n" "$_bu_lock_info";
    printf "${rot}DB-Abschnitt übersprungen.${reset} Lock manuell löschen: ${blau}%s rm %s${reset}\n" \
      "${QL:+ssh $QL}" "$_bu_lockfile";
    _bu_fehler=1;
  else
    # Lock erhalten – Cleanup-Funktion für trap und normales Ende
    _bu_db_unlock() { eval "$qssh 'rm -f \"$_bu_lockfile\" 2>/dev/null'" 2>/dev/null||true; };
    trap '_bu_db_unlock' EXIT INT TERM;
VLM=$(sed -n 's/^[[:space:]]*datadir[[:space:]]*=[[:space:]]*\(.*\)/\1/p' /etc/my.cnf);
[ "$obforce" ] && testdat= || testdat=ibdata1;

if [ -n "$VLM" ]; then
  # Versionen ermitteln (major.minor)
  _bu_ver_q=$(eval "$qssh \
    '{ mariadbd --version 2>/dev/null || mysqld --version 2>/dev/null; }'" 2>/dev/null \
    | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1 | cut -d. -f1,2);
  if [ -n "$ZL" ]; then
    _bu_ver_z=$(ssh "$ZL" "{ mariadbd --version 2>/dev/null || mysqld --version 2>/dev/null; }" 2>/dev/null \
      | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1 | cut -d. -f1,2);
  else
    _bu_ver_z=$({ mariadbd --version 2>/dev/null || mysqld --version 2>/dev/null; } \
      | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1 | cut -d. -f1,2);
  fi;
  printf "MariaDB Quelle ${blau}%s${reset} (%s), Ziel ${blau}%s${reset} (%s): " \
    "${_bu_ver_q:-unbekannt}" "${QL:-lokal}" "${_bu_ver_z:-unbekannt}" "${ZL:-lokal}";

  if [ -n "$_bu_ver_q" ] && [ -n "$_bu_ver_z" ] && [ "$_bu_ver_q" = "$_bu_ver_z" ]; then
    # ── Gleiche Version: schneller datadir-Sync ────────────────────────
    printf "${blau}gleich → rsync datadir${reset}\n";
    if [ "$obecht" ]; then
      for _i in $(seq 9 -1 3); do
        [ -d "${VLM}_${_i}" ] && { rm -rf "${VLM}_${_i}"; printf "  ${blau}%s_%s${reset} gelöscht\n" "$VLM" "$_i"; };
      done;
      [ -d "${VLM}_2" ] && { rm -rf "${VLM}_2"; printf "  ${blau}%s_2${reset} gelöscht\n" "$VLM"; };
      [ -d "${VLM}_1" ] && { mv "${VLM}_1" "${VLM}_2"; printf "  ${blau}%s_1 → %s_2${reset} (Vorversion)\n" "$VLM" "$VLM"; };
      $zssh "systemctl stop mariadb"; $zssh "systemctl disable mariadb";
      if [ "$obumg" ]; then
        # -u: direkt in Datadir kopieren (nicht in _1), Rotation überspringen
        printf "${blau}Kopiere Datadir direkt nach %s (wegen -u)${reset}\n" "$VLM";
        kopiermt "$VLM/" "$VLM" "" "$OBDEL" $testdat 86400 1 1;
      else
        kopiermt "$VLM/" "${VLM}_1" "" "$OBDEL" $testdat 86400 1 1;
      fi;
      # my.cnf und Eigentümer sicherstellen bevor Start:
      $zssh "[ -f /etc/my.cnf ] || { cp ${INSTVZ:-/root/neuserver}/my.cnf /etc/my.cnf 2>/dev/null; restorecon /etc/my.cnf 2>/dev/null; }";
      $zssh "chown -R mysql:mysql $VLM 2>/dev/null; restorecon -Rv $VLM 2>/dev/null||true";
      $zssh "systemctl start mariadb"; $zssh "systemctl enable mariadb";
    else
      printf "Simulation: %s_3..9 löschen, %s_1 → %s_2\n" "$VLM" "$VLM" "$VLM";
      printf "Simulation: systemctl stop/start mariadb, kopiermt %s/ %s_1\n" "$VLM" "$VLM";
    fi;

  else
    # ── Verschiedene Versionen: mariadb-dump/import ────────────────────
    printf "${rot}verschieden → mariadb-dump${reset}\n";
    _bu_dbs=$(eval "$qssh \
      'mariadb --defaults-extra-file=/root/.mysqlrpwd -BN \
       -e \"SHOW DATABASES\" 2>/dev/null'" \
      | grep -vE '^(information_schema|performance_schema|sys|mysql)$');
    if [ -z "$_bu_dbs" ]; then
      printf "${rot}Keine Datenbanken auf Quelle gefunden – abgebrochen${reset}\n"; _bu_fehler=1;
    else
      printf "Datenbanken: ${blau}%s${reset}\n" "$(printf '%s ' $_bu_dbs)";
      # ── Parameter für mariadb-dump (nur einmal definiert) ────────────
      _bu_dump_args="--defaults-extra-file=/root/.mysqlrpwd \
        --default-character-set=utf8mb4 -c -K \
        --routines --events --triggers \
        --single-transaction --skip-lock-tables --skip-add-locks --quick \
        --ignore-table=faxeinp.tmph --ignore-table=mysql.transaction_registry \
        --add-drop-table";
      # ── awk-Filter (Fortschritt + DEFINER-Bereinigung) ───────────────
      _bu_awk_filter='
        /^\/\/ \-\- Current Database:/ || /^\-\- Current Database:/ {
          db=$4; gsub(/`/,"",db);
          if (!(db in seen)) {
            printf "\n  \033[34mDatenbank: %-20s\033[0m\n", db > "/dev/stderr";
            seen[db] = 1;
          }
        }
        /^\-\- Table structure for table/ {
          tbl=$NF; gsub(/`/,"",tbl);
          printf "    Struktur:  %-30s\r", tbl > "/dev/stderr"
        }
        /^\-\- Dumping data for table/ {
          tbl=$NF; gsub(/`/,"",tbl);
          printf "    Daten:     \033[34m%-30s\033[0m\r", tbl > "/dev/stderr"
        }
        { gsub(/ DEFINER=`[^`]*`@`[^`]*`/, ""); gsub(/ SQL SECURITY DEFINER/, ""); print }
      ';
      # ── mariadb Import-Funktion – ZL=remote oder lokal ──────────────────
      _bu_mariadb_import() {
        if [ -n "$ZL" ]; then
          ssh "$ZL" "mariadb --defaults-extra-file=/root/.mysqlrpwd --force \
            --init-command='SET SESSION foreign_key_checks=0; SET SESSION unique_checks=0; SET SESSION sql_log_bin=0;'";
        else
          mariadb --defaults-extra-file=/root/.mysqlrpwd --force \
            --init-command="SET SESSION foreign_key_checks=0; SET SESSION unique_checks=0; SET SESSION sql_log_bin=0;";
        fi;
      }
      if [ "$obecht" ]; then
        # Timeouts auf Quell-Server erhöhen (gilt für alle folgenden Dump-Verbindungen)
        eval "$qssh 'mariadb --defaults-extra-file=/root/.mysqlrpwd \
          -e \"SET GLOBAL net_write_timeout=3600; SET GLOBAL net_read_timeout=3600;\"'"
        [ -z "$_bu_wh_max" ] && _bu_wh_max=5;
        _bu_wh_try=0; _bu_wh_ok=; _bu_wh_anzahl=0;
        while [ "$_bu_wh_try" -le "$_bu_wh_max" ]; do
          [ "$_bu_wh_try" -gt 0 ] && printf "${blau}DB-Dump Wiederholung %s/%s …${reset}\n" "$_bu_wh_try" "$_bu_wh_max";
          set -o pipefail;
          if [ -n "$ZL" ]; then
            # Von linux1 (lokal) nach linux7 (remote): lokal dumpen, remote importieren
            mariadb-dump $_bu_dump_args \
              --databases $(printf '%s ' $_bu_dbs) \
              2> >(grep -v "^$\|Warning\|warning" >&2) \
            | awk "$_bu_awk_filter" \
            | _bu_mariadb_import;
          else
            # Von linux0/linux7 (lokal) nach linux1 (Quelle via SSH): remote dumpen, lokal importieren
            ssh -o ServerAliveInterval=60 -o ServerAliveCountMax=10 "$QL" \
              "mariadb-dump $_bu_dump_args --databases $(printf '%s ' $_bu_dbs)" \
            | awk "$_bu_awk_filter" \
            | _bu_mariadb_import;
          fi;
          _bu_ps=("${PIPESTATUS[@]}"); set +o pipefail;
          if { [ "${_bu_ps[0]}" = 0 ] || [ "${_bu_ps[0]}" = 2 ]; } \
               && [ "${_bu_ps[1]}" = 0 ] && [ "${_bu_ps[2]}" = 0 ]; then
            printf "${blau}Import erfolgreich${reset} (Dump=${_bu_ps[0]})\n";
            _bu_wh_ok=1; break;
          elif { [ "${_bu_ps[0]}" = 3 ] || [ "${_bu_ps[0]}" = 5 ]; } \
               && [ "$_bu_wh_try" -lt "$_bu_wh_max" ]; then
            printf "${rot}Verbindungsverlust (Dump=${_bu_ps[0]}) – warte 10s, Versuch %s/%s${reset}\n" \
              "$((_bu_wh_try+1))" "$_bu_wh_max";
            sleep 10; _bu_wh_anzahl=$((_bu_wh_anzahl+1));
          else
            printf "${rot}Import fehlgeschlagen (Dump=${_bu_ps[0]} Awk=${_bu_ps[1]} Import=${_bu_ps[2]})${reset}\n";
            _bu_fehler=1; break;
          fi;
          _bu_wh_try=$((_bu_wh_try+1));
        done;
        [ "$_bu_wh_anzahl" -gt 0 ] && \
          printf "${blau}DB-Dump: %s Wiederholung(en) nötig${reset}\n" "$_bu_wh_anzahl";
        # ── Fallback: Dump-Datei auf Quelle ─────────────────────────────
        if [ -z "$_bu_wh_ok" ]; then
          _bu_sqldump_dir="${VLM%/*}/bu_sqldump";
          _bu_sqldump_f="$_bu_sqldump_dir/dump_$(date +%Y%m%d_%H%M%S).sql";
          printf "${rot}Pipe-Import fehlgeschlagen – Fallback: Dump-Datei${reset}\n";
          printf "  Schreibe Dump nach ${blau}%s${reset} auf %s …\n" "$_bu_sqldump_f" "${QL:-lokal}";
          if [ -n "$ZL" ]; then
            mkdir -p "$_bu_sqldump_dir" && \
              mariadb-dump $_bu_dump_args \
                --databases $(printf "%s " $_bu_dbs) > "$_bu_sqldump_f";
          else
            eval "$qssh 'mkdir -p \"$_bu_sqldump_dir\" && \
              mariadb-dump $_bu_dump_args \
              --databases $(printf "%s " $_bu_dbs) > \"$_bu_sqldump_f\"'";
          fi;
          if [ $? -eq 0 ]; then
            printf "  Importiere von ${blau}%s${reset} …\n" "$_bu_sqldump_f";
            eval "$qssh 'cat \"$_bu_sqldump_f\"'" \
            | sed 's/ DEFINER=`[^`]*`@`[^`]*`//g; s/ SQL SECURITY DEFINER//g' \
            | _bu_mariadb_import \
            && { printf "${blau}Fallback-Import erfolgreich${reset}\n";
                 _bu_wh_ok=1; _bu_fehler=;
                 eval "$qssh 'rm -f \"$_bu_sqldump_f\"'"; } \
            || { printf "${rot}Fallback-Import fehlgeschlagen${reset}\n"; _bu_fehler=1; };
          else
            printf "${rot}Dump-Datei konnte nicht erstellt werden${reset}\n"; _bu_fehler=1;
          fi;
        fi;
        [ -z "$_bu_wh_ok" ] && [ -z "$_bu_fehler" ] && _bu_fehler=1;
        bu_db_erg;
      else
        printf "Simulation: ssh %s mariadb-dump [args] %s | awk [filter] | mariadb [args]\n" \
          "$QL" "$(printf '%s ' $_bu_dbs)";
      fi;
    fi;
  fi;
fi;
  _bu_ftr "db  Ende  " $_bu_ts_db;
    _bu_db_unlock;  # Lock auf Quellrechner freigeben
  fi; # else: Lock erhalten und DB-Block ausgeführt
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
