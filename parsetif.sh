#/bin/bash
q=$1;
[ ! -f "$q" ]&&{ echo "Datei \"$q\" nicht gefunden. Höre auf."; exit; }
stamm=${1%.*};
z=${stamm}.tif;
rand=${stamm}i.tif;
txt=${stamm}i;


# $1 = Befehl, $2 = Farbe, $3=obdirekt (ohne Result, bei Befehlen z.B. wie "... && Aktv=1" oder "sh ...") $4=obimmer (auch wenn nicht echt)
# in dem Befehl sollen zur Uebergabe erst die \ durch \\ ersetzt werden, dann die $ durch \$ und die " durch \", dann der Befehl von " eingerahmt
ausf() {
  gz=;
  anzeige=$(echo "${1%\n}"|sed 's/%/%%/;s/\\/\\\\\\\\/g')$reset;
	[ "$verb" -o "$2" ]&&{ gz=1;printf "$2$anzeige";}; # escape für %, soll kein printf-specifier sein
  if [ "$obecht" -o "$4" ]; then
    if test "$3" = direkt; then
      $1;
    elif test "$3"; then 
      [ "$verb" ]&&echo "$1";
      eval "$1"; 
    else 
  #    ne=$(echo "$1"|sed 's/\([\]\)/\\\\\1/g;s/\(["]\)/\\\\\1/g'); # neues Eins, alle " und \ noch ein paar Mal escapen; funzt nicht
  #    printf "$rot$ne$reset";
      resu=$(eval "$1" 2>&1); 
    fi;
    ret=$?;
    resgedr=;
    [ $verb ]&& printf " -> ret: $blau$ret$reset";
    if [ -z "$3" ]; then 
      [ "$verb" -o \( "$ret" -ne 0 -a "$resu" \) ]&&{ 
        [ "$gz" ]||printf "$2$anzeige";
        [ "$ret" = 0 ]&& farbe=$blau|| farbe=$rot;
        printf "${reset}, resu:\n$farbe"; 
        resgedr=1;
        [ "$resu" ]&&{ [ "$maxz" -a "$maxz" -ne 0 -a $(echo "$resu"|wc -l) > "$maxz" ]&&resz="...\n"$(echo "$resu"|tail -n$maxz)||resz="$resu";};
        printf -- "$resz"|sed -e '$ a\'; # || echo -2: $resz; # Zeilenenden als solche ausgeben
        printf "$reset";
      }
    fi; # if [ -z "$3" ]; then 
  fi; # obecht
  [ "$gz" -a -z "$resgedr" ]&&printf "\n";
#  [ $resgedr ]||printf "\n";
} # ausf

verb=1;
obecht=1;
ausf "gs -q -dNOPAUSE -sDEVICE=tiffg4 -sOutputFile=\"$z\" \"$q\" -c quit"
[ -f "$z" ]&&{
  ausf "convert \"$z\" -bordercolor White -border 10x10 \"$rand\"";
  [ -f "$rand" ]&&ausf "tesseract -l deu+eng+osd \"$rand\" \"$txt\"";
}
[ -f "$txt" ]&&echo Ergebnis: "$txt";
