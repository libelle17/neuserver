#/bin/bash
blau="\033[1;34m";
lila="\033[1;35m";
dblau="\033[0;34;1;47m";
rot="\033[1;31m";
reset="\033[0m";

# $1 = Befehl, $2 = Farbe, $3=obdirekt (ohne Result, bei Befehlen z.B. wie "... && Aktv=1" oder "sh ...") $4=obimmer (auch wenn nicht echt)
# in dem Befehl sollen zur Uebergabe erst die \ durch \\ ersetzt werden, dann die $ durch \$ und die " durch \", dann der Befehl von " eingerahmt
ausf() {
  [ $verb ]&&printf "ausf(\"$1\" \"$2\" \"$3\" \"$4\")\n"
  gz=;
  anzeige=$(echo "${1%\n}"|sed 's/%/%%/;s/\\/\\\\\\\\/g')$reset;
	[ $verb -o "$2" ]&&{ gz=1;printf "$2$anzeige";}; # escape für %, soll kein printf-specifier sein
  if [ "$obecht" -o "$4" ]; then
    if test "$3" = direkt; then
      $1;
    elif test "$3"; then 
      [ $verb ]&&echo "\$1: $1";
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
          [ -f "$1" ]&&qd="$1"||printf "Datei $blau$1$reset nicht gefunden!\n";;
      esac;;
     *)
      qd="$1";;
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

