#!/bin/bash
# setmariadbpwdfuerpraxis.sh [-e]
#
# Das neue Passwort wird NICHT mehr als Kommandozeilenparameter uebergeben
# (landete sonst dauerhaft in der Shell-History und war waehrend der Laufzeit
# ueber ps/proc/cmdline fuer jeden lokalen Prozess sichtbar - anders als
# ~/.mariadbpwd, das nur den jeweils aktuellen Stand mit Rechten 700 haelt),
# sondern interaktiv ohne Echo abgefragt (an einem Terminal) bzw. per stdin
# eingelesen (z.B. "printf '%s\n' "$pw" | setmariadbpwdfuerpraxis.sh -e" aus
# einem Passwort-Manager/Skript heraus - dasselbe Muster wie beim Push an
# Update-HeidiSQLPassword.ps1 in Schritt 6).
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
#   5) /srv/www/phppwd.php (Zugangsdaten fuer die PHP-Seiten unter /srv/www/htdocs/php/,
#      u.a. anzeig.php/ianzeig.php/dmpspei.php/tragein2.php -- Patientenlaufzettel)
#   6) HeidiSQL-Sessions (User=praxis) auf den erreichbaren Windows-PCs: per SSH-Push
#      (Konten sturm, schade, administrator -- je nachdem, welches davon auf dem
#      jeweiligen PC passwortlos erreichbar ist) wird Update-HeidiSQLPassword.ps1 per
#      scp lokal auf den PC kopiert (ein direkter Aufruf ueber den Netzwerkpfad
#      \\linux1\daten\down\ scheitert am SSH-Double-Hop-Problem: eine per Public-Key
#      authentifizierte Sitzung hat kein Windows-Passwort, um sich zusaetzlich beim
#      Samba-Server auszuweisen -- s. Testlauf 18.07.2026 auf szn4/sturm) und dort
#      ausgefuehrt; das neue Passwort wird per stdin uebergeben (landet nie auf der
#      Platte) und aktualisiert die lokale Registry (HKCU\Software\HeidiSQL\...).
#      Laeuft NUR auf linux1 (s. Hostcheck unten) - auf den Reserveservern
#      waeren die Windows-PCs ueber dasselbe LAN ohnehin nochmal erreichbar,
#      der Push muss aber nur einmal (von linux1 aus) erfolgen, nicht wiederholt.
#
# Ohne -e: Simulation (zeigt nur, was getan wuerde). Mit -e: echter Lauf.
#
# Voraussetzung: die lokal gebauten Testbinaries unter /root/<programm>/<programm>
# unterstuetzen -cmpwd bereits (s. Commit vom 09.07.2026). Falls diese durch neuere
# Quellstaende ersetzt werden, vorher "make <programm>" im jeweiligen Verzeichnis pruefen.

set -euo pipefail

rot="\e[1;31m"; gruen="\e[0;32m"; blau="\e[1;34m"; schwarz="\e[0m"

HOST=$(hostname); HOST=${HOST%%.*}

obecht=
if [ "${1:-}" = "-e" ]; then obecht=1; shift; fi

if [ -n "${1:-}" ]; then
	printf "${rot}Aufruf: $0 [-e]${schwarz}\n" >&2
	printf "  Das Passwort wird NICHT mehr als Parameter uebergeben (Shell-History/ps!),\n" >&2
	printf "  sondern gleich interaktiv abgefragt bzw. per stdin eingelesen.\n" >&2
	printf "  ohne -e: Simulation (zeigt nur, was getan wuerde)\n" >&2
	printf "  mit -e:  echter Lauf\n" >&2
	exit 1
fi

if [ -t 0 ]; then
	printf "${blau}Neues Passwort fuer 'praxis' eingeben (wird nicht angezeigt): ${schwarz}" >&2
	stty -echo
	IFS= read -r NEUPWD || true # "|| true": stty echo muss auch bei leerer Eingabe/EOF (read liefert dann != 0) unbedingt noch laufen, s.u. -- sonst bliebe das Terminal unter "set -e" ohne Echo stehen
	stty echo
	printf "\n" >&2
else
	IFS= read -r NEUPWD || true
