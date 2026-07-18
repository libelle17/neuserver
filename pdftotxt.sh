#!/bin/zsh
# pdftotxt.sh - erstellt aus einer Bild-Datei (.jpg, .pdf oder bereits
# vorhandenes .tif) per tesseract eine OCR-Textdatei (Sprachen deu+eng+fra+
# ita). Je nach Endung von $1 (komplett mit Endung übergeben, z.B.
# "scan.pdf") wird vorher nach "$1.tif" umgewandelt (Endung wird angehängt,
# nicht ersetzt - aus "scan.pdf" wird also "scan.pdf.tif"): .jpg per
# "convert", .pdf per ghostscript (mit optionalem $2 als zusätzlichem
# gs-Parameter, z.B. für Auflösung); bei .tif wird direkt tesseract auf $1
# angewendet. tesseract selbst hängt an den Ausgabenamen ".txt" an. Aufruf:
# pdftotxt.sh <Dateiname mit Endung> [gs-Zusatzparameter bei .pdf].
#Fallunterscheidung: bei *.jpg: convert "$1.jpg" "$1.tif"
# Pruefe Parameterzahl #
if [ $# -lt 1 ]; then; echo "Benutzung : $0 <Dateiname>"; exit; fi
# Pruefe Existenz der Datei
if [ ! -f $1 ]; then; echo "Datei \"$1\" nicht gefunden"; exit; fi
filename=$1
ext=${filename##*\.}
if [ $ext = "tif" ]; then
  tesseract -l deu+eng+fra+ita "$1" "$1"
else
  case $ext in
    "jpg" ) convert "$1" "$1.tif" ;;
    "pdf") gs -q -dNOPAUSE $2 -sDEVICE=tiffg4 -sOutputFile="$1.tif" "$1" -c quit ;;
  esac
  tesseract -l deu+eng+fra+ita "$1.tif" "$1"
fi
