#/bin/bash
qvz="/DATA/Patientendokumente/DMPakt";
qvz="/DATA/Patientendokumente/DMP";
blau="\033[1;34m";
lila="\033[1;35m";
dblau="\033[0;34;1;47m";
rot="\033[1;31m";
reset="\033[0m";

# $1 = Befehl, $2 = Farbe, $3=obdirekt (ohne Result, bei Befehlen z.B. wie "... && Aktv=1" oder "sh ...") $4=obimmer (auch wenn nicht echt)
# in dem Befehl sollen zur Uebergabe erst die \ durch \\ ersetzt werden, dann die $ durch \$ und die " durch \", dann der Befehl von " eingerahmt
ausf() {
  gz=;
  anzeige=$(echo "${1%\n}"|sed 's/%/%%/;s/\\/\\\\\\\\/g')$reset;
	[ $verb -o "$2" ]&&{ gz=1;printf "$2$anzeige";}; # escape für %, soll kein printf-specifier sein
  if [ "$obecht" -o "$4" ]; then
    if test "$3" = direkt; then
      $1;
    elif test "$3"; then 
      [ $verb ]&&echo "$1";
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
      [ "$verb" -o \( "$ret" -ne 0 -a "$resu" \) ]&&{  # ohne Anführungszeichen bei verb ggf. Fehler!
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

# Befehlszeilenparameter auswerten
commandline() {
  verb=;
  obecht=1; # zur Zeit unecht hier nicht implementiert
  einzeln=;
	while [ $# -gt 0 ]; do
   case "$1" in 
     -*|/*)
      para=${1#[-/]};
      case $para in
        e|-echt) obecht=1;;
        v|-verbose) verb=1;;
        h|'?'|-h|'-?'|/?|-hilfe) obhilfe=1;; # Achtung: das Fragezeichen würde expaniert
        -help) obhilfe=e;; # englische Hilfe
        nd|-neudd) neudb=1;;
        nt|-neutif) neutif=1;;
        *) 
          einzeln=1;
          [ $verb ]&&printf "commandline: werte aus: $blau$1$reset\n"
          [ -f "$1" ]&&q="$1"||printf "Datei $blau$1$reset nicht gefunden!\n";;
      esac;;
     *)
      q="$1";;
   esac;
   shift;
	done;
  QmD=$QL:;QmD=${QmD#:};
  ZmD=$ZL:;ZmD=${ZmD#:};
	if [ "$verb" ]; then
    printf "Parameter: $blau-v$reset => gesprächig\n";
#		printf "obecht: $blau$obecht$reset\n";
    [ $neudb ]&&printf "neudb: $blau$neudb$reset => Datenbankeinträge werden auch dann neu erstellt, wenn keine einzelne Datei angegeben\n"; 
    [ $neutif ]&&printf "neutif: $blau$neutif$reset => tif-Dateien werden neu erstellt und geparst\n"; 
	fi;
} # commandline

auswert() {
[ ! -f "$q" ]&&{ printf "Datei $blau\"$q\"$reset nicht gefunden. Höre auf.\n"; exit; }
stamm=${q%.*};
z=${stamm}.tif;
rand=${stamm}i.tif;
txt=${stamm}i;

if [ "$neutif" -o ! -f "${txt}.txt" ]; then
ausf "gs -q -dNOPAUSE -sDEVICE=tiffg4 -sOutputFile=\"$z\" \"$q\" -c quit" # -r800x800 hilft auch nichts
[ -f "$z" ]&&{
  ausf "convert \"$z\" -bordercolor White -border 10x10 \"$rand\"";
  [ -f "$rand" ]&&ausf "time tesseract -l deu+eng+osd \"$rand\" \"$txt\"";
}
fi;
txt=${txt}.txt
ender="${stamm}_echt.txt";
awkd="${stamm}_awk.txt";
awkdk="${stamm}_awkd.txt";
[ $verb ]&&[ -f "$txt" ]&&printf "Ergebnis: $blau$txt$reset\n";
erstellt=;
erstellt=$(sed -n '/erstellt am/{s/.*am \([0-9]*.[0-9]*.[0-9]*\)/\1/p;q;}' "$txt")
[ $verb ]&&printf "erstellt: $blau$erstellt$reset\n";
case ${stamm,,} in *gs*) arzt=gs;; *tk*) arzt=tk;; *) arzt=so;; esac;
[ $verb ]&&printf "Arzt: $blau$arzt$reset\n";
# sql="DELETE FROM dmprm WHERE arzt='"$arzt"' AND erstellt=STR_TO_DATE('"$erstellt"','%d.%m.%Y')";
# mariadb --defaults-extra-file=~/.mariadbpwd quelle -e"$sql";

sed '
/41915300/!d;                          # Zwischenzeilen löschen
s/|}/|/g;      # eckige Klammer nach | löschen
s/"//g; # " löschen
s/ '\''/ /g; # einfache Anführungszeichen löschen
s/[][{}][|]*/|/g; # alle Klammern durch | ersetzen
s/|\([^ 0-9EF]\)/\1/g; # | vor Versichertennummer löschen
s/ j\([^ru]\)/ |\1/g;     # " j" durch " |" ersetzen, außer in "jr." oder "jun"
s/;/,/g;     # " ; durch , ersetzen
s/\([0-9]\):\([0-9]\)/\1.\2/g;        # : zwischen Ziffern durch . ersetzen
s/[:°~\\]//g;        # :, ° und ~ löschen
s/[][{}-]|/|/g; # Klammern und - vor | streichen
s/ FFD/ |FD/g;  # verdoppletes F in Folgedoku löschen
s/\([EF]\)DT/\1D1/g; # FDT statt FD1
s/\([EF]\)[Do]\([12]\)/\1D\2/g; # o anstatt D in Erst- und Folgedoku korrigieren
s/\(- |\|[4Ff1TJI ]\)\([EF]D[12Ift]\|[EF]KHK\|[EF]AB\)/|\2/g; # Erst- und Folgedoku einheitlich einleiten
s/, *|/ |/g; # Komma nach der Krankenkasse entfernen
s/ [|]*\([EF]D\)[Iift] / |\11 /g; # I und f in Erst- und Folgedoku in 1 ändern
s/[147][|]*\([1-4]\)\//| \1\//g; # Fehlinterpretation | als 1, 4 oder 7 vor Quartal ausbügeln
s/1|/|/g;                   # 1| löschen
s/|[[:space:]]*|/|/g; # doppelte | löschen
s/\. / /g;       # überzählige Punkte vor Leerzeichen löschen
s/ \./ /g;       # überzählige Punkte nach Leerzeichen löschen
s/\(\/[0-9]\{4\}\).*/\1/g;     # überflüssige Zeichen am Zeilenende löschen
s/\([0-9]\{2\}\),[.]*\([0-9]\{2\}\)/\1.\2/g; # Kommas zwischen Ziffern durch Punkte ersetzen
s/\([0-9]\{2\}\),[.]*\([0-9]\{2\}\)/\1.\2/g; # Kommas zwischen Ziffern durch Punkte ersetzen, 2. notwendiger Aufruf
s/\([0-9]\{2\}\)[ .]\([0-9]\{2\}\)[ .]\([0-9]\{4\}\)/\1.\2.\3/g; # Leerzeichen zwischen Ziffern im Datum durch Punkte ersetzen
s/\( [0-9]\{2\}\.[0-9]\{2\}\.[0-9]\{4\}\) *[147()] *\([0-9]\{2,5\} \)/\1 |\2/g; # falsche Trennzeichen nach dem Geburtsdatum in | umwandeln
s/\(\.[0-9]\{4\} \)\([0-9]\)/\1|\2/g; # fehlendes | nach Geburtsdatum ergänzen
s/[ ]*[^| ]\([0-9]\{2\}\.[0-9]\{2\}\.[0-9]\{4\}\)/ \1/g; # überschüssige Zeichen vor Datum löschen
s/\([^| ] *\)\([0-9]\{2\}\.[0-9]\{2\}\.[0-9]\{4\}\)/\1| \2/g; # fehlendes | vor Geburts- und Dokudatum ergänzen
s/.*41915300\( [.]*|\|\) *[|1]*//g; # Spalte BSNR mit allen Ungenauigkeiten vorher, am Anfang und danch löschen 
s/^[-J]\([A-Z]\)/\1/g; # als | interpretiertes J und einleitendes - streichen
s/^\([^ ]*\), \([^ ]* \)/\1,\2/g; # | im Namen Leerzeichen hinter Kommas löschen
s/^\([^ ]*\)|\([^ ]* \)/\1-\2/g; # | im Namen durch - ersetzen
s/[|]*A[OQ]K/AOK/g; # AOK richtig schreiben und | davor entfernen
s/\(| *[0-9]\{1,\}\) *\([0-9]\{1,5\} [A-Z]\{0,1\}[0-9]\{1,\}\)/\1\2/g; # Leerzeichen in der Patientennummer entfernen
s/\([0-9]\{2,5\} [A-Z]*[0-9]\{1,7\}\) \([0-9]\{1,5\}\) \{0,1\}\([0-9]\{1,5\}\)/\1\2\3/g; # Leerzeichen in der Versicherungsnummer entfernen
s/ *| */ | /g; # Leerzeichen vor und nach | vereinheitlichen
' "$txt" >"${ender}";
epo=$(awk 'BEGIN{srand();print -srand();}'); # $(date +%s); # -epoch als vorläufige Bezugs-ID
[ $verb ]&&printf "epo: $blau$epo$reset\n";
awk -F " " -v arzt="$arzt" -v erstellt="$erstellt" -v epo="$epo" '
function trim(str) {
       # remove whitespaces begin of str and end of str
        gsub(/^[[:blank:]]+|[[:blank:]]+$/,"", str)
        return str
     }
{
  printf "$0: %s\n",$0;
  split($0,ar,"|");
  split(ar[1],na,",");
  split(ar[3],re," ");
  nachname=trim(na[1]);
  gsub("'\''","'\'''\''",nachname);
  vorname=trim(na[2]);
  pid=trim(re[1]);
  gebdat=trim(ar[2]);
  gsub(".14.",".11.",gebdat);
  gebdat=gensub(/.49([0-9])/,".19\\1","g",gebdat);
  gebdat=gensub(/[.]9([0-9])[.]/,".0\\1.","g",gebdat);
  vnr=trim(re[2]);
  versi=trim(re[3]);
  dokudat=trim(ar[5]);
  dokuart=trim(ar[4]);
  if (1) { # wenn nachträgliche Reparatur von Sed-Fehlern gewünscht
    pos=match(dokuart,/[0-9]{2}.[0-9]{2}.[0-9]{4}/,darr); # wenn das Dokumentdatum zum vorigen Datenfeld gerutscht ist
    if (pos) {
      dokudat=darr[0];
      if (pos>1) {
        dokuart=trim(substr(dokuart,1,pos-2));
      } else {
        dokuart="";
      } 
    }
    if (length(dokuart)>6) {
        pos=index(dokuart," ");
        if (pos) dokuart=substr(dokuart,1,pos);
    }
    if (!length(dokuart)) { # wenn Dokart ein Feld vorgerutscht ist
      dokuart=trim(re[4]);
      dokudat=trim(ar[4]);
      split(ar[5],qu,"/");
    } else {
      split(ar[6],qu,"/");
    }
    if (match(dokuart,/^[,.;:]/)) dokuart=substr(dokuart,2);
  }
  gsub("31.09.","31.03.",dokudat);
  gsub("80.","30.",dokudat);
  printf("%-21s\t%-22s\t%-10s\t%6s\t%10s\t%5s\t%-4s\t%s\t%s\n",nachname,trim(na[2]),gebdat,pid,trim(re[2]),trim(re[3]),trim(ar[4]),dokudat,trim(ar[6]));
  sql="REPLACE INTO dmprm(einlID,arzt,erstellt,Nachname,Vorname,Gebdat,Pat_id,VNr,Versi,Dokuart,Dokudat,Quartal,Jahr,npid) VALUES(" epo ",'\''" arzt "'\'',STR_TO_DATE('\''" erstellt "'\'','\''%d.%m.%Y'\''),'\''" nachname "'\'','\''" vorname "'\'',STR_TO_DATE('\''" gebdat "'\'','\''%d.%m.%Y'\''),'\''" pid "'\'','\''" vnr "'\'','\''" versi "'\'','\''" dokuart "'\'',STR_TO_DATE('\''" dokudat "'\'','\''%d.%m.%Y'\''),'\''" trim(qu[1]) "'\'','\''" trim(qu[2]) "'\'',(SELECT MIN(pat_id) FROM namen WHERE (pat_id='\''" pid "'\'' AND (nachname='\''" nachname "'\'' OR vorname='\''" vorname "'\'' OR gebdat=STR_TO_DATE('\''" gebdat "'\'','\''%d.%m.%Y'\''))) OR (nachname='\''" nachname "'\'' AND (Vorname='\''" vorname "'\'' OR Gebdat=STR_TO_DATE('\''" gebdat "'\'','\''%d.%m.%Y'\''))) OR (Vorname='\''" vorname "'\'' AND Gebdat=STR_TO_DATE('\''" gebdat "'\'','\''%d.%m.%Y'\''))))";
print sql;
system("mariadb --defaults-extra-file=~/.mariadbpwd quelle -e\"" sql "\" 2>&1");
}
END {
}
' "${ender}" >"${awkd}";
sed '/\(^REPLACE\|^INSERT\|^ERROR\|^\$0\)/d' "${awkd}" > "${awkdk}";
# echo "mariadb --defaults-extra-file=~/.mariadbpwd quelle -s -s -e\"DELETE FROM dmpeinl WHERE Datei='$q'\";"
mariadb --defaults-extra-file=~/.mariadbpwd quelle -s -s -e"DELETE FROM dmpeinl WHERE Datei='$q'"; # Anführungszeichen um $q führen zum Fehler!
epo2=$(date +%s);
[ $verb ]&&printf "epo2: $blau$epo2$reset\n";
# echo "mariadb --defaults-extra-file=~/.mariadbpwd quelle -s -s -e\"INSERT INTO dmpeinl(Datei,eingelesen) FROM_UNIXTIME('$epo2'))\";"
mariadb --defaults-extra-file=~/.mariadbpwd quelle -s -s -e"INSERT INTO dmpeinl(Datei,eingelesen) VALUES('$q',FROM_UNIXTIME('$epo2'))";
einlid=$(mariadb --defaults-extra-file=~/.mariadbpwd quelle -s -s -e"SELECT id FROM dmpeinl WHERE Datei='$q' AND eingelesen=FROM_UNIXTIME('$epo2')");
[ $verb ]&&printf "einlid: $blau$einlid$reset\n";
mariadb --defaults-extra-file=~/.mariadbpwd quelle -s -s -e"UPDATE dmprm SET einlid='$einlid' WHERE einlid=$epo";
# echo "mariadb --defaults-extra-file=~/.mariadbpwd quelle -s -s -e\"SELECT CONCAT('Eingelesen aus Datei ','\'\"$q\"\'',', erstellt am ','\"$erstellt\"',' für Arzt ','\"$arzt\"',': ',(SELECT COUNT(0) FROM dmprm WHERE arzt='\"$arzt\"' AND erstellt=STR_TO_DATE('\"$erstellt\"','%d.%m.%Y')),' Datensätze, davon: ',(SELECT COUNT(0) FROM dmprm WHERE arzt='\"$arzt\"' AND erstellt=STR_TO_DATE('\"$erstellt\"','%d.%m.%Y') AND npid IS NULL),' ohne Arztzuordnung');\""
printf "\r";
# mariadb --defaults-extra-file=~/.mariadbpwd quelle -s -s -e"SELECT CONCAT('''$q''',' eingelesen (erstellt am ','''$erstellt''',' für Arzt ','''$arzt''','): ',(SELECT COUNT(0) FROM dmprm WHERE arzt='$arzt' AND erstellt=STR_TO_DATE('$erstellt','%d.%m.%Y')),' Datensätze, davon ',(SELECT COUNT(0) FROM dmprm WHERE arzt='"$arzt"' AND erstellt=STR_TO_DATE('"$erstellt"','%d.%m.%Y') AND npid IS NULL),' ohne Arztzuordnung');"
ausgabe=$(mariadb --defaults-extra-file=~/.mariadbpwd quelle -s -s -e"SELECT CONCAT('''$blau$q$reset''',' eingelesen (erstellt am ','''$blau$erstellt$reset''',' für Arzt ','''$blau$arzt$reset''','): $blau',(SELECT COUNT(0) FROM dmprm WHERE einlid='$einlid'),'$reset Datensätze, davon $blau',(SELECT COUNT(0) FROM dmprm WHERE einlid='$einlid' AND npid IS NULL),'$reset ohne Arztzuordnung:');");
ausg2="$(mariadb --defaults-extra-file=~/.mariadbpwd quelle -e'SELECT COUNT(0) FROM dmprm WHERE einlid='$einlid' AND npid IS NULL'";
printf "$ausgabe\n";
printf "$ausg2\n";
[ $verb ]&& {
#  ausf "vi ${awkdk} ${awkd} ${ender} ${txt} -p" "" direkt;
  printf "vi \"${awkdk}\" \"${awkd}\" \"${ender}\" \"${txt}\" -p\n"
  vi "${awkdk}" "${awkd}" "${ender}" "${txt}" -p;
}
} # auswert

tabellen() {
sql="\
CREATE TABLE IF NOT EXISTS dmprm (\
	ID INT(11) UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'ID',\
	einlID INT(11) SIGNED COMMENT 'Bezugs-ID in dmpeinl',\
  arzt VARCHAR(2) NOT NULL DEFAULT '' COMMENT 'gs,tk oder so fuer Sonstige',\
	erstellt DATE NULL DEFAULT NULL COMMENT 'Dateierstellungdatum',\
	Nachname VARCHAR(30) NOT NULL DEFAULT '' COLLATE 'utf8mb3_unicode_ci',\
	Vorname VARCHAR(30) NOT NULL DEFAULT '' COLLATE 'utf8mb3_unicode_ci',\
	Versi VARCHAR(30) NOT NULL DEFAULT '' COMMENT 'Versicherung, z.B. BKK' COLLATE 'utf8mb3_unicode_ci',\
	Dokuart VARCHAR(6) NOT NULL DEFAULT '' COMMENT 'z.B. FD2' COLLATE 'utf8mb3_unicode_ci',\
	Quartal VARCHAR(2) NOT NULL DEFAULT '' COMMENT 'z.B. 1' COLLATE 'utf8mb3_unicode_ci',\
	Jahr VARCHAR(4) NOT NULL DEFAULT '' COMMENT 'z.B. 2024' COLLATE 'utf8mb3_unicode_ci',\
	Gebdat DATE NULL DEFAULT NULL,\
	Pat_id INT(10) UNSIGNED NOT NULL DEFAULT '0',\
	npid INT(10) UNSIGNED COMMENT 'Bezug auf Pat_id in Namen',\
	VNr VARCHAR(12) NOT NULL DEFAULT '' COMMENT 'Versicherungsnummer' COLLATE 'utf8mb3_unicode_ci',\
	Dokudat DATE NULL DEFAULT NULL COMMENT 'Abgabedatum der Doku',\
	PRIMARY KEY (ID) USING BTREE,\
 	UNIQUE INDEX eind (npid, Gebdat, Dokudat, Jahr, Quartal, Dokuart, arzt) USING BTREE,\
 	UNIQUE INDEX find (pat_id,Gebdat,Nachname,Vorname,Dokuart) USING BTREE,\
	INDEX erstellt (arzt,erstellt) USING BTREE,\
	INDEX Nachname (Nachname) USING BTREE,\
	INDEX Vorname (Vorname) USING BTREE,\
	INDEX Versi (Versi) USING BTREE,\
	INDEX Dokuart (Dokuart) USING BTREE,\
	INDEX Quartal (Quartal) USING BTREE,\
	INDEX Jahr (Jahr) USING BTREE,\
	INDEX Gebdat (Gebdat) USING BTREE,\
	INDEX Pat_id (Pat_id) USING BTREE,\
	INDEX npid (npid) USING BTREE,\
	INDEX VNr (VNr) USING BTREE,\
	INDEX Dokudat (Dokudat) USING BTREE\
)\
COMMENT='rückgemeldete DMP-Eintragungen von der Datenstelle'\
COLLATE='utf8mb3_unicode_ci'\
ENGINE=InnoDB\
";
# echo "mariadb --defaults-extra-file=~/.mariadbpwd quelle -e\"$sql\";"
mariadb --defaults-extra-file=~/.mariadbpwd quelle -e"$sql";
sql="\
CREATE TABLE IF NOT EXISTS dmpeinl (\
	ID INT(11) UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'ID',\
	Datei VARCHAR(250) NULL DEFAULT NULL COLLATE 'utf8mb3_unicode_ci',\
	eingelesen DATETIME NULL DEFAULT NULL,\
	PRIMARY KEY (ID) USING BTREE,\
	INDEX Datei (Datei) USING BTREE,\
	INDEX eingelesen (eingelesen) USING BTREE\
)\
COMMENT='Einlesungen von DMP-Rückmeldungen mit der Batch-Datei parsetif.sh'\
COLLATE='utf8mb3_unicode_ci'\
ENGINE=InnoDB\
";
# echo "mariadb --defaults-extra-file=~/.mariadbpwd quelle -e\"$sql\";"
mariadb --defaults-extra-file=~/.mariadbpwd quelle -e"$sql";
} # tabellen

raussuch() {
  altverb=$verb;
  verb=;
#  find "$qvz" -maxdepth 1 \( -iname "*tk*.pdf" -o -iname "*gs*.pdf" \) -print0 |
  ausgew=0;
  gefund=0;
  find "$qvz" -maxdepth 1 -iregex ".*\(TK\|GS\).*.pdf" -print0 |
  while IFS= read -r -d '' datei; do
    gefund=$(expr $gefund + 1);
    [ $altverb ]&&printf "\rUntersuche $blau$datei$reset                                          \n";
    erg=$(mariadb --defaults-extra-file=~/.mariadbpwd quelle -s -s -e"SELECT 0 FROM dmpeinl WHERE datei='$datei'");
    if [ ! "$erg" ]; then
      ausgew=$(expr $ausgew + 1);
      printf "\rbearbeite: $blau$datei$reset                                                  "; [ $verb ]&&printf "\n";
      q="$datei";
      auswert;
    fi;
    printf "\r$blau$gefund$reset passende Dateien in \"$blau$qvz$reset\" gefunden, $blau$ausgew$reset neu ausgewertet.";
  done;
  printf "\n";
  verb=$altverb;
} # raussuch


commandline "$@"; # alle Befehlszeilenparameter übergeben
if [ "$neudb" ]; then
  if [ ! $einzeln ]; then
    [ $verb ]&&printf "${rot}Lösche die Tabellen ${blau}dmpeinl$rot und ${blau}dmprm$rot!$reset\n";
    mariadb --defaults-extra-file=~/.mariadbpwd quelle -e"DROP TABLE dmpeinl";
    mariadb --defaults-extra-file=~/.mariadbpwd quelle -e"DROP TABLE dmprm";
  fi;
fi;
tabellen;
if [ $einzeln ]; then
  if [ -f "$q" ]; then
    [ $verb ]&&printf "${blau}q: $q$reset, rufe ${blau}auswert$reset auf\n";
    auswert;
  else
    printf "$blau\"$q\"$reset nicht gefunden. Tue gar nichts.\n";
  fi;
else
  [ $verb ]&&printf "${blau}q$reset nicht bestimmt, rufe ${blau}raussuch$reset auf\n";
  raussuch;
fi;
