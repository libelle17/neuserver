# stutzeTMBack.sh - Generationen-Rotation für alte Turbomed-7z-Archive
# unter /DATA/TMBack (verschiebt Aussortiertes nach /DATA/TMBackloe).
# Definiert nur vorgaben()/ermittledatum() für den gemeinsamen Rotations-
# Motor in instutz.sh (s. dessen Kopfkommentar) - Muster
# "TM????????_??????.7z"; anders als stutze.sh/stutzeDBBack.sh OHNE
# Jahres-Runde (kein gr0/beh0), stattdessen: ab 30 Tagen 1/Monat (am 1.),
# ab 3 Tagen 4/Monat (1./8./15./22.), ab 1 Tag 1/Tag; kein Name ist von
# der Aussortierung ausgenommen. Aufruf: stutzeTMBack.sh [-v] [-h|--hilfe].
vorgaben() {
# vom Programmaufruf abhängige Parameter
  # Suchverzeichnis
  Vz=/DATA/TMBack;
  # Zielverzeichnis
  Zvz=${Vz}loe;
  # Musterende der interessanten Dateien
  muende="TM????????_??????.7z";
  # Grenze an Tagen zurück, ab der nur noch 1 Datei im Jahr aufgehoben werden soll
  gr0=365;
  # Grenze, ab der nur noch 1 Datei im Monat aufgehoben werden soll
  gr1=30;
  # Tag im Monat, mit dem eine Datei auf jeden Fall behalten werden soll
  beh1="-01-";
  # Grenze, ab der nur noch 4 Dateien im Monat aufgehoben werden sollen
  gr2=3;
  # Tage im Monat, mit denen eine Datei auf jeden Fall behalten werden soll
  beh2="-01-08-15-22-";
  # Grenze an Tagen zurück, ab der pro Tag nur noch die jüngste Datei aufgehoben werden soll
  gr3=1;
  # die mit den Namen zwischen den Bindestrichen beginnenden Dateien nicht aussortieren
  Ausspar="";
}

# das Sicherungsdatum aus dem Dateinamen ermitteln (erfordert bestimmte Namenskonvention beim Sichern)
ermittledatum() {
  # nanf = Namensanfang, z.B. Name der gesicherten mariadb-Tabelle, alles bis zum letzten --
  nanf=${dt%.*};
  gname=$muende;
  datum=$(echo $dt|head -c10|tail -c8);
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
