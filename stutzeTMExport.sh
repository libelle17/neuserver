# $1 = Befehl, $2 = Farbe, $3=obdirekt (ohne Result, bei Befehlen z.B. wie "... && Aktv=1" oder "sh ...")
# in dem Befehl sollen zur Uebergabe erst die \ durch \\ ersetzt werden, dann die $ durch \$ und die " durch \", dann der Befehl von " eingerahmt
vorgaben() {
# vom Programmaufruf abhängige Parameter
  # Suchverzeichnis
  Vz=/DATA/eigene\ Dateien/TMExport;
  # Zielverzeichnis
  Zvz=/DATA/TMExportloe;
  # Musterende der interessanten Dateien
  muende="*.BDT.7z";
  # Grenze, ab der nur noch 1 Datei im Monat aufgehoben werden soll
  gr1=730;
  # Tag im Monat, mit dem eine Datei auf jeden Fall behalten werden soll
  beh1="-01-";
  # Grenze, ab der nur noch 4 Dateien im Monat aufgehoben werden sollen
  gr2=90;
  # Tage im Monat, mit denen eine Datei auf jeden Fall behalten werden soll
  beh2="-01-08-15-22-";
  # die mit den Namen zwischen den Bindestrichen beginnenden Dateien nicht aussortieren
  Ausspar=;
  # Mindestgroesse
  mgroe="6M";
}

# das Sicherungsdatum aus dem Dateinamen ermitteln (erfordert bestimmte Namenskonvention beim Sichern)
ermittledatum() {
  # nanf = Namensanfang, z.B. Name der gesicherten mariadb-Tabelle, alles bis zum letzten --
  nanf=; # wenn leer, dann muss auch Ausspar leer sein
  gname=$nanf$muende;
  # datum = zunächst String hinter dem ersten --
  datum=$(date -r "$Vz/$dt" "+%Y %m %d");
  jahr=$(echo $datum|awk '{print $1}');
  monat=$(echo $datum|awk '{print $2}');
  tag=$(echo $datum|awk '{print $3}');
  datum=$(date -r "$Vz/$dt" "+%Y-%m-%d %H:%M:%S");
}

. instutz.sh
