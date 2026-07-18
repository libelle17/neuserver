# stutzMOSich.sh - Generationen-Rotation für Sicherungen unter
# /mnt/wser/mosich (Medical-Office-Sicherungen, vermutlich Verzeichnisse
# statt Dateien - Name besteht rein aus einem 14-stelligen Zeitstempel
# JJJJMMTTHHMMSS), verschiebt Aussortiertes nach $Vz/loe. Definiert nur
# vorgaben()/ermittledatum() für instutz.sh (s. dessen Kopfkommentar):
# behält ab 365 Tagen 1/Jahr (Januar), ab 30 Tagen 1/Monat (am 1.), ab 7
# Tagen 4/Monat (1./8./15./22.); Namen, die NICHT rein aus 14 Ziffern
# bestehen, werden nie aussortiert (Ausspar-Logik ist hier umgedreht: über
# ein Regex-Muster statt eines Teilstrings). Hinweis: "obvz=true" (Zeile
# unten) wird von instutz.sh nirgends ausgewertet - toter Schalter, ohne
# Wirkung auf den tatsächlichen Ablauf. Aufruf: stutzMOSich.sh [-v]
# [-h|--hilfe].
vorgaben() {
# vom Programmaufruf abhängige Parameter
  # Suchverzeichnis
  Vz=/mnt/wser/mosich;
  # Zielverzeichnis
  Zvz=$Vz/loe;
  mkdir -p $Zvz;
  # Musterende der interessanten Dateien
  muende="[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]";
  # Grenze an Tagen zurück, ab der nur noch 1 Datei im Jahr aufgehoben werden soll
  gr0=365;
  # Monat im Jahr, mit dem eine Datei auf jeden Fall behalten werden soll
  beh0="-01-";
  # Grenze an Tagen zurück, ab der nur noch 1 Datei im Monat aufgehoben werden soll
  gr1=30;
  # Tag im Monat, mit dem eine Datei auf jeden Fall behalten werden soll
  beh1="-01-";
  # Grenze an Tagen zurück, ab der nur noch 4 Dateien im Monat aufgehoben werden sollen
  gr2=7;
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

. /root/bin/instutz.sh
