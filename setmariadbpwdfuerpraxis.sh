#!/bin/bash
# setmariadbpwdfuerpraxis.sh [-e] <neues-passwort>
#
# Aendert das Passwort des gemeinsam genutzten MariaDB-Benutzers 'praxis' an allen
# bekannten Stellen:
#   1) /root/dbverbfreigabe/dbverb.cfg    (zentrale Freigabe fuer DBVerb.frm-Programme,
#                                           s. Dateilese.exe, FotosBenennen.exe, HAFax.exe, ...)
#   2) /root/.mysqlpwd, /root/.mariadbpwd (--defaults-extra-file fuer Backup-/Verwaltungsskripte)
#   3) MariaDB-Server selbst: 'praxis'@'%' (fern) und 'praxis'@'localhost' (lokal)
#   4) die mpwd-Konfiguration der 9 C++-Programme (anrliste, auffaell, autofax, dicom,
#      impgl, labimp, labpath, pznbdt, termine) ueber deren eigene -cmpwd-Option --
#      dabei wird NUR die Konfiguration aktualisiert, keine weitere Programmlogik ausgefuehrt.
#      fbfax braucht keinen Datenbankzugriff und wird ausgelassen.
#
# Ohne -e: Simulation (zeigt nur, was getan wuerde). Mit -e: echter Lauf.
#
# Voraussetzung: die lokal gebauten Testbinaries unter /root/<programm>/<programm>
# unterstuetzen -cmpwd bereits (s. Commit vom 09.07.2026). Falls diese durch neuere
# Quellstaende ersetzt werden, vorher "make <programm>" im jeweiligen Verzeichnis pruefen.

set -euo pipefail

rot="\e[1;31m"; gruen="\e[0;32m"; blau="\e[1;34m"; schwarz="\e[0m"

obecht=
if [ "${1:-}" = "-e" ]; then obecht=1; shift; fi

NEUPWD="${1:-}"
if [ -z "$NEUPWD" ]; then
	printf "${rot}Aufruf: $0 [-e] <neues-passwort>${schwarz}\n" >&2
	printf "  ohne -e: Simulation (zeigt nur, was getan wuerde)\n" >&2
	printf "  mit -e:  echter Lauf\n" >&2
	exit 1
fi

CPPROGS="anrliste auffaell autofax dicom impgl labimp labpath pznbdt termine"

ausf() {
	# $1 = Beschreibung, $2.. = Befehl (als Array-Elemente)
	local beschr="$1"; shift
	if [ "$obecht" ]; then
		printf "${blau}%s${schwarz}\n" "$beschr"
		"$@"
	else
		printf "Waere: ${blau}%s${schwarz} (%s)\n" "$beschr" "$*"
	fi
}

printf "${gruen}== 1) dbverb.cfg ==${schwarz}\n"
if [ "$obecht" ]; then
	tmp=$(mktemp /root/dbverbfreigabe/dbverb.cfg.XXXXXX)
	printf 'uid=praxis\npwd=%s\n' "$NEUPWD" > "$tmp"
	chown root:praxis "$tmp"
	chmod 640 "$tmp"
	mv -f "$tmp" /root/dbverbfreigabe/dbverb.cfg
	printf "${blau}/root/dbverbfreigabe/dbverb.cfg geschrieben.${schwarz}\n"
else
	printf "Waere: ${blau}/root/dbverbfreigabe/dbverb.cfg neu schreiben (uid=praxis, neues Passwort)${schwarz}\n"
fi

printf "${gruen}== 2) .mysqlpwd / .mariadbpwd ==${schwarz}\n"
for f in /root/.mysqlpwd /root/.mariadbpwd; do
	if [ "$obecht" ]; then
		tmp=$(mktemp "$f.XXXXXX")
		printf '[client]\nuser=praxis\npassword=%s\n' "$NEUPWD" > "$tmp"
		chmod 700 "$tmp"
		mv -f "$tmp" "$f"
		printf "${blau}%s geschrieben.${schwarz}\n" "$f"
	else
		printf "Waere: ${blau}%s${schwarz} neu schreiben (user=praxis, neues Passwort)\n" "$f"
	fi
done

printf "${gruen}== 3) MariaDB-Server: 'praxis'@'%%' und 'praxis'@'localhost' ==${schwarz}\n"
sql_escaped=${NEUPWD//\'/\'\'}
if [ "$obecht" ]; then
	tmpsql=$(mktemp)
	trap 'shred -u "$tmpsql" 2>/dev/null || rm -f "$tmpsql"' EXIT
	{
		printf "ALTER USER 'praxis'@'%%' IDENTIFIED BY '%s';\n" "$sql_escaped"
		printf "ALTER USER 'praxis'@'localhost' IDENTIFIED BY '%s';\n" "$sql_escaped"
		printf "FLUSH PRIVILEGES;\n"
	} > "$tmpsql"
	mariadb --defaults-extra-file=/root/.mysqlrpwd < "$tmpsql"
	printf "${blau}MariaDB-Passwort fuer 'praxis'@'%%' und 'praxis'@'localhost' gesetzt.${schwarz}\n"
	# Verifikation: mit dem neuen Passwort lokal verbinden
	if mariadb --user=praxis --password="$NEUPWD" --host=localhost -e "SELECT 1;" >/dev/null 2>&1; then
		printf "${blau}Verifikation lokal erfolgreich (praxis@localhost verbindet mit neuem Passwort).${schwarz}\n"
	else
		printf "${rot}WARNUNG: Verifikation lokal fehlgeschlagen -- bitte pruefen!${schwarz}\n"
	fi
else
	printf "Waere: ${blau}ALTER USER 'praxis'@'%%' IDENTIFIED BY '***';${schwarz}\n"
	printf "Waere: ${blau}ALTER USER 'praxis'@'localhost' IDENTIFIED BY '***';${schwarz}\n"
fi

printf "${gruen}== 4) C++-Programme (mpwd ueber -cmpwd) ==${schwarz}\n"
for p in $CPPROGS; do
	bin="/root/$p/$p"
	if [ "$obecht" ]; then
		if [ ! -x "$bin" ]; then
			printf "${rot}%s nicht gefunden/nicht ausfuehrbar -- uebersprungen!${schwarz}\n" "$bin"
			continue
		fi
		"$bin" -cmpwd "$NEUPWD" -krf >/dev/null
		printf "${blau}%s: mpwd aktualisiert.${schwarz}\n" "$p"
	else
		printf "Waere: ${blau}%s -cmpwd *** -krf${schwarz}\n" "$bin"
	fi
done

if [ "$obecht" ]; then
	printf "${gruen}Fertig.${schwarz} Alle Stellen aktualisiert. Die laufenden (installierten) Programme lesen\n"
	printf "das neue Passwort automatisch bei ihrem naechsten regulaeren Lauf aus der jeweiligen\n"
	printf "Konfiguration -- ein Neu-Ausrollen der .exe/Binaries ist dafuer NICHT erforderlich.\n"
else
	printf "${gruen}Simulation beendet.${schwarz} Fuer den echten Lauf: $0 -e <neues-passwort>\n"
fi
