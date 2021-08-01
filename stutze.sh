# $1 = Befehl, $2 = Farbe, $3=obdirekt (ohne Result, bei Befehlen z.B. wie "... && Aktv=1" oder "sh ...")
# in dem Befehl sollen zur Uebergabe erst die \ durch \\ ersetzt werden, dann die $ durch \$ und die " durch \", dann der Befehl von " eingerahmt
vorgaben() {
# vom Programmaufruf abhängige Parameter
  # Suchverzeichnis
  Vz=/DATA/sql;
  # Zielverzeichnis
  Zvz=/DATA/sqlloe;
  # Musterende der interessanten Dateien
  muende="????-??-??*.sql*";
  # Grenze, ab der nur noch 1 Datei im Monat aufgehoben werden soll
  gr1=730;
  # Tag im Monat, mit dem eine Datei auf jeden Fall behalten werden soll
  beh1="-01-";
  # Grenze, ab der nur noch 4 Dateien im Monat aufgehoben werden sollen
  gr2=90;
  # Tage im Monat, mit denen eine Datei auf jeden Fall behalten werden soll
  beh2="-01-08-15-22-";
  # die mit den Namen zwischen den Bindestrichen beginnenden Dateien nicht aussortieren
  Ausspar="-dp-office-";
}

# das Sicherungsdatum aus dem Dateinamen ermitteln (erfordert bestimmte Namenskonvention beim Sichern)
ermittledatum() {
  # nanf = Namensanfang, z.B. Name der gesicherten mariadb-Tabelle, alles bis zum letzten --
  nanf=${dt%--*};
  gname=$nanf--$muende;
  # datum = zunächst String hinter dem ersten --
  datum=${dt#*--};
  # jahr = in datum alles bis zum ersten -
  jahr=${datum%%-*};
  # datum = dann alles bis zum letzten - in datum
  datum=${datum%-*};
#  ndat=$(date -d "$datum +1 day" +%Y-%m-%d);
  # monat = zunächst alles ab dem ersten - in datum 
  monat=${datum#*-};
  # tag = alles ab dem ersten - in monat
  tag=${monat#*-};
  # monat = dann alles bis zum letzten in monat
  monat=${monat%-*};
}

# ab hier sind alle gleich
vgbstarr() {
# eher starre Vorgaben
	blau="\033[1;34m"; # für Programmausgaben
	rot="\033[1;31m";
	lila="\033[1;35m";
	reset="\033[0m"; # Farben zurücksetzen
  mgroe=0;
}

# Befehlszeilenparameter auswerten
commandline() {
	while [ $# -gt 0 ]; do
		para="$1";
		case $para in
			-v|--verbose) verb=1;;
			-h|--h|--hilfe|-hilfe|-?|/?|--?)
        printf "Programm $blau$0$reset: verschiebt einen Teil der Dateien nach Muster $blau*$muende$reset aus $blau$Vz$reset nach $blau$Zvz$reset,\n";
        printf "  zusammengeschrieben von: Gerald Schade 15.6.2019\n";
        printf "  Benutzung:\n";
				printf "  $blau$0 [-v] [-h|--hilfe|-?]$reset\n";
			exit;;
			--help|-help)
        printf "Program $blau$0$reset: moves part of the files of pattern $blau*$muende$reset from $blau$Vz$reset to $blau$Zvz$reset,\n";
        printf "  written together by: Gerald Schade 15.6.2019\n";
        printf "  Usage:\n";
				printf "  $blau$0 [-v] [-h|--hilfe|-help]$reset\n";
			exit;;
			*) pcs="$para";;
		esac;
		[ "$verb" ]&&printf "Parameter: $blau$para$reset\n";
		shift;
	done;
}

zeit() {
  # dieses Programm soll ja nicht mit falsch eingestelltem Datum laufen => Internet-Zeit holen
  bef="ntpdate ptbtime1.ptb.de";
  [ "$verb" ]&&{ eval "$bef"||exit;:;}||{ eval "$bef" >/dev/null 2>&1||exit;};
  # auch die Bios-Uhr korrigieren
  /sbin/hwclock --systohc 
  # jetzt in Sekunden umrechnen
  jsec=$(date +%s);
}

