#!/bin/dash
ROT_="\033[31m"
BLAU_="\033[34m"
SCHWARZ_="\033[0m"
blue_msg() { echo -e $BLAU_"\\033[34;1m${@}\033[0m\c"; }
yell() { echo -e "\033[33m"; }

ausf() {
  [ "$verb" ]&&printf "Befehl: $BLAU_$1$SCHWARZ_\n";
  eval "$1";
}

doumw() {
   echo -e $ROT_"doumw: "$SCHWARZ_ "$1" "$2"
   blue_msg $1
   OUTDIR=`dirname "$1"`
   if [ $# -ge 2 ]; then OUTDIR="$2"; fi
   ausf "soffice --headless --convert-to pdf --outdir \"$OUTDIR\" \"$1\""
   ZIEL="$OUTDIR"/`basename "$1"`
   ZIEL=${ZIEL%.*}
   ausf "touch -r \"$1\" \"$ZIEL\".pdf";
   if [ $# -ge 2 ]; then if test -d $2; then if test -f "$1"; then ausf "mv -f \"$1\" \"$2\"/"; fi; fi; fi
}

if [ $# -lt 1 ]; then echo "Benutzung : $0 <Datei- oder Pfadname> [<Zielpfad>]"; exit; fi;
IFS=$'|';
[ $ZSH_VERSION ]&& setopt sh_word_split;
if test -d "$1"; then
 FLS=$(find "$1" -maxdepth 1 -type f -printf "%p|" 2>/dev/null); 
 case "$FLS" in "");; *) 
   for FL in $FLS; do 
    [ "$FL" ]&& doumw "$FL" "$2";
   done;;
 esac;
# for FILE in $1/*; do doumw $FILE $2 done
elif test -f $1; then
 doumw "$1" "$2"
else
 echo -e $BLAU_"$1"_$SCHWARZ_ "nicht gefunden!"
fi