tabellen() {
sql="\
CREATE TABLE IF NOT EXISTS dmprm (\
	ID INT(11) UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'ID',\
	einlID INT(11) SIGNED COMMENT 'Bezugs-ID in dmpeinl',\
  art VARCHAR(1) NOT NULL DEFAULT '0' COMMENT '0=Fehler, 1=berücksichtigte, 2=eingegangene Dokumentationen',\
  arzt VARCHAR(2) NOT NULL DEFAULT '' COMMENT 'gs,tk oder so fuer Sonstige',\
	erstellt DATE NULL DEFAULT NULL COMMENT 'Dateierstellungdatum',\
	Nachname VARCHAR(30) NOT NULL DEFAULT '' COLLATE 'utf8mb3_unicode_ci',\
	Vorname VARCHAR(30) NOT NULL DEFAULT '' COLLATE 'utf8mb3_unicode_ci',\
	Versi VARCHAR(30) NOT NULL DEFAULT '' COMMENT 'Versicherung, z.B. BKK' COLLATE 'utf8mb3_unicode_ci',\
	Dokuart VARCHAR(6) NOT NULL DEFAULT '' COMMENT 'z.B. FD2' COLLATE 'utf8mb3_unicode_ci',\
  Aktion VARCHAR(20) NOT NULL DEFAULT '' COMMENT 'wenn statt Quartal z.B. ´Ausschr.´ dort steht',\
	Quartal VARCHAR(2) NOT NULL DEFAULT '' COMMENT 'z.B. 1' COLLATE 'utf8mb3_unicode_ci',\
	Jahr VARCHAR(4) NOT NULL DEFAULT '' COMMENT 'z.B. 2024' COLLATE 'utf8mb3_unicode_ci',\
	Gebdat DATE NULL DEFAULT NULL,\
	Pat_id INT(10) UNSIGNED NOT NULL DEFAULT '0',\
	npid INT(10) UNSIGNED COMMENT 'Bezug auf Pat_id in Namen',\
	VNr VARCHAR(12) NOT NULL DEFAULT '' COMMENT 'Versicherungsnummer' COLLATE 'utf8mb3_unicode_ci',\
	Dokudat DATE NULL DEFAULT NULL COMMENT 'Abgabedatum der Doku',\
	PRIMARY KEY (ID) USING BTREE,\
 	UNIQUE INDEX eind (npid,Gebdat,Dokudat,Jahr,Quartal,Dokuart,arzt,art) USING BTREE,\
 	UNIQUE INDEX find (pat_id,Gebdat,Nachname,Vorname,Dokuart,art) USING BTREE,\
	INDEX art (art) USING BTREE,\
	INDEX erstellt (arzt,erstellt) USING BTREE,\
	INDEX Nachname (Nachname) USING BTREE,\
	INDEX Vorname (Vorname) USING BTREE,\
	INDEX Versi (Versi) USING BTREE,\
	INDEX Dokuart (Dokuart) USING BTREE,\
	INDEX Aktion (Aktion) USING BTREE,\
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

auswert() {
[ $verb ]&&printf "${blau}auswert($qdd)$reset\n";
[ ! -f "$qd" ]&&{ printf "Datei $blau\"$qd\"$reset nicht gefunden. Höre auf.\n"; exit; }
stamm=${qd%.*};
zd=${stamm}.tif; # 1. nach ghostscript
rand=${stamm}i.tif; # 2. nach convert
txt=${stamm}i;   # 3. nach tesseract

if [ "$neutif" -o ! -f "${txt}.txt" ]; then
# Umwandlung von pdf in tif
ausf "gs -q -dNOPAUSE -sDEVICE=tiffg4 -sOutputFile=\"$zd\" \"$qd\" -c quit" # -r800x800 hilft auch nichts
[ -f "$zd" ]&&{
  ausf "convert \"$zd\" -bordercolor White -border 10x10 \"$rand\"";
  [ -f "$rand" ]&&ausf "time tesseract -l deu+eng+osd \"$rand\" \"$txt\"";
}
fi;
txt=${txt}.txt
ender="${stamm}_echt.txt"; # 4. nach sed
awkd="${stamm}_awk.txt";   # 5. nach awk
awkdk="${stamm}_awkd.txt"; # 6. nach 2.sed
[ $verb ]&&[ -f "$txt" ]&&printf "nach convert und tesseract: $blau$txt$reset\n";
erstellt=;
erstellt=$(sed -n '/erstellt am/{s/.*am \([0-9]*.[0-9]*.[0-9]*\)/\1/p;q;}' "$txt")
[ $verb ]&&printf "erstellt: $blau$erstellt$reset\n";
case ${stamm,,} in *gs*) arzt=gs;; *tk*) arzt=tk;; *ah*) arzt=ah;; *) arzt=so;; esac;
[ $verb ]&&printf "Arzt: $blau$arzt$reset\n";
# sql="DELETE FROM dmprm WHERE arzt='"$arzt"' AND erstellt=STR_TO_DATE('"$erstellt"','%d.%m.%Y')";
# mariadb --defaults-extra-file=~/.mariadbpwd quelle -e"$sql";
[ $verb ]&&printf "sed ... $txt \> ${ender}\n";
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
s/[147/][|]*\([1-4]\)\//| \1\//g; # Fehlinterpretation | als 1, 4, 7 oder / vor Quartal ausbügeln
s/1|/|/g;                   # 1| löschen
s/|[[:space:]]*|/|/g; # doppelte | löschen
s/,,/,/g; # doppelte Kommas
s/\. / /g;       # überzählige Punkte vor Leerzeichen löschen
s/ \./ /g;       # überzählige Punkte nach Leerzeichen löschen
s/\(\/[0-9]\{4\}\).*/\1/g;     # überflüssige Zeichen am Zeilenende löschen
s/\([0-9]\{2\}\),[.]*\([0-9]\{2\}\)/\1.\2/g; # Kommas zwischen Ziffern durch Punkte ersetzen
s/\([0-9]\{2\}\),[.]*\([0-9]\{2\}\)/\1.\2/g; # Kommas zwischen Ziffern durch Punkte ersetzen, 2. notwendiger Aufruf
s/\([0-9]\{2\}\)[ .]\([0-9]\{2\}\)[ .]\([0-9]\{4\}\)/\1.\2.\3/g; # Leerzeichen zwischen Ziffern im Datum durch Punkte ersetzen
s/\( [0-9]\{2\}\.[0-9]\{2\}\.[0-9]\{4\}\) *[147()] *\([0-9]\{2,5\} \)/\1 |\2/g; # falsche Trennzeichen nach dem Geburtsdatum in | umwandeln
s/\(\.[0-9]\{4\} \)\([A-Z]\?[0-9]\)/\1|\2/g; # fehlendes | nach Geburtsdatum ergänzen
s/\( [0-9]\{2\}\.[0-9]\{2\}\.\)[0-9]\([0-9]\) \([0-9]\{3\} \)/ \1\2\3/g; # Leerzeichen zwischen dem Datum, Spezialfall
s/\([^| ] *\)\([0-9]\{2\}\.[0-9]\{2\}\.[0-9]\{4\}\)/\1| \2/g; # fehlendes | vor Geburts- und Dokudatum ergänzen
s/.*41915300\( [.]*|\|\) *[|1]*//g; # Spalte BSNR mit allen Ungenauigkeiten vorher, am Anfang und danch löschen 
s/^[-J]\([A-Z]\)/\1/g; # als | interpretiertes J und einleitendes - streichen
s/^\([^ ]*\), \([^ ]* \)/\1,\2/g; # | im Namen Leerzeichen hinter Kommas löschen
s/^\([^ ]*\)|\([^ ]* \)/\1-\2/g; # | im Namen durch - ersetzen
s/^\(‚- \| *\|\/\)//; # wohl Schmutz oder Leerzeichen am Anfang entfernen
s/^\(.[^A-ZÄÖÜ ,-]\+\) *\([A-ZÄÖÜ][^,]*|\)/\1,\2/; # fehlende Kommas zwischen Vor- und Nachnamen ergänzen
s/[|]*A[OQ]K/AOK/g; # AOK richtig schreiben und | davor entfernen
s/\(| *[0-9]\{1,\}\) *\([0-9]\{1,5\} [A-Z]\{0,1\}[0-9]\{1,\}\)/\1\2/g; # Leerzeichen in der Patientennummer entfernen
s/\([0-9]\{2,5\} [A-Z]*[0-9]\{1,7\}\) \([0-9]\{1,5\}\) \{0,1\}\([0-9]\{1,5\}\)/\1\2\3/g; # Leerzeichen in der Versicherungsnummer entfernen
s/\( [0-9]\{2\}\.[0-9]\{2\}\.[0-9]\) \([0-9]\{3\} \)/\1\2/g; # Leerzeichen zwischen dem Datum im Jahr
s/\( [0-9]\{2\}\.[0-9]\) \([0-9]\.[0-9]\{4\} \)/\1\2/g; # Leerzeichen zwischen dem Datum im Monat
s/ \([0-9]\{2\}\.[0-9]\{2\}\.[0-9]\{4\} \)\([^|]\)/\1| \2/g; # | nach Datum ggf. ergänzen
s/ \([0-9]\{2\}\.[0-9]\{2\}\.[0-9]\{4\}\)\.\+/\1/g; # | Punkte nach Datum löschen
s/\([^| ] *\)\([0-9]\{2\}\.[0-9]\{2\}\.[0-9]\{4\}\)/\1 | \2/g; # Leerzeichen und | vor Datum
s/\(\.[0-9]\{4\}\) *| *-* *[|(/]\? *\([0-9]\/\)/\1 | \2/; # zusätzliche Zeichen und Felder vor dem Quartal löschen
s/^\([^|,]*,[^|,]*| *[0-9]\{2\}\.[0-9]\{2\}\.[0-9]\{4\} *|[^|]*\)-* *| *\([EF]D\|BKK\)/\1 \2/; # | u.ä. vor Erst- oder Folgedoku oder Krankenkasse entfernen
s/ *| */ | /g; # Leerzeichen vor und nach | vereinheitlichen
s/| [_*]\? |/|/; # wohl Schmutz
s/\(851\) \(0288\)/\1\2/; # Einzelfälle
s/\(3\) \(T6648\)/\2/;
s/\(1\) \(\Y8811\)/\2/;
s/\(7\) \(\P6752\)/\2/;
s/\(5851\) \(\0288\)/\1\2/;
' "$txt" >"${ender}";
# Überprüfung und Ergänzung des o.g. sed-Befehls mit 2-3 putty-Fenstern, davon in einem:
# 1) Aufruf von /root/neuserver/parsetif.sh "/pfad/zur/zuüberprüfenden Datei" -v
# 2) im vi im 3. Fenster suchen:
# /^[^|,]*,[^|,]*| *[0-9]\{2\}\.[0-9]\{2\}\.[0-9]\{4\} *|[^|]*| *[0-9]\{2\}\.[0-9]\{2\}\.[0-9]\{4\} *| *[0-9]\/[0-9]\{4\}$
# dann werden die fehlerhaften gelb

epo=$(awk 'BEGIN{srand();print -srand();}'); # $(date +%s); # -epoch als vorläufige Bezugs-ID
[ $verb ]&&printf "epo: $blau$epo$reset\n";
[ $verb ]&&printf "vor akw -F \n ... ${ender} \> ${awkd}\n";
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
  if (length(pid)>6 || pid ~ /^[^0-9]/) { # keine Patientennummer
    vnr=pid;
    pid=0;
    versi=trim(re[2]);
  } else {
    vnr=trim(re[2]);
    versi=trim(re[3]);
  }
  gebdat=trim(ar[2]);
  gsub("[.]14[.]",".11.",gebdat);
  gebdat=gensub(/.49([0-9])/,".19\\1","g",gebdat);
  gebdat=gensub(/[.]9([0-9])[.]/,".0\\1.","g",gebdat);
  gsub("[.]70[.]",".10.",gebdat);
  gebdat=gensub(/4([0-9])[.]/,"1\\1.","g",gebdat);
  gsub("97[.]","07.",gebdat);
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
  gsub("31[.]09[.]","31.03.",dokudat);
  gsub("80[.]","30.",dokudat);
  gsub("41[.]","11.",dokudat);
  printf("%-21s\t%-22s\t%-10s\t%6s\t%10s\t%5s\t%-4s\t%s\t%s\n",nachname,trim(na[2]),gebdat,pid,trim(re[2]),trim(re[3]),trim(ar[4]),dokudat,trim(ar[6]));
  sql="REPLACE INTO dmprm(einlID,arzt,erstellt,Nachname,Vorname,Gebdat,Pat_id,VNr,Versi,Dokuart,Dokudat,Quartal,Jahr,npid) VALUES(" epo ",'\''" arzt "'\'',STR_TO_DATE('\''" erstellt "'\'','\''%d.%m.%Y'\''),'\''" nachname "'\'','\''" vorname "'\'',STR_TO_DATE('\''" gebdat "'\'','\''%d.%m.%Y'\''),'\''" pid "'\'','\''" vnr "'\'','\''" versi "'\'','\''" dokuart "'\'',STR_TO_DATE('\''" dokudat "'\'','\''%d.%m.%Y'\''),'\''" trim(qu[1]) "'\'','\''" trim(qu[2]) "'\'',(SELECT MIN(pat_id) FROM namen WHERE (pat_id='\''" pid "'\'' AND (nachname='\''" nachname "'\'' OR vorname='\''" vorname "'\'' OR gebdat=STR_TO_DATE('\''" gebdat "'\'','\''%d.%m.%Y'\''))) OR (nachname='\''" nachname "'\'' AND (Vorname='\''" vorname "'\'' OR Gebdat=STR_TO_DATE('\''" gebdat "'\'','\''%d.%m.%Y'\''))) OR (Vorname='\''" vorname "'\'' AND Gebdat=STR_TO_DATE('\''" gebdat "'\'','\''%d.%m.%Y'\''))))";
print sql;
system("mariadb --defaults-extra-file=~/.mariadbpwd quelle -e\"" sql "\" 2>&1");
}
END {
}
' "${ender}" >"${awkd}";
[ $obverb ]&&printf "sed ... ${awkd} \> ${awkdk}\n";
sed '/\(^REPLACE\|^INSERT\|^ERROR\|^\$0\)/d' "${awkd}" > "${awkdk}";
# echo "mariadb --defaults-extra-file=~/.mariadbpwd quelle -s -s -e\"DELETE FROM dmpeinl WHERE Datei='$qd'\";"
mariadb --defaults-extra-file=~/.mariadbpwd quelle -s -s -e"DELETE FROM dmpeinl WHERE Datei='$qd'"; # Anführungszeichen um $qd führen zum Fehler!
epo2=$(date +%s);
[ $verb ]&&printf "epo2: $blau$epo2$reset\n";
# echo "mariadb --defaults-extra-file=~/.mariadbpwd quelle -s -s -e\"INSERT INTO dmpeinl(Datei,eingelesen) FROM_UNIXTIME('$epo2'))\";"
mariadb --defaults-extra-file=~/.mariadbpwd quelle -s -s -e"INSERT INTO dmpeinl(Datei,eingelesen) VALUES('$qd',FROM_UNIXTIME('$epo2'))";
einlid=$(mariadb --defaults-extra-file=~/.mariadbpwd quelle -s -s -e"SELECT id FROM dmpeinl WHERE Datei='$qd' AND eingelesen=FROM_UNIXTIME('$epo2')");
[ $verb ]&&printf "einlid: $blau$einlid$reset\n";
mariadb --defaults-extra-file=~/.mariadbpwd quelle -s -s -e"UPDATE dmprm SET einlid='$einlid' WHERE einlid=$epo";
# echo "mariadb --defaults-extra-file=~/.mariadbpwd quelle -s -s -e\"SELECT CONCAT('Eingelesen aus Datei ','\'\"$qd\"\'',', erstellt am ','\"$erstellt\"',' für Arzt ','\"$arzt\"',': ',(SELECT COUNT(0) FROM dmprm WHERE arzt='\"$arzt\"' AND erstellt=STR_TO_DATE('\"$erstellt\"','%d.%m.%Y')),' Datensätze, davon: ',(SELECT COUNT(0) FROM dmprm WHERE arzt='\"$arzt\"' AND erstellt=STR_TO_DATE('\"$erstellt\"','%d.%m.%Y') AND npid IS NULL),' ohne Patientenzuordnung');\""
printf "\r";
# mariadb --defaults-extra-file=~/.mariadbpwd quelle -s -s -e"SELECT CONCAT('''$qd''',' eingelesen (erstellt am ','''$erstellt''',' für Arzt ','''$arzt''','): ',(SELECT COUNT(0) FROM dmprm WHERE arzt='$arzt' AND erstellt=STR_TO_DATE('$erstellt','%d.%m.%Y')),' Datensätze, davon ',(SELECT COUNT(0) FROM dmprm WHERE arzt='"$arzt"' AND erstellt=STR_TO_DATE('"$erstellt"','%d.%m.%Y') AND npid IS NULL),' ohne Patientenzuordnung');"
ausgabe=$(mariadb --defaults-extra-file=~/.mariadbpwd quelle -s -s -e"SELECT CONCAT('''$blau$qd$reset''',' eingelesen (erstellt am ','''$blau$erstellt$reset''',' für Arzt ','''$blau$arzt$reset''','): $blau',(SELECT COUNT(0) FROM dmprm WHERE einlid='$einlid'),'$reset Datensätze, davon $blau',(SELECT COUNT(0) FROM dmprm WHERE einlid='$einlid' AND npid IS NULL),'$reset ohne Patientenzuordnung:');");
ausg2="$(mariadb --defaults-extra-file=~/.mariadbpwd quelle -e'SELECT COUNT(0) FROM dmprm WHERE einlid='$einlid' AND npid IS NULL')";

