#!/bin/dash
# sucht in p:\eingelesene, aber nicht in die Karteikarten importierte Dokumente und kopiert sie in p:\ohneImportNachweis

vorgaben() {
  # vom Programmaufruf abhängige Parameter
  gruen="\033[0;32m"
  blau="\033[1;34m";
  dblau="\033[0;34;1;47m";
  rot="\033[1;31m";
  lila="\033[1;35m";
  reset="\033[0m";
  # Verzeichnis zum Durchsuchen nach vielleicht nicht gefundenen Importen:
  VzNG=/DATA/Patientendokumente/eingelesen/
  # Liste mit allen zu pruefenden Dateien
  listeV=/DATA/Patientendokumente/eingelesen
  dl=dateiliste_
  liste=$listeV/$dl$(date +%Y%d%m_%H%M%S).txt
  # Verzeichnis zum Suchen
  VzZS=/DATA/turbomed/Dokumente
  # Verzeichnis für Kopien der nicht Gefundenen
  VzKp=/DATA/Patientendokumente/ohneImportNachweis
  # Protokolldatei der nicht Gefundenen
  PrtDt="/DATA/Patientendokumente/Nicht_gefundene_Importe_$Jahr_"$(date +%y%m%d_%H%M%S)".txt"
  nr=0
  fnr=0
}

# Befehlszeilenparameter auswerten
commandline() {
  # verbose
  verb=0;
  # nur Dateien ab diesem Datum werden berücksichtigt
  ab=$(find $listeV -maxdepth 1 -type f -iname "$dl*" -printf '%TY%Tm%Td\n' |sort -r|head -n1)
  # ab=20230821;
  # ab=20091231;
  # falls Jahr angegeben, wird nur dieses Unterverzeichnis von p:\eingelesen berücksichtigt
  # Jahr=2023
  Jahr=;
	while [ $# -gt 0 ]; do
    para=$(echo "$1"|sed 's;^/;-;');
		case $para in
      -ab) ab=$2; shift;;
      -jahr) Jahr=$2; shift;;
      -v|--verbose) verb=$(expr $verb + 1);;
			-h|--h|--hilfe|--help|-?|/?|--?)
        printf "Programm $blau$0$reset: durchsucht $blau$VzNG\$Jahr$reset nach nicht in Turbomed zu Patienten importierten Dateien, kopiert diese in $blau$VzKp$reset und protokolliert sie in $blau$liste$reset,\n";
        printf "  zusammengeschrieben von: Gerald Schade 2023\n";
        printf "  Benutzung:\n";
				printf "$blau$0 [-ab yyyymmdd] [-jahr yyyy] [-v] [-h|--hilfe|-?]$reset\n";
				printf "  $blau-ab$reset: berücksichtigt Dateien ab \$ab anstatt ab $ab\n";
				printf "  $blau-jahr$reset: durchsucht den Ordner $blau$VzNG\$Jahr$reset anstatt $blau$VzNG$reset\n";
			exit;;
		esac;
		[ "$verb" ]&&printf "Parameter: $blau$para$reset\n";
		shift;
	done;
  # Verzeichnis zum Durchsuchen nach vielleicht nicht gefundenen Importen:
  VzNG=$VzNG$Jahr;
  [ $Jahr ]&&{ awk "BEGIN{if($Jahr ~ /^[0-9]{2}$/) exit 0;exit 1;}"&&Jahr=20$Jahr;};
  awk "BEGIN{if($ab ~ /^[0-3][0-9](0[1-9]|1[0-2])(0[1-9]|[12][0-9]|3[01])$/) exit 0;exit 1;}"&&ab=20$ab;
	if [ "$verb" -gt 0 ]; then
		printf "ab: $blau\"$ab\"$reset\n";
		printf "Jahr: $blau\"$Jahr\"$reset\n";
		printf "VzNG: $blau\"$VzNG\"$reset\n";
		printf "verb: $blau\"$verb\"$reset\n";
	fi;
  [ $Jahr ]&&{ awk "BEGIN{if($Jahr ~ /^[0-9]{4}$/) exit 0;exit 1;}"||{ printf "Jahr $blau$Jahr$reset nicht wohlgeformt. Breche ab.\n"; exit 1;};};
  awk "BEGIN{if($ab ~ /^20[0-3][0-9](0[1-9]|1[0-2])(0[1-9]|[12][0-9]|3[01])$/) exit 0;exit 1;}"||{ printf "ab $blau$ab$reset nicht wohlgeformt. Breche ab.\n"; exit 1;};
} # commandline

