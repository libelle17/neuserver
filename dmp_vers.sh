#!/bin/dash
blau="\033[1;34m";
lila="\033[1;35m";
dblau="\033[0;34;1;47m";
rot="\033[1;31m";
reset="\033[0m";
verb=1;

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
	dateidat DATE NULL DEFAULT NULL COMMENT 'Dateierstellungdatum',\
	erstellt DATE NULL DEFAULT NULL COMMENT 'Erstellungdatum eines Blocks',\
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
	INDEX dateidat (dateidat) USING BTREE,\
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
pdf="$qd".pdf;
if test -f "$pdf"; then
  txt="$qd".txt;
  if ! test -f "$txt"; then
    pdftotext -layout "$pdf"
  fi
  dateidat=;
  dateidat=$(sed -n '/München,/{s/.*München,[[:space:]]*\([0-9]*.[0-9]*.[0-9]*\)/\1/p;q;}' "$txt")
  echo dateidat: $dateidat;
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
  awk -F " " -v arzt="$arzt" -v dateidat="$dateidat" -v erstellt="$erstellt" -v epo="$epo" -v epo2="$epo2" -v pdf="$pdf" '
  BEGIN {
    zl=0;
    print "BEGIN;"
    print "DELETE FROM dmprm WHERE dateidat=STR_TO_DATE('\''" dateidat "'\'','\''%d.%m.%Y'\'');"
  }
  /Bitte.*Teilnahmeerklärung für/ {vsw="TN";art=3;}
  /Bitte.*Teilnahmeerklärung und Erstdokumentation/ {vsw="TN,ED";art=3;}
  /Intervallfehler/ {vsw="TN,ED";art=3;}
  /Bitte.*Erstdokumentation für/ {vsw="ED";art=3;}
  /Bitte.*Folgedokumentation für/ {vsw="FD";art=3;}
  /berücksichtigte Dokumentationen/ {vsw="";art=1;}
  /eingegangenen Dokumentationen/ {vsw="";art=2;}
  /Dokumentationen ohne Handlungsbedarf/ {vsw="";art=5;}
  /889690003/ {arzt="gs";}
  /933284903/ {arzt="tk";}
  /177828303/ {arzt="ah";}
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
    if (vsw!="") qu[1]=vsw": "qu[1]
    for(k=10;k<13;k++){if(k in ar){qu[1]=qu[1]" "ar[k];}}
    gdr=gensub(/([0-9]{2})\.([0-9]{2})\.([0-9]{4})/, "\\3\\2\\1", "g",gebdat)

  printf("-- %s\t%s\t%-21s\t%-22s\t%-10s\t%6s\t%10s\t%5s\t%-4s\t%s\t%s\n",zl,art,nachname,vorname,gebdat,vnr,versi,dokuart,dokudat,qu[1],qu[2]);
  sql="REPLACE INTO dmprm(einlID,art,arzt,dateidat,erstellt,Nachname,Vorname,Gebdat,Pat_id,VNr,Versi,Dokuart,Dokudat,"(qu[1]~/^[0-9]+$/?"Quartal":"Aktion")",Jahr,npid) VALUES(" epo ",'\''" art "'\'','\''" arzt "'\'',STR_TO_DATE('\''" dateidat "'\'','\''%d.%m.%Y'\''),STR_TO_DATE('\''" erstellt "'\'','\''%d.%m.%Y'\''),'\''" nachname "'\'','\''" vorname "'\''," gdr ",'\''" 0 "'\'','\''" vnr "'\'','\''" versi "'\'','\''" dokuart "'\'',STR_TO_DATE('\''" dokudat "'\'','\''%d.%m.%Y'\''),'\''" qu[1] "'\'','\''" qu[2] "'\'',COALESCE((SELECT MIN(pat_id) FROM namen WHERE (nachname='\''" nachname "'\'' AND Vorname='\''" vorname "'\'' AND Gebdat=" gdr ") OR ((NOT(nachname='\''" nachname "'\'' AND Vorname='\''" vorname "'\'' AND Gebdat=" gdr "))AND (gebdat=" gdr " AND(nachname RLIKE'\''" nachname "'\''OR'\''" nachname "'\''RLIKE nachname)))),0));";
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
      printf "vi \"${awkdk}\" \"${awkd}\" \"${txt}\" \"${txt}\" -p\n"
    # nach 2.sed, nach awk, nach sed, nach tesseract
      vi "${awkdk}" "${awkd}" "${txt}" "${txt}" -p;
    }
  fi
else
  printf "Datei $blau\"$pdf\"$reset nicht gefunden. Höre auf.\n";
fi
} # auswert

commandline "$@"; # alle Befehlszeilenparameter übergeben
[ $verb ]&&printf "verb gesetzt.\n";
if [ "$neudb" ]; then
  if [ ! $einzeln ]; then
    [ $verb ]&&printf "${rot}Lösche die Tabellen ${blau}dmpeinl$rot und ${blau}dmprm$rot!$reset\n";
    mariadb --defaults-extra-file=~/.mariadbpwd quelle -e"DROP TABLE dmpeinl";
    mariadb --defaults-extra-file=~/.mariadbpwd quelle -e"DROP TABLE dmprm";
  fi;
fi;
tabellen;
qp=/DATA/Patientendokumente/DMP-Reminder/
dt="DMP-Reminder 21.4.26"
qd="$qp$dt";
auswert;

