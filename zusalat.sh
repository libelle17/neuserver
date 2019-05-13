#!/bin/bash
blau="\033[1;34m"; # für Programmausgaben
rot="\033[1;31m";
lila="\033[1;35m";
reset="\033[0m"; # Farben zurücksetzen
mt=/DATA; # Verzeichnis, das zum Ablauf eingehängt sein muß
G=$mt/Patientendokumente; # Grundverzeichnis
Q=$G/zusalat; # Quellverzeichnis
Z=$G/ur; # Zielverzeichnis für Urtext
Z2=$mt/ur; # Zielverzeichnis 2 für Urtext
F="$G/zufaxen"; # Verzeichnisse, in denen die Verschlüsselung entfernt werden soll
case "$1" in [/-]h|[/-]?|[/-]hilfe|[-/]help)
  printf "$blau$0$reset:\n";
  printf "versucht, nicht-PDF-Dateien in $blau$Q$reset in PDF-Dateien umzuwandeln,\n";
  printf "verschlüsselt PDF-Dateien in $blau$Q$reset, verschiebt das Original nach $blau$Z$reset und $blau$Z2$reset,\n";
  printf "entfernt die Verschlüsselungen bei PDF-Dateien in $blau$F$reset\n";
  exit;;
esac;
if mountpoint -q "$mt"; then # wenn mt eingehängt
  pwd=6LXpGWJo; # Lese-Passwort
  find "$F" -type f -iname "*.pdf"|while read -r d;do # entschlüsseln
    if [ -f "$d" ]; then # falls nicht zwischenzeitlich von anderer Instanz bearbeitet,
      if ! qpdf --check "$d" >/dev/null 2>/dev/null; then # die Datei nicht ohne Passwort zu öffnen ist,
       if qpdf --decrypt --password=$pwd "$d" "$d.ent" >/dev/null 2>&1; then # mit dem richtigen Passwort zu entschlüsseln ist,
         mv "$d.ent" "$d"; # dann mit der entschlüsselten Version überschreiben
       fi;
      fi;
    fi;
  done;
  find "$Q" -type f -not -iname "*.pdf"|while read -r d;do # dort alle Nicht-PDF-Dateien bearbeiten
    t=${d##*/}; # Dateiname
    r=${t%.*};  # Rumpf
    which soffice >/dev/null 2>&1||zypper install libreoffice-base;
    which soffice >/dev/null 2>&1&&soffice --headless --convert-to pdf --outdir "$Q" "$d" >/dev/null; # Umwandlungsversuch 1
    [ -f "$Q/$r.pdf" ]||convert "$d" "$Q/$r.pdf"; # ggf. Umwandlungsversuch 2
    [ -f "$Q/$r.pdf" ]&&mv "$d" "$G/"; # falls erfolgreich, Original nach P:\ verschieben
  done;
  find "$Q" -iname "*.pdf"|while read -r d;do # alle PDF-Dateien bearbeiten
    t=${d##*/}; # Dateiname
    r=${t%.*};  # Rumpf
#      if pdftk "$d" output "$G/$r.pdf" user_pw 6LXpGWJo; then # in p:\ verschlüsseln
    which qpdf >/dev/null 2>&1||zypper install qpdf;
    if [ -f "$d" ]; then # falls nicht zwischenzeitlich von anderer Instanz bearbeitet,
      if ! qpdf --check "$d" >/dev/null 2>/dev/null; then # die Datei schon verschlüsselt ist,
       if qpdf --check --password=$pwd "$d" >/dev/null; then # mit dem richtigen Passwort verschlüsselt ist,
        [ -f "$d" ]&&mv "$d" "$G/"; # immer noch nicht von anderer Instanz bearbeitet => rueckverschieben
       fi;
      fi;
    fi;
    if [ -f "$d" ]; then # falls nicht zwischenzeitlich von anderer Instanz bearbeitet
      if qpdf --encrypt $pwd Ji-54YIP 256 -modify=none -- "$d" "$G/$r.pdf"; then # in p:\verschlüsseln, auch: Schreib-Passwort
       mkdir -p "$Z2"; # $Z2 ggf. erstellen
       [ -d "$Z2" -a -f "$d" ]&&cp -a "$d" "$Z2/";  # falls erfolgreich nach $Z2 kopieren,
       mkdir -p "$Z";  # $Z ggf. erstellen
       [ -d "$Z" -a -f "$d" ]&&mv "$d" "$Z/";      # dann nach $Z verschieben
      fi;
    fi;
  done;
fi;