# Folgende haben im Q2/25 für alle bis auf einen funktioniert:
# UPDATE dmprm dp SET pat_id = (SELECT pat_id FROM namen WHERE versichertennummer=dp.vnr) WHERE pat_id=0 AND LENGTH(vnr)>7 AND (SELECT COUNT(0) FROM namen WHERE versichertennummer=dp.vnr)=1 ;
# UPDATE dmprm dp SET pat_id = (SELECT pat_id FROM namen WHERE nachname=dp.nachname AND vorname=dp.vorname) WHERE pat_id=0 AND LENGTH(vnr)>7 AND (SELECT COUNT(0) FROM namen WHERE nachname=dp.nachname AND vorname=dp.vorname)=1 ;
# UPDATE dmprm dp SET pat_id = (SELECT pat_id FROM namen WHERE nachname=dp.nachname and gebdat=dp.gebdat) WHERE pat_id=0 AND LENGTH(vnr)>7 AND (SELECT COUNT(0) FROM namen WHERE nachname=dp.nachname and gebdat=dp.gebdat)=1 ;
# UPDATE dmprm dp SET pat_id = (SELECT pat_id FROM namen WHERE vorname=dp.vorname and gebdat=dp.gebdat) WHERE pat_id=0 AND LENGTH(vnr)>7 AND (SELECT COUNT(0) FROM namen WHERE vorname=dp.vorname and gebdat=dp.gebdat)=1 ;
# UPDATE dmprm dp SET pat_id = (SELECT pat_id FROM namen WHERE left(nachname,1)=left(dp.Nachname,1) and left(vorname,1)=left(dp.vorname,1) and gebdat=dp.gebdat) WHERE pat_id=0 AND LENGTH(vnr)>7 AND (SELECT COUNT(0) FROM namen WHERE left(nachname,1)=left(dp.Nachname,1) and left(vorname,1)=left(dp.vorname,1) and gebdat=dp.gebdat)=1 ;
# UPDATE dmprm dp SET pat_id = (SELECT pat_id FROM namen WHERE left(nachname,3)=left(dp.Nachname,3) and left(vorname,3)=left(dp.vorname,3) and year(gebdat)=year(dp.gebdat)) WHERE pat_id=0 AND LENGTH(vnr)>7 AND (SELECT COUNT(0) FROM namen WHERE left(nachname,3)=left(dp.Nachname,3) and left(vorname,3)=left(dp.vorname,3) and year(gebdat)=year(dp.gebdat))=1 ;
# UPDATE dmprm dp SET pat_id = (SELECT pat_id FROM namen WHERE left(nachname,3)=left(dp.nachname,3) and gebdat=dp.gebdat) WHERE pat_id=0 AND LENGTH(vnr)>7 AND (SELECT COUNT(0) FROM namen WHERE left(nachname,3)=left(dp.nachname,3) and gebdat=dp.gebdat)=1 ;

