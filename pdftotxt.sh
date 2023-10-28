#!/bin/zsh
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
