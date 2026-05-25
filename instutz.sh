# inlcude fuer mehrere stutz*.sh
# ab hier sind alle gleich
vgbstarr() {
# eher starre Vorgaben
	blau="\033[1;34m"; # für Programmausgaben
	rot="\033[1;31m";
	lila="\033[1;35m";
	reset="\033[0m"; # Farben zurücksetzen
  mgroe=0;
  # Standardvorgabe: pro Tag nur die jüngste Datei behalten, wenn älter als 3 Tage;
  # kann in vorgaben() des aufrufenden Scripts überschrieben werden
  gr3=3;
} # vgbstarr

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
} # commandline

zeit() {
  # dieses Programm soll nicht mit vielleicht falsch eingestelltem Datum laufen => Internet-Zeit holen
  # bef="ntpdate ptbtime1.ptb.de";
  bef="/sbin/chronyd -q 'server ptbtime1.ptb.de iburst maxsamples 1'&&/sbin/hwclock --systohc"
  [ "$verb" ]&&{ eval "$bef"||exit;:;}||{ eval "$bef" >/dev/null 2>&1||exit;};
  # auch die Bios-Uhr korrigieren
  # /sbin/hwclock --systohc 
  # jetzt in Sekunden umrechnen
  jsec=$(date +%s);
} # zeit

# Zeittifferenz zwischen jetzt und der Zeit im ersten Parameter
ddiff() {
  dsec=$(date -d "$1" +%s 2>/dev/null);
  # wenn date das Datum nicht auflösen konnte, Fehler melden und abbrechen
  if [ -z "$dsec" ]; then
    [ "$verb" ]&&printf "${rot}Ungültiges Datum '$1' bei Datei $dt – wird übersprungen${reset}\n";
    datediff="";
    return 1;
  fi
  datediff=$(awk 'BEGIN {print int(('$jsec'-'$dsec')/86400)}');
#  echo Name: $nanf, Datum: $datum, datediff: $datediff
} # ddiff

vgbstarr;
vorgaben;
# Zielverzeichnis ggf. erstellen
mkdir -p "$Zvz";
# falls es fehlt, aufhören
test -d "$Zvz" ||exit
commandline "$@"; # alle Befehlszeilenparameter übergeben
zeit;
# alle Dateien mit dem Muster aus dem Quellverzeichnis raussuchen und den Namen verwenden
[ "$verb" ]&& echo "find \"$Vz\" -maxdepth 1 -name "*$muende" -not -size -$mgroe -printf '%f\n'"
for dt in $(find "$Vz" -maxdepth 1 -name "*$muende" -not -size -$mgroe -printf '%f\n'); do
  # Sicherungsdatum ermitteln und die Variablen datum, jahr, monat, tag befüllen
  ermittledatum;
  [ "$verb" ]&&printf "$blau$dt$reset => Datum: $rot$datum$reset, nanf: $nanf\n"
  # wenn Ausspar diesem Namen gleicht, Datei ignorieren
  [ "$Ausspar" ]&&case $Ausspar in *$nanf*)[ "$verb" ]&&echo "$Ausspar in *$nanf* => continue";continue;; esac;
  # datediff mit dem Alter von $datum [d] belegen; bei ungültigem Datum Datei überspringen
  ddiff $datum || continue;
  # runde = Zahl der verschiedenen Aufhebhäufigkeiten (gr0..gr3)
  for runde in 0 1 2 3; do
    # Mindestalter der Datei [d], damit sie für diese Runde verwertet wird
    vgr=$(eval 'echo $gr'"$runde");
    # Tage im Monat oder Monate im Jahr, mit denen die Datei in dieser Runde auf jeden Fall behalten wird
    # (Runde 3 benötigt kein Behaltemuster, dort wird die jüngste Datei des Tages ermittelt)
    vbeh=$(eval 'echo $beh'"$runde");
    # falls kein Mindestalter angegeben, diese Runde überspringen
    [ "$vgr" ]||continue;
    # für Runden 0-2: auch ohne Behaltemuster überspringen
    [ $runde -lt 3 ]&&{ [ "$vbeh" ]||continue; };
# Variablen je nach Runde/Prüfzeitraum setzen (nur für Runden 0-2)
    [ $runde -eq 0 ]&&{ tagomonat=$monat;ttit=Monat;pruefanf=$jahr-01-01;}
    [ $runde -eq 1 -o $runde -eq 2 ]&&{ tagomonat=$tag;ttit=Tag;pruefanf=$jahr-$monat-01;}
    # wenn die Datei also älter als dieses Mindestalter ist ...
    if test $datediff -gt $vgr; then
      if [ $runde -lt 3 ]; then
        # Runden 0-2: Datei anhand des Tages-/Monatsmusters prüfen
        # wenn der Monatstag der Datei ..
        case $vbeh in 
         # $vbeh gleicht ..
         *-$tagomonat-*)
          # dann Datei behalten
          [ "$verb" ]&&echo "Runde $runde, behalte: $dt, da $ttit $tagomonat in $vbeh";
          ;;
         *)
          [ "$verb" ]&&echo "Runde $runde loesche vielleicht: $dt, da $ttit $tagomonat nicht in $vbeh";
          # ansonsten ...
#        echo "find $Vz -newermt $jahr-$monat-01 -not -newermt $datum -name "$nanf--????-??-??*.sql*" -print -quit;"
          # schauen, ob es im gleichen Monat/Jahr schon eine ältere Datei gibt (die aufgehoben wird), diese dann in die Variable $aelter drucken
          befehl="find \"$Vz\" -maxdepth 1 -newermt \"$pruefanf\" -not -newermt \"$datum\" -name \"$gname\" -print -quit";
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
        # Runde 3: pro Tag nur die jüngste Datei behalten
        # den Folgetag berechnen, um den Suchrahmen auf genau diesen Tag einzugrenzen
        ndat=$(date -d "$datum +1 day" +%Y-%m-%d);
        # schauen, ob es am gleichen Tag bereits eine jüngere Datei des gleichen Gegenstandes gibt;
        # -newer mit dem Dateipfad vergleicht den echten mtime-Zeitstempel, damit werden
        # weder die Datei selbst noch ältere Dateien des gleichen Tages fälschlich gefunden
        befehl="find \"$Vz\" -maxdepth 1 -newer \"$Vz/$dt\" -not -newermt \"$ndat\" -name \"$gname\" -print -quit";
        [ "$verb" ]&&echo "Runde 3 befehl: $befehl"
        juenger=$(eval $befehl)
        # wenn eine jüngere Datei des gleichen Tages gefunden wurde ...
        if test "$juenger"; then
          [ "$verb" ]&&echo "   Runde 3, jünger am gleichen Tag: $juenger, loesche/verschiebe: $dt";
          # dann diese ältere Datei des Tages in das Zu-Löschen-Verzeichnis schieben
          mv -i "$Vz/$dt" "$Zvz/"
          # und nicht weiter prüfen
          break;
        else
          # ansonsten ist dies die jüngste Datei des Tages => aufheben
          [ "$verb" ]&&echo "Runde 3 keine jüngere Datei des gleichen Tages, behalte: $dt";
        fi;
      fi;
    else
      # ... sonst wird die Datei heute noch nicht untersucht.
      [ "$verb" ]&&echo "$dt: mit $datediff Tagen jünger als $vgr (Runde $runde)";
    fi;
  done;
done;
[ "$verb" ]&&{
  MUPR=$(readlink -f $0); # Mutterprogramm
  echo "Fertig mit $MUPR"
}