# printf "$ausgabe\n";
# printf "$ausg2\n";
[ $verb ]&& {
#  ausf "vi ${awkdk} ${awkd} ${ender} ${txt} -p" "" direkt;
  printf "vi \"${awkdk}\" \"${awkd}\" \"${ender}\" \"${txt}\" -p\n"
# nach 2.sed, nach awk, nach sed, nach tesseract
  vi "${awkdk}" "${awkd}" "${ender}" "${txt}" -p;
}
} # auswert

ausw2() {
[ $verb ]&&printf "${blau}ausw2($qdd)$reset\n";
pdf="$qd".pdf;
if test -f "$pdf"; then
  txt="$qd".txt;
  if ! test -f "$txt"; then
    pdftotext -layout "$pdf"
  fi
  erstellt=;
  erstellt=$(sed -n '/erstellt am/{s/.*am \([0-9]*.[0-9]*.[0-9]*\)/\1/p;q;}' "$txt")
  [ $verb ]&&printf "erstellt: $blau$erstellt$reset\n";
  awkd="${qd}_awk.sql";   # 5. nach awk
  awkdk="${qd}_awkd.err"; # 6. nach 2.sed

  epo=$(awk 'BEGIN{srand();print -srand();}'); # $(date +%s); # -epoch als vorläufige Bezugs-ID
  [ $verb ]&&printf "epo: $blau$epo$reset\n";
  [ $verb ]&&printf "vor akw -F \n ... ${txt} \> ${awkd}\n";
  epo2=$(date +%s);
  [ $verb ]&&printf "epo2: $blau$epo2$reset\n";
  [ $verb ]&&printf "pdf: $blau$pdf$reset\n";
  awk -F " " -v arzt="$arzt" -v erstellt="$erstellt" -v epo="$epo" -v epo2="$epo2" -v pdf="$pdf" '
  BEGIN {
    zl=0;
    print "BEGIN;"
  }
  /Bitte / {
    art=0;
    vsw=""
  }
  /Bitte .*Teilnahmeerklärung für/ {vsw="TN";}
  /Bitte .*Teilnahmeerklärung und Erstdokumentation/ {vsw="TN,ED";}
  /Bitte .*Erstdokumentation für/ {vsw="ED";}
  /Bitte .*Folgedokumentation für/ {vsw="FD";}
  /berücksichtigte Dokumentationen/ {art=1;vsw=""}
  /eingegangenen Dokumentationen/ {art=2;vsw=""}
  /^641915300/ {
    print "-- " $0
    gsub(/^[[:blank:]]+|[[:blank:]]+$/,"", $0)
    gsub(/[[:blank:]]+/,"_", $0)
    for(iru=1;iru<4;iru++) $0=gensub(/(^[0-9]*[^0-9]+)_([^0-9])/,"\\1 \\2",1,$0) # falls mehrere Vornamen
    split($0,ar,"_")
    split(ar[2],na,",");
    nachname=na[1];
    gsub("'\''","'\'''\''",nachname);
    vorname=na[2];
    gebdat=ar[3]
    vnr=ar[4];
    versi=ar[5];
    dokuart=ar[6] ar[7];
    dokudat=ar[8];
    split(ar[9],qu,"/");
    if (!art) if (vsw!="") qu[1]=vsw": "qu[1]
    for(k=10;k<13;k++){if(k in ar){qu[1]=qu[1]" "ar[k];}}

  printf("-- %s\t%s\t%-21s\t%-22s\t%-10s\t%6s\t%10s\t%5s\t%-4s\t%s\t%s\n",zl,art,nachname,vorname,gebdat,vnr,versi,dokuart,dokudat,qu[1],qu[2]);
  sql="REPLACE INTO dmprm(einlID,art,erstellt,Nachname,Vorname,Gebdat,Pat_id,VNr,Versi,Dokuart,Dokudat,"(qu[1]~/^[0-9]+$/?"Quartal":"Aktion")",Jahr,npid) VALUES(" epo ",'\''" art "'\'',STR_TO_DATE('\''" erstellt "'\'','\''%d.%m.%Y'\''),'\''" nachname "'\'','\''" vorname "'\'',STR_TO_DATE('\''" gebdat "'\'','\''%d.%m.%Y'\''),'\''" 0 "'\'','\''" vnr "'\'','\''" versi "'\'','\''" dokuart "'\'',STR_TO_DATE('\''" dokudat "'\'','\''%d.%m.%Y'\''),'\''" qu[1] "'\'','\''" qu[2] "'\'',COALESCE((SELECT MIN(pat_id) FROM namen WHERE (nachname='\''" nachname "'\'' AND (Vorname='\''" vorname "'\'' OR Gebdat=STR_TO_DATE('\''" gebdat "'\'','\''%d.%m.%Y'\''))) OR (Vorname='\''" vorname "'\'' AND Gebdat=STR_TO_DATE('\''" gebdat "'\'','\''%d.%m.%Y'\''))),0));";
  print sql;
     zl++;
    }
  END {
      print "DELETE FROM dmpeinl WHERE Datei='\''"pdf"'\'';"
      print "INSERT INTO dmpeinl(Datei,eingelesen) VALUES('\''"pdf"'\'',FROM_UNIXTIME('\''"epo2"'\''));"
      print "UPDATE dmprm SET einlid=(SELECT id FROM dmpeinl WHERE Datei='\''"pdf"'\''AND eingelesen=FROM_UNIXTIME('\''"epo2"'\''))WHERE einlid="epo";";
      print "COMMIT;"
  }' "${txt}" >"${awkd}";
  mariadb --defaults-extra-file=~/.mariadbpwd quelle<"${awkd}" >"${awkdk}" 2>&1
  if test -s "${awkdk}"; then
    vi "${awkdk}"
  else
    # [ $obverb ]&&printf "sed ... ${awkd} \> ${awkdk}\n";
    # sed '/\(^REPLACE\|^INSERT\|^ERROR\|^\$0\)/d' "${awkd}" > "${awkdk}";
    printf "\r";
    ausgabe=$(mariadb --defaults-extra-file=~/.mariadbpwd quelle -s -s -e"SELECT CONCAT('''$blau$pdf$reset''',' eingelesen (erstellt am ','''$blau$erstellt$reset''',IF('$arzt'='','',CONCAT(' für Arzt ','''$blau$arzt$reset''')),'): $blau',(SELECT COUNT(0) FROM dmprm WHERE einlid=i.id),'$reset Datensätze, davon $blau',(SELECT COUNT(0) FROM dmprm WHERE einlid=i.id AND npid IS NULL),'$reset ohne npid, einlid=$blau',i.id,'$reset')FROM(SELECT id FROM dmpeinl WHERE Datei='$pdf' AND eingelesen=FROM_UNIXTIME('$epo2'))i;");
    printf "$ausgabe\n";
    # printf "$ausg2\n";
    [ $verb ]&& {
    #  ausf "vi ${awkdk} ${awkd} ${txt} ${txt} -p" "" direkt;
      printf "vi \"${awkd}\" \"${txt}\" -p\n"
    # nach 2.sed, nach awk, nach sed, nach tesseract
      xargs -o vi "${awkd}" "${txt}" -p # sonst fehlt das Terminal
    }
  fi
else
  printf "Datei $blau\"$pdf\"$reset nicht gefunden. Höre auf.\n";
fi
} # ausw2

