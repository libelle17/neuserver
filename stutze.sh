# Suchverzeichnis
Vz=/DATA/sql;
# Zielverzeichnis
Zvz=/DATA/sqlloe;
muster="*????-??-??*.sql*";
muster="quelle--????-??-??*.sql*";
# Grenze, ab der nur noch 1 Datei im Monat aufgehoben werden soll
gr1=730;
# Tag im Monat, mit dem eine Datei auf jeden Fall behalten werden soll
beh1="-01-";
# Grenze, ab der nur noch 4 Dateien im Monat aufgehoben werden sollen
gr2=90;
# Tage im Monat, mit denen eine Datei auf jeden Fall behalten werden soll
beh2="-01-08-15-22-";
# dieses Programm soll ja nicht mit falsch eingestelltem Datum laufen => Internet-Zeit holen
ntpdate ptbtime1.ptb.de||exit
# auch die Bios-Uhr korrigieren
/sbin/hwclock --systohc 
# jetzt in Sekunden umrechnen
jsec=$(date +%s);
# die mit den Namen zwischen den Bindestrichen beginnenden Dateien nicht aussortieren
Ausspar="-dp-office-";

# Zeittifferenz zwischen jetzt und der Zeit im ersten Parameter
ddiff () {
  dsec=$(date -d "$1" +%s);
  datediff=$(awk 'BEGIN {print int(('$jsec'-'$dsec')/86400)}');
}

# das Sicherungsdatum aus dem Dateinamen ermitteln (erfordert bestimmte Namenskonvention beim Sichern)
ermittledatum() {
  # name = Name der gesicherten mariadb-Tabelle, alles bis zum letzten --
  name=${dt%--*};
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

# Zielverzeichnis ggf. erstellen
mkdir -p $Zvz;
# falls es fehlt, aufhören
test -d $Zvz ||exit
# alle Dateien mit dem Muster aus dem Quellverzeichnis raussuchen und den Namen verwenden
for dt in $(find $Vz -name "$muster" -printf '%f\n'); do
  # Sicherungsdatum ermitteln und die Variablen datum, jahr, monat, tag befüllen
  ermittledatum;
  # wenn Ausspar diesem Namen gleicht, Datei ignorieren
  case $Ausspar in *-$name-*) continue;; esac;
  # datediff mit dem Alter von $datum [d] belegen
  ddiff $datum;
  # runde = Zahl der verschiedenen Aufhebhäufigkeiten pro Monat (gr1, gr2)
  for runde in 1 2; do
    # Mindestalter der Datei [d], damit sie für diese Runde verwertet wird
    vgr=$(eval 'echo $gr'"$runde");
    # Tage im Monat, mit denen die Datei in dieser Runde auf jeden Fall behalten wird
    vbeh=$(eval 'echo $beh'"$runde");
    echo "!!!!!!!!!!! vbeh: $vbeh, Runde: $runde"
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
        echo "$runde behalte: $dt, da $tag in $vbeh";;
       *)
        echo "$runde loesche vielleicht: $dt, da $tag nicht in $vbeh";
        # ansonsten ...
#        echo "find $Vz -newermt $jahr-$monat-01 -not -newermt $datum -name "$name--????-??-??*.sql*" -print -quit;"
        # schauen, ob es tatsächlich im gleichen Monat schon eine ältere Datei gibt (die aufgehoben wird), diese dann in die Variable $aelter drucken
        aelter=$(find "$Vz" -newermt "$jahr-$monat-01" -not -newermt "$datum" -name "$name--????-??-??*.sql*" -print -quit);
        # wenn also die Variable befüllt ...
        if test "$aelter"; then
          echo $dt $name $datum $jahr $monat $tag $datediff;
          echo "   Runde $runde, älter: $aelter, loesche: $dt";
          # dann die Datei in das Zu-Löschen-Verzeichnis schieben
          mv -i $Vz/$dt $Zvz/
          # und nicht weiter prüfen
          break;
        else
          # ansonsten auch aufheben, obwohl der Tag nicht stimmt (weil dann die mit dem aufzuhebenden Tag wohl fehlt)
          echo "Runde $runde nichts älter, behalte: $dt";
        fi;;
      esac;
    else
      # ... sonst wird die Datei heute noch nicht untersucht.
      echo "$dt: mit $datediff Tagen jünger als $vgr (Runde $runde)";
    fi;
  done;
done;
