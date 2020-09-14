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
   if test $ext = "tif" -o $ext = "tiff" -o $ext = "png"; then 
     OCRRUMPF="$1"_ocr
     if [ $# -ge 2 ]; then OCRRUMPF="$2"/`basename "$OCRRUMPF"`; fi
     OCR="$OCRRUMPF".txt
     echo -e "\nOCR: " "$OCR"
     if ! test -f "$OCR"; then
      if test -f "$1"; then
         echo "Erzeuge " "$OCR"
         yell
         ausf "tesseract -l deu+eng+osd \"$1\" \"$OCRRUMPF\" 2>/dev/null && blue_msg \"$OCR\""
         test -f "$1" -a -f "$OCR" && ausf "touch -r \"$1\" \"$OCR\""
      fi
     else
      echo " schon bearbeitet\c"
     fi
     
     PDF="$1"_ocr.pdf
     if [ $# -ge 2 ]; then PDF="$2"/`basename "$PDF"`; fi
     BILDPDF=/tmp/`basename "$1"`$BILDANH.pdf # "$1"$BILDANH.pdf
     if ! test -f "$PDF"; then 
      if ! test -f "$BILDPDF"; then 
       echo -e $BLAU_"$BILDPDF"$SCHWARZ_ "noch nicht da!"
       echo "Erzeuge " "$BILDPDF"
       ausf "convert \"$1\" \"$BILDPDF\"";
      fi
      if test -f "$BILDPDF"; then
# symbolischer Link auf OCRmyPDF.sh
         ausf "ocrmypdf -d -l deu+eng+osd \"$BILDPDF\" \"$PDF\" 2>/dev/null" 
         ausf "rm \"$BILDPDF\""
         test -f "$1" -a -f "$PDF" && ausf "touch -r \"$1\" \"$PDF\""
# steht schon hier, weil sonst bei zwei gleichzeitig laufenden Instanzen das Datum nicht mehr angeglichen wird
         if [ $# -ge 2 ]; then if test -d "$2"; then if test -f "$1"; then ausf "mv -f \"$1\" \"$2\"/"; fi; fi; fi;
      fi
     else
       echo -e $BLAU_"$PDF"$SCHWARZ_ "schon da!"
     fi
     echo ""
   else
     echo -e $BLAU_"$1"$SCHWARZ_ "endet nicht mit '$ROT_tif$SCHWARZ_'"
   fi
}

if [ $# -lt 1 ]; then echo "Benutzung : $0 <Datei- oder Pfadname> [<Zielpfad>]"; exit; fi
IFS=$'|';
[ $ZSH_VERSION ]&& setopt sh_word_split;
if test -d "$1"; then
 FLS=$(find "$1" -maxdepth 1 -type f \( -name "*.tif" -o -name "*.tiff" -o -name "*.png" \) -printf "%p|" 2>/dev/null); 
 case "$FLS" in "");; *) 
   for FL in $FLS; do 
    [ "$FL" ]&& doumw "$FL" "$2";
   done;;
 esac;
# for FILE in $1/*.tif; do doumw $FILE $2 done
# for FILE in $1/*.tiff; do doumw $FILE $2 done
elif test -f "$1"; then
 doumw "$1" "$2"
else
 echo -e $BLAU_"$1"$SCHWARZ_ "nicht gefunden!"
fi