# hier geht's los
vorgaben;
commandline "$@"; # alle Befehlszeilenparameter übergeben
printf "suche in $blaut$VzNG$reset:"
find $VzNG -mindepth 1 -maxdepth 3 -newermt $ab -type f -not -iregex '.*\(abrechnungssem\|azubi\|anforderung\|bei geräten\|blankoform\|dmp-daten\|diabetes\(tag\|mittel\)\|dokumentation.*htm\|einladung\|experten forum\|fortbildung\|haus\(ärzteverb\|arztvertr\)\|patientenbefrag\|pipettieren\|qualitätskrit\|schweigepflichts+entbindung\|verbandsstoffe\|vhk an\)[^/]*$\|.*\.wav\|.*/\(pict\|img\).*jpg\|.*/befund_.*\.pdf\|plan .*\|.*/[0-9. ()]*.\.\(tif\|jpg\)\|.*/\(192.168\|7komma7\|abrechnung\|acots\|act\(os\|rapid\)\|ada \|adipositas\|advan[tz]ia\|afghanistan\|aida-studie\|äkd\|akag\|aktuell\|amd phenom\|amper\|anfrage\|angebot\|anleit\|anmeld\|antrag\|antwort\|aok \|apo-bank\|approbat\|artikel\|ärzt\|auf\(trag\|zug\)\|aus\(geschrieben\|richt\|stehen\)\|autofax\|avoid\|avp\|axa\|b2b\|bad heilbrunn\|bahn\|barmenia\|base \|basin\|bay\(\.\|eris\)\|befr\(agu\|eiu\)\|behand\|begleit\|berlin\( ak\|sulin\)\|brmitschnitt\|canon\|dmp\|blahusch\|easd\|ekf \|empfohlen\|erinnerung\|erklärung\|euromed\|europe\|exenatide\|fachverband\|fahrrad\|falsche\|fehlende überw\|ffh \|filelist\|finanztest\|force 3d\|fortknox\|gkm \|gkv \|gloxo\|glucosepent\|goä\|hävg\|ing-\|motivat\|patmit\|predictive\|programme\|prüfung\|pumpengutachten\|patient\|patmit\|schulungs\|sidebar\|unbekannt\)[^/]*$' \( -not -iregex '.*an fax.*' -o -iregex '.*arztbrief.*' \) -name '*'|sort > "$liste" 
printf "\r$blau%d$reset zu untersuchende Dateien gefunden, bearbeite sie ...\n" $(wc -l "$liste"|cut -f1 -d' ')
# lese die $liste
while read -r file; do
    gefu=; # deshalb dürfen nachfolgend keine subshells verwendet werden
    TBef=;
    DNBef=;
    nr=$(expr $nr + 1);            #    let nr=$nr+1 (geht nur in bash)
#    [ $nr = 21 ]&&exit;
    DBBef="mariadb --defaults-extra-file=~/.mysqlpwd quelle -s -e\"SELECT REPLACE(REPLACE(Pfad,'\\\\\\\\','/'),'$/TurboMed','/DATA/turbomed') FROM briefe WHERE name like '$(basename "$file"|sed 's/`/%%/g'|sed "s/'/\\\\'/g")' GROUP BY Pfad\""
    TName=$(eval "$DBBef")
    if [ "$TName" ];then 
     [ $verb -gt 0 ]&&printf "$nr: $blau$file$reset\n"
#    falls gleichnamige Datei in Datenbank gefunden ...      
#    mariadb --defaults-extra-file=~/.mysqlpwd -s quelle -e"select pfad from briefe where pfad like '%|%'" => 0 Ergebnisse
     TName=$(echo "$TName"|tr ' \n' '| ')
