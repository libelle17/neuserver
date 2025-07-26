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
  # Grenze, ab der nur noch 1 Datei im Jahr aufgehoben werden soll
  gr0=730;
  # Monat im Jahr, mit dem eine Datei auf jeden Fall behalten werden soll
  beh0="-01-";
  # Grenze, ab der nur noch 1 Datei im Monat aufgehoben werden soll
  gr1=365;
  # Tag im Monat, mit dem eine Datei auf jeden Fall behalten werden soll
  beh1="-01-";
  # Grenze, ab der nur noch 4 Dateien im Monat aufgehoben werden sollen
  gr2=30;
  # Tage im Monat, mit denen eine Datei auf jeden Fall behalten werden soll
  beh2="-01-08-15-22-";
  # die mit den Namen zwischen den Bindestrichen beginnenden Dateien nicht aussortieren
  Ausspar="-dp-" # "-dp-office-";
}

# das Sicherungsdatum aus dem Dateinamen ermitteln (erfordert bestimmte Namenskonvention beim Sichern)
ermittledatum() {
  # nanf = Namensanfang, z.B. Name der gesicherten mariadb-Tabelle, alles bis zum letzten --
  nanf=${dt%--*};
  # Variable für die Suche älterer Sicherungen des gleichen Gegenstandes für find ... -name "$gname"
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

. instutz.sh
