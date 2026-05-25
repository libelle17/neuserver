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
  # Grenze an Tagen zurück, ab der nur noch 1 Datei im Jahr aufgehoben werden soll
  gr0=730;
  # Monat im Jahr, mit dem eine Datei auf jeden Fall behalten werden soll
  beh0="-01-";
  # Grenze an Tagen zurück, ab der nur noch 1 Datei im Monat aufgehoben werden soll
  gr1=182;
  # Tag im Monat, mit dem eine Datei auf jeden Fall behalten werden soll
  beh1="-01-";
  # Grenze an Tagen zurück, ab der nur noch 4 Dateien im Monat aufgehoben werden sollen
  gr2=15;
  # Tage im Monat, mit denen eine Datei auf jeden Fall behalten werden soll
  beh2="-01-08-15-22-";
  # Grenze an Tagen zurück, ab der pro Tag nur noch die jüngste Datei aufgehoben werden soll
  gr3=2;
  # die mit den Namen zwischen den Bindestrichen beginnenden Dateien nicht aussortieren
  Ausspar="-dp-" # "-dp-office-";
  # Mindestgroesse, wenn nicht angegeben, dann 0
  # mgroe="6M";
}

# das Sicherungsdatum aus dem Dateinamen ermitteln (erfordert bestimmte Namenskonvention beim Sichern)
ermittledatum() {
  # nanf = Namensanfang, z.B. Name der gesicherten mariadb-Tabelle, alles bis zum letzten --
  nanf=${dt%--*};
  # Variable für die Suche älterer Sicherungen des gleichen Gegenstandes für find ... -name "$gname"
  gname=$nanf--$muende;
  # datum = zunächst String hinter dem ersten --
  datum=${dt#*--};
  # Dateiendung (alles ab dem ersten Punkt) entfernen, damit das Datum sauber extrahiert werden kann
  datum=${datum%%.*};
  # datum auf genau JJJJ-MM-TT begrenzen (erste 10 Zeichen)
  datum=${datum:0:10};
  # jahr, monat, tag direkt per Substring aus dem normierten Datum lesen
  jahr=${datum:0:4};
  monat=${datum:5:2};
  tag=${datum:8:2};
}

. /root/bin/instutz.sh
