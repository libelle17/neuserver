#!/bin/dash
blue_msg() { echo -e "\\033[34;1m${@}\033[0m\c"; }
yell() { echo -e "\033[33m"; }
ROT_="\033[31m"
BLAU_="\033[34m"
SCHWARZ_="\033[0m"
verb=1;

ausf() {
  [ "$verb" ]&&printf "Befehl: $BLAU_$1$SCHWARZ_\n";
  eval "$1";
}

doumw() {
   echo -e $ROT_"doumw: "$SCHWARZ_ "$1" "$2"
   blue_msg $1
   ext=${1##*\.}
   if test $ext = "pdf" ; then 
     OCRRUMPF="$1"_ocr
     if [ $# -ge 2 ]; then OCRRUMPF="$2"/`basename "$OCRRUMPF"`; fi
     OCR="$OCRRUMPF".txt
     echo -e "\nOCR: " $OCR
     if ! test -f "$OCR"; then
      TMPTIF=/tmp/`basename "$1"`.tif
      if ! test -f "$TMPTIF"; then
        echo -e "\nErzeuge mit gs: $TMPTIF"
        ausf "ls -l \"$1\""
        ausf "gs -q -sDEVICE=tiff24nc -r600 -sPAPERSIZE=a4 -o \"$TMPTIF\" \"$1\""  
        ausf "ls -l \"$TMPTIF\""
      fi
      if test -f "$TMPTIF"; then
         touch -r "$1" "$TMPTIF"
         echo "Erzeuge mit tesseract: " "$OCR"
         yell
         ausf "tesseract -l deu+eng+osd \"$TMPTIF\" \"$OCRRUMPF\" 2>/dev/null && blue_msg \"$OCR\""
         test -f "$1" -a -f "$OCR" && ausf "touch -r \"$1\" \"$OCR\""
         rm "$TMPTIF"
      fi
     else
      echo " schon bearbeitet"
     fi

     OCRPDF="$1"$OCRANH.pdf
     if [ $# -ge 2 ]; then OCRPDF="$2"/`basename "$OCRPDF"`; fi
     if ! test -f "$OCRPDF"; then 
       echo -e $BLAU_"$OCRPDF"$SCHWARZ_ "noch nicht da!"
# symbolischer Link auf OCRmyPDF.sh
       echo "Erzeuge mit ocrpdf: " "$OCRPDF"
       ausf "ocrmypdf -d -l deu+eng+osd \"$1\" \"$OCRPDF\" 2>/dev/null" 
       test -f "$1" -a -f "$OCRPDF" && ausf "touch -r \"$1\" \"$OCRPDF\""
# steht schon hier, weil sonst bei zwei gleichzeitig laufenden Instanzen das Datum nicht mehr angeglichen wird
     else
       echo -e $BLAU_"$OCRPDF"$SCHWARZ_ "schon da!"
     fi
     if [ $# -ge 2 ]; then if test -d "$2"; then if test -f "$1"; then ausf "mv -f \"$1\" \"$2\"/"; fi; fi; fi;
   else
     echo -e $BLAU_"$1"$SCHWARZ_ "endet nicht mit '$ROT_pdf$SCHWARZ_'"
   fi
}

if [ $# -lt 1 ]; then
  echo "Benutzung : $0 <Datei- oder Pfadname> [<Zielpfad>]"; 
  exit; 
fi
IFS=$'|';
[ $ZSH_VERSION ]&& setopt sh_word_split;
OCRANH="_ocr"
# echo 1: $1
if test -d "$1"; then
 FLS=$(find "$1" -maxdepth 1 -type f -name "*.pdf" -printf "%p|" 2>/dev/null); 
# echo FLS: $FLS
 case "$FLS" in "");; *) 
   for FL in $FLS; do 
#    if ! [[ "$FL" = *$OCRANH.pdf || "$FL/" = "/" ]]; then doumw "$FL" "$2"; fi;
    case "$FL" in "");; *$OCRANH.pdf) ausf "mv -f \"$FL\" \"$2\"/";; *) doumw "$FL" "$2";; esac;
   done;;
 esac;
# for FILE in $1/*.pdf; do
#  if ! [[ "$FILE" = *$OCRANH.pdf ]]; then doumw "$FILE" "$2"; fi
# done
elif test -f "$1"; then
 doumw "$1" "$2";
else
 echo -e $BLAU_"$1"_SCHWARZ_ "nicht gefunden!"
fi
