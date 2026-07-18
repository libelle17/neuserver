# stutzeTMExport.sh - Generationen-Rotation für alte komprimierte
# BDT-Exporte unter "/DATA/eigene Dateien/TMExport" (verschiebt
# Aussortiertes nach /DATA/TMExportloe). Definiert nur vorgaben()/
# ermittledatum() für instutz.sh (s. dessen Kopfkommentar) - Muster
# "*.BDT.7z", nur mindestens 6M große Dateien (mgroe), nur zwei Runden: ab
# 365 Tagen 1/Monat (am 1.), ab 30 Tagen 4/Monat (1./8./15./22.); keine
# Jahres- oder Tages-Runde (kein gr0/gr3). Das Datum wird hier NICHT aus
# dem Dateinamen, sondern aus dem echten Änderungszeitstempel der Datei
# ermittelt (date -r). Aufruf: stutzeTMExport.sh [-v] [-h|--hilfe].
vorgaben() {
# vom Programmaufruf abhängige Parameter
  # Suchverzeichnis
  Vz="/DATA/eigene Dateien/TMExport";
  # Zielverzeichnis
  Zvz=/DATA/TMExportloe;
  # Musterende der interessanten Dateien
  muende="*.BDT.7z";
  # Grenze an Tagen zurück, ab der nur noch 1 Datei im Monat aufgehoben werden soll
  gr1=365;
  # Tag im Monat, mit dem eine Datei auf jeden Fall behalten werden soll
  beh1="-01-";
  # Grenze an Tagen zurück, ab der nur noch 4 Dateien im Monat aufgehoben werden sollen
  gr2=30;
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