#     echo "$TName"|hexdump -C
     for zeile in $TName; do            #     while read -r zeile; do
      zeile=$(echo "$zeile"|tr '|' ' ')
      [ $verb -gt 0 ]&&printf " in DB: $reset$zeile$blau existiert"
      [ -f "$zeile" ]&&{ [ $verb -gt 0 ]&&printf "$reset\n";gefu=ja;}||{ [ $verb -gt 0 ]&&printf "$rot nicht$reset\n";}
     done;          #   done < <(echo "$TName");
    else
     [ $verb -gt -1 ]&&printf "$nr: $blau$file$reset\n"
#    falls gleichnamige Datei in Datenbank nicht gefunden ...      
     init=$(basename "$file"|cut -d' ' -f1|sed "s/[-,.;_:]*$//;s/^\(.\{3\}\).*/\1/"|tr '`' "?")
     [ $verb -gt -1 ]&&echo init: $init
#      stat "$file";
#      sz=$(stat -c%s "$file")
      dn=$(dirname "$file");
      bn=$(basename "$file");
# falls Dateiname ein Leerzeichen am Schluss enthält
#     Größe der Datei
      sz=$(find "$dn" -regextype sed -regex ".*/$bn *" -exec stat -c%s {} \;);
#      MT=$(stat -c%Y "$file")
# falls Dateiname ein Leerzeichen am Schluss enthält
#     Änderungsdatum der Datei
      MT=$(find "$dn" -regextype sed -regex ".*/$bn *" -exec stat -c%Y {} \;)
      MTme=$(expr $MT - 172800);
      MTpt=$(expr $MT + 172800);       #      let MTme=$MT-1 MTpt=$MT+86400;
#      echo $init, $sz, $MTme, $MTpt
#     Dateien mit dieser Größe und ungefähr diesem Änderungdatum finden
      TBef="find $VzZS -type f -size ${sz}c -newermt @$MTme -not -newermt @$MTpt -iname \""$init"*\""
      [ $verb -gt -1 ]&&printf "${lila}TBef: $rot$TBef$reset\n";
#     find /DATA/turbomed/Dokumente -name '*|*' => 0 Ergebnisse
      TName=$(eval $TBef|tr ' \n' '| ')
      if [ "$TName" ];then 
       for zeile in $TName; do # while read -r zeile; do
         zeile=$(echo "$zeile"|tr "|" " "|tr '`' "'"|sed "s/'/\\\\'/g")
         DNBef="mariadb --defaults-extra-file=~/.mysqlpwd quelle -s -e\"SELECT Name FROM briefe WHERE Pfad=REPLACE(REPLACE('"$zeile"','/DATA/turbomed','$/TurboMed'),'/','\\\\\\\\') GROUP BY Pfad\""
         DName=$(eval $DNBef)
         [ $verb -gt -1 ]&&printf " nach Größe+Datum: $lila$zeile$reset\n DNBef: $blau$DNBef$reset\n DName: $blau$DName$reset\n";
         [ "$DName" ]&&{ gefu=ja;} # break
       done # < <(echo "$TName");
      fi;
    fi;
    [ $gefu ]||{ 
      fnr=$(expr $fnr + 1);  
      [ $fnr = 1 ]&&{ 
        printf "Liste der in den Karteikarten fehlenden Dokumente: $blau$PrtDt\nnicht gefunden:$reset\n"
        printf "Nicht in den Turbomed-Karteikarten gefundene Dokumente aus $VzNG:\n" >> $PrtDt; 
        mkdir -p "$VzKp"
        for d in "$PrtDt" "$VzKp"; do 
          chown sturm:praxis "$d"
          chmod 774 "$d"
        done;
      }
      printf "%4b: %s\n" $fnr "$(basename "$file"|sed "s/'/\\\\'/g")" >> $PrtDt;
      printf "${blau}%4b: $rot$file$reset\n" $fnr; 
      printf "     DBBef: $DBBef\n";
      printf "     TBef : $TBef\n";
      printf "     DNBef: $DNBef\n";
      cp -a "$file" "$VzKp";
    } # [ $gefu ]
done < "$liste";
