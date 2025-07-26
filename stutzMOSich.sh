# $1 = Befehl, $2 = Farbe, $3=obdirekt (ohne Result, bei Befehlen z.B. wie "... && Aktv=1" oder "sh ...")
# in dem Befehl sollen zur Uebergabe erst die \ durch \\ ersetzt werden, dann die $ durch \$ und die " durch \", dann der Befehl von " eingerahmt
vorgaben() {
# vom Programmaufruf abhängige Parameter
  # Suchverzeichnis
  Vz=/mnt/wser/mosich;
  # Zielverzeichnis
  Zvz=/mnt/wser/mosich/loe;
  # Musterende der interessanten Dateien
  muende="[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]";
  # Grenze an Tagen zurück, ab der nur noch 1 Datei im Jahr aufgehoben werden soll
  gr0=365;
  # Monat im Jahr, mit dem eine Datei auf jeden Fall behalten werden soll
  beh0="-01-";
  # Grenze an Tagen zurück, ab der nur noch 1 Datei im Monat aufgehoben werden soll
  gr1=5;
  # Tag im Monat, mit dem eine Datei auf jeden Fall behalten werden soll
  beh1="-01-";
  # Grenze an Tagen zurück, ab der nur noch 4 Dateien im Monat aufgehoben werden sollen
  gr2=1;
  # Tage im Monat, mit denen eine Datei auf jeden Fall behalten werden soll
  beh2="-01-08-15-22-";
  # die mit den Namen zwischen den Bindestrichen beginnenden Dateien nicht aussortieren
  Ausspar="-loe-files-" # "-dp-office-";
  # ob Verzeichnisse statt Dateien überprüft werden sollen
  obvz=true;
}

# das Sicherungsdatum aus dem Dateinamen ermitteln (erfordert bestimmte Namenskonvention beim Sichern)
ermittledatum() {
  # nanf = Namensanfang zum Vergleich mit $Ausspar, z.B. Name der gesicherten mariadb-Tabelle, alles bis zum letzten --
  [[ $dt =~ ^[0-9]{14}$ ]]&&nanf=nichtaussparen||nanf=;
  # Variable für die Suche älterer Sicherungen des gleichen Gegenstandes für find ... -name "$gname"
  gname=$muende;
  # datum = erste 8 Buchstaben
  datum=$(echo $dt|sed 's/^\(.\{8\}\).*$/\1/');
  # jahr = erste 4 Buchstaben
  jahr=$(echo $dt|sed 's/^\(.\{4\}\).*$/\1/');
  # monat = nächste 2 Buchstaben
  monat=$(echo $dt|sed 's/^.\{4\}\(.\{2\}\).*$/\1/');
  # tag = nächste 2 Buchstaben
  tab=$(echo $dt|sed 's/^.\{6\}\(.\{2\}\).*$/\1/');
}

. instutz.sh
