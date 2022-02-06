# $1 = Befehl, $2 = Farbe, $3=obdirekt (ohne Result, bei Befehlen z.B. wie "... && Aktv=1" oder "sh ...")
# in dem Befehl sollen zur Uebergabe erst die \ durch \\ ersetzt werden, dann die $ durch \$ und die " durch \", dann der Befehl von " eingerahmt
vorgaben() {
# vom Programmaufruf abhängige Parameter
  # Suchverzeichnis
  Vz=/DATA/DBBack;
  # Zielverzeichnis
  Zvz=/DATA/DBBackloe;
  # Musterende der interessanten Dateien
  muende="_????????.7z";
  # Grenze, ab der nur noch 1 Datei im Monat aufgehoben werden soll
  gr1=30;
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
  nanf=${dt%.*};
  # datum = zunächst String hinter dem ersten --
  datum=${nanf#*_};
  nanf=${nanf%_*};
  gname=$nanf$muende;
  # jahr = in datum alles bis zum ersten -
  jahr=$(echo $datum|head -c 4)
  # datum = dann alles bis zum letzten - in datum
#  ndat=$(date -d "$datum +1 day" +%Y-%m-%d);
  # monat = zunächst alles ab dem ersten - in datum 
  monat=$(echo $datum|head -c 6|tail -c 2)
  # tag = alles ab dem ersten - in monat
  tag=$(echo $datum|head -c 8|tail -c 2)
  # monat = dann alles bis zum letzten in monat
  datum=$jahr-$monat-$tag;
}

. instutz.sh