# Zeittifferenz zwischen jetzt und der Zeit im ersten Parameter
ddiff() {
  dsec=$(date -d "$1" +%s);
  datediff=$(awk 'BEGIN {print int(('$jsec'-'$dsec')/86400)}');
#  echo Name: $nanf, Datum: $datum, datediff: $datediff
}

vgbstarr;
vorgaben;
# Zielverzeichnis ggf. erstellen
mkdir -p "$Zvz";
# falls es fehlt, aufhören
test -d "$Zvz" ||exit
commandline "$@"; # alle Befehlszeilenparameter übergeben
zeit;
# alle Dateien mit dem Muster aus dem Quellverzeichnis raussuchen und den Namen verwenden
[ "$verb" ]&& echo "find \"$Vz\" -name "*$muende" -size +$mgroe -printf '%f\n'"
for dt in $(find "$Vz" -name "*$muende" -size +$mgroe -printf '%f\n'); do
  # Sicherungsdatum ermitteln und die Variablen datum, jahr, monat, tag befüllen
  ermittledatum;
  [ "$verb" ]&&printf "$blau$dt$reset => $rot$datum$reset => $nanf\n"
  # wenn Ausspar diesem Namen gleicht, Datei ignorieren
  [ "$Ausspar" ]&&case $Ausspar in *$nanf*) continue;; esac;
  # datediff mit dem Alter von $datum [d] belegen
  ddiff $datum;
  # runde = Zahl der verschiedenen Aufhebhäufigkeiten pro Monat (gr1, gr2)
  for runde in 1 2; do
    # Mindestalter der Datei [d], damit sie für diese Runde verwertet wird
    vgr=$(eval 'echo $gr'"$runde");
    # Tage im Monat, mit denen die Datei in dieser Runde auf jeden Fall behalten wird
    vbeh=$(eval 'echo $beh'"$runde");
#    echo "!!!!!!!!!!! vbeh: $vbeh, Runde: $runde"
#    echo datediff: $datediff
#    echo vgr: $vgr
#    echo tag: $tag
#    echo vbeh: $vbeh
    # wenn die Datei also älter als dieses Mindestalter ist ...
    if test $datediff -gt $vgr; then
      # wenn der Monatstag der Datei ..
      case $vbeh in 
       # $vbeh gleicht ..
       *-$tag-*)
        # dann Datei behalten
        [ "$verb" ]&&echo "$runde behalte: $dt, da $tag in $vbeh";
        ;;
       *)
        [ "$verb" ]&&echo "$runde loesche vielleicht: $dt, da $tag nicht in $vbeh";
        # ansonsten ...
#        echo "find $Vz -newermt $jahr-$monat-01 -not -newermt $datum -name "$nanf--????-??-??*.sql*" -print -quit;"
        # schauen, ob es tatsächlich im gleichen Monat schon eine ältere Datei gibt (die aufgehoben wird), diese dann in die Variable $aelter drucken
        befehl="find \"$Vz\" -newermt \"$jahr-$monat-01\" -not -newermt \"$datum\" -name \"$gname\" -print -quit";
        [ "$verb" ]&&echo befehl: $befehl
        aelter=$(eval $befehl)
        # wenn also die Variable befüllt ...
        if test "$aelter"; then
          # [ "$verb" ]&&echo $dt $nanf $datum $jahr $monat $tag $datediff;
          [ "$verb" ]&&echo "   Runde $runde, älter: $aelter, loesche/verschiebe: $dt";
          # dann die Datei in das Zu-Löschen-Verzeichnis schieben
          mv -i "$Vz/$dt" "$Zvz/"
          # und nicht weiter prüfen
          break;
        else
          # ansonsten auch aufheben, obwohl der Tag nicht stimmt (weil dann die mit dem aufzuhebenden Tag wohl fehlt)
          [ "$verb" ]&&echo "Runde $runde nichts älter, behalte: $dt";
        fi;;
      esac;
    else
      # ... sonst wird die Datei heute noch nicht untersucht.
      [ "$verb" ]&&echo "$dt: mit $datediff Tagen jünger als $vgr (Runde $runde)";
    fi;
  done;
done;