fi
if [ -z "$NEUPWD" ]; then
	printf "${rot}Kein Passwort eingegeben -- abgebrochen.${schwarz}\n" >&2
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
	# CRLF noetig: VB6s "Line Input #" erkennt reines LF nicht als Zeilenende
	# und liest die Datei sonst als eine einzige Zeile (s. Korrektur 09.07.2026)
	printf 'uid=praxis\r\npwd=%s\r\n' "$NEUPWD" > "$tmp"
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

printf "${gruen}== 5) /srv/www/phppwd.php ==${schwarz}\n"
if [ "$obecht" ]; then
	# PHP-Single-Quote-String: nur \ und ' muessen escaped werden
	php_escaped=${NEUPWD//\\/\\\\}
	php_escaped=${php_escaped//\'/\\\'}
	tmp=$(mktemp /srv/www/phppwd.php.XXXXXX)
	printf '<?php\n$user = "praxis";\n$pwt = '\''%s'\'';\n?>\n' "$php_escaped" > "$tmp"
	chown root:root "$tmp"
	chmod 644 "$tmp"
	mv -f "$tmp" /srv/www/phppwd.php
	printf "${blau}/srv/www/phppwd.php geschrieben.${schwarz}\n"
else
	printf "Waere: ${blau}/srv/www/phppwd.php neu schreiben (user=praxis, neues Passwort)${schwarz}\n"
fi

printf "${gruen}== 6) HeidiSQL auf Windows-PCs (SSH-Push, Registry-Update) ==${schwarz}\n"
if [ "$HOST" != "linux1" ]; then
	printf "Uebersprungen: laeuft nur auf ${blau}linux1${schwarz} (hier: ${blau}%s${schwarz}) - der Push zu den\n" "$HOST"
	printf "Windows-PCs braucht nur einmal zu erfolgen, nicht wiederholt von jedem Reserveserver aus.\n"
else
	WINPCS="anmoo anmww anmmo anmmw anmh bzw2 fuss labor3 res1 res3 sono1 sr6 srn2 szo1 szon1 szoo1 szow1 szs1 szn4 wexp wres wser amd hss"
	WINKONTEN="sturm schade administrator"
	HEIDISKRIPTLOKAL=/DATA/down/Update-HeidiSQLPassword.ps1
	if [ "$obecht" ]; then
		for pc in $WINPCS; do
			ping -c1 -W1 "$pc" >/dev/null 2>&1 || continue
			for konto in $WINKONTEN; do
				zielpfad="C:/Users/$konto/Update-HeidiSQLPassword.ps1"
				scp -o BatchMode=yes -o ConnectTimeout=3 -q "$HEIDISKRIPTLOKAL" "$konto@$pc:$zielpfad" 2>/dev/null || continue
				ergebnis=$(printf '%s\n' "$NEUPWD" | ssh -o BatchMode=yes -o ConnectTimeout=3 "$konto@$pc" \
					powershell -NoProfile -ExecutionPolicy Bypass -File "$zielpfad" 2>/dev/null) || continue
				[ -n "$ergebnis" ] && printf "${blau}%s@%s${schwarz}: %s\n" "$konto" "$pc" "$ergebnis"
			done
		done
	else
		printf "Waere: fuer jeden erreichbaren PC aus (${blau}%s${schwarz})\n" "$WINPCS"
		printf "  per SSH mit den Konten ${blau}%s${schwarz} versucht,\n" "$WINKONTEN"
		printf "  ${blau}%s${schwarz} per scp lokal zu kopieren und damit das Passwort\n" "$HEIDISKRIPTLOKAL"
		printf "  in die dortige HeidiSQL-Registry zu pushen.\n"
	fi
fi

if [ "$obecht" ]; then
	printf "${gruen}Fertig.${schwarz} Alle Stellen aktualisiert. Die laufenden (installierten) Programme lesen\n"
	printf "das neue Passwort automatisch bei ihrem naechsten regulaeren Lauf aus der jeweiligen\n"
	printf "Konfiguration -- ein Neu-Ausrollen der .exe/Binaries ist dafuer NICHT erforderlich.\n"
else
	printf "${gruen}Simulation beendet.${schwarz} Fuer den echten Lauf: $0 -e\n"
fi
