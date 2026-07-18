#!/bin/sh
# wegmailen.sh - liest Konfiguration aus (erst ein optionales
# "wegmailen.conf" im aktuellen Verzeichnis, dann ein optionales
# "~/.config/wegmailen.conf" - letzteres kann Werte aus ersterem
# überschreiben) und erwartet darin u.a. $ZMVZ (zu mailendes Verzeichnis)
# und $ANMAILSTR (Trennstring im Dateinamen vor der Zieladresse). Durchsucht
# dann $ZMVZ nach Dateien, deren Name "<...> $ANMAILSTR <mailadresse>.<ext>"
# entspricht, und extrahiert daraus die Mailadresse. Aufruf ohne Parameter.
# Hinweis: in dieser Fassung wird die Mailadresse nur ermittelt und per echo
# ausgegeben - ein tatsächlicher Mailversand (z.B. per mail/sendmail) ist in
# diesem Skript (noch) nicht enthalten.
ichges="$(readlink -f "$0")";  # ~/neuserver/wegmailen.sh
ich=${ichges##*/};             # wegmailen.sh
confnm=./${ich%.*}.conf;       # wegmailen.conf
[ -f "$confnm" ]&&. "$confnm";
confdt="$(getent passwd $(logname 2>/dev/null||loginctl user-status|sed -n '1s/\(.*\) .*/\1/p'||whoami)|cut -d: -f6)/.config/$confnm"; 
[ -f "$confdt" ]&&. "$confdt"; # $HOME/.config/wegmailen.conf

mkdir -p "$ZMVZ"; # zu mailen Verzeichnis
for dt in "$ZMVZ"/*" $ANMAILSTR "*; do
 if [ -f "$dt" ]; then
  echo Datei: \"$dt\" Dateiende;
	Mailap=$(echo "$dt"|awk -F"$ANMAILSTR" '{print $2}') # Mailadresse plus Endung
	Maila=${Mailap%.*};           # Mailadresse
	echo $Maila;
 fi;
done;