raussuch() {
#  altverb=$verb;
#  verb=;
#  find "$qvz" -maxdepth 1 \( -iname "*tk*.pdf" -o -iname "*gs*.pdf" \) -print0 |
  ausgew=0;
  gefund=0;
  find "$qvz" -maxdepth 1 -iregex ".*/[^/]*DMP[^/]* \(TK\|GS\|AH\) [^/]*\.pdf$" -print0 |
  while IFS= read -r -d '' datei; do
    gefund=$(expr $gefund + 1);
    [ $verb ]&&printf "\rUntersuche $blau$datei$reset                                          \n";
    erg=$(mariadb --defaults-extra-file=~/.mariadbpwd quelle -s -s -e"SELECT 0 FROM dmpeinl WHERE datei='$datei'");
    if [ ! "$erg" ]; then
      ausgew=$(expr $ausgew + 1);
      printf "\rbearbeite: $blau$datei$reset                                                  "; [ $verb ]&&printf "\n";
      qd="$datei";
      auswert;
    fi;
    printf "\r$blau$gefund$reset passende Dateien in \"$blau$qvz$reset\" gefunden, $blau$ausgew$reset neu ausgewertet.";
  done;
  printf "\n";
#  verb=$altverb;
  ausgew=0;
  gefund=0;
  find "$qp" "$qvz" -maxdepth 1 -not -iregex ".* \(TK\|GS\|AH\) .*" -iregex ".*reminder.*\.pdf$" -print0 |
  while IFS= read -r -d '' pdf; do
    gefund=$(expr $gefund + 1);
    [ $verb ]&&printf "\rUntersuche $blau$pdf$reset                                          \n";
    erg=$(mariadb --defaults-extra-file=~/.mariadbpwd quelle -s -s -e"SELECT 0 FROM dmpeinl WHERE datei='$pdf'");
#    if true -o [ ! "$erg" ]; then
    if [ ! "$erg" ]; then
      ausgew=$(expr $ausgew + 1);
      printf "\rbearbeite: $blau$pdf$reset                                                  "; [ $verb ]&&printf "\n";
      aktp=${pdf%/*}  # /DATA/Patientendokumente
#      echo aktp: $aktp
      qd=${pdf##*/} 
      dt=${qd%.*}   # DMP-Reminder
      qd=${pdf%.*}  # /DATA/Patientendokumente/DMP-Reminder
#      echo qd: $qd
#      echo dt: $dt
      ausw2;
      if [ "$aktp/" != "$qvz/" ]; then
        echo mv -i "$pdf" "$qd".txt "$awkd" "$awkdk" "$qvz"
        mv -i "$pdf" "$qd".txt "$awkd" "$awkdk" "$qvz"
      fi;
    fi;
    printf "\r$blau$gefund$reset passende Dateien in \"$blau$qvz$reset\" gefunden, $blau$ausgew$reset neu ausgewertet.";
  done;
  printf "\n\r";
} # raussuch


commandline "$@"; # alle Befehlszeilenparameter übergeben
[ $verb ]&&printf "verb gesetzt.\n";
if [ "$neudb" ]; then
  if [ ! $einzeln ]; then
    [ $verb ]&&printf "${rot}Lösche die Tabellen ${blau}dmpeinl$rot und ${blau}dmprm$rot!$reset\n";
    mariadb --defaults-extra-file=~/.mariadbpwd quelle -e"DROP TABLE dmpeinl";
    mariadb --defaults-extra-file=~/.mariadbpwd quelle -e"DROP TABLE dmprm";
  fi;
fi;
mariadb --defaults-extra-file=~/.mariadbpwd quelle -e"DELETE FROM dmpeinl WHERE NOT EXISTS(SELECT * FROM dmprm WHERE einlid=dmpeinl.ID)";
mariadb --defaults-extra-file=~/.mariadbpwd quelle -e"DELETE FROM dmprm WHERE NOT EXISTS(SELECT * FROM dmpeinl WHERE id=einlID)"
tabellen;
qp="/DATA/Patientendokumente";
qvz="/DATA/Patientendokumente/DMP";
if [ $einzeln ]; then
  if [ -f "$qd" ]; then
    [ $verb ]&&printf "${blau}qd: $qd$reset, rufe ${blau}auswert$reset auf\n";
    auswert;
  else
    printf "$blau\"$qd\"$reset nicht gefunden. Tue gar nichts.\n";
  fi;
else
  [ $verb ]&&printf "${blau}qd$reset nicht bestimmt, rufe ${blau}raussuch$reset auf\n";
  raussuch;
fi;
