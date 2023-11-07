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
  # nur Dateien ab diesem Datum werden berücksichtigt
  ab=$(find "$listeV" -maxdepth 1 -type f -iname "$dl*" -printf '%TY%Tm%Td\n' |sort -r|head -n1)
  # ab=20230821;
  # ab=20091231;
  # falls Jahr angegeben, wird nur dieses Unterverzeichnis von p:\eingelesen berücksichtigt
  # Jahr=2023
  Jahr=;
  verb=0;
  for para in "$@"; do
    para=$(echo "$para"|sed 's;^/;-;');
    case $para in
      -v|--verbose) verb=$(expr $verb + 1);;
    esac;
  done;
	while [ $# -gt 0 ]; do
    para=$(echo "$1"|sed 's;^/;-;');
		case $para in
      -v|--verbose);;
      -ab) ab=$2; shift;;
      -jahr) Jahr=$2; shift;;
			-h|--h|--hilfe|--help|-?|/?|--?)
        printf "Programm $blau$0$reset: durchsucht $blau$VzNG\$Jahr$reset nach nicht in Turbomed zu Patienten importierten Dateien, kopiert diese in $blau$VzKp$reset und protokolliert sie in $blau$liste$reset,\n";
        printf "  zusammengeschrieben von: Gerald Schade 2023\n";
        printf "  Benutzung:\n";
				printf "$blau$0 [-ab yyyymmdd] [-jahr yyyy] [-v] [-h|--hilfe|-?]$reset\n";
				printf "  $blau-ab$reset: berücksichtigt Dateien ab \$ab anstatt ab $ab\n";
				printf "  $blau-jahr$reset: durchsucht den Ordner $blau$VzNG\$Jahr$reset anstatt $blau$VzNG$reset\n";
			exit;;
		esac;
		[ "$verb" -gt 0 ]&&printf "Parameter: $blau$para$reset\n";
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
printf "suche in $blau$VzNG$reset ..."
find "$VzNG" -mindepth 1 -maxdepth 3 -newermt $ab -type f -not -iregex '.*\(abrechnungssem\|azubi\|anforderung\|bei geräten\|blankoform\|dmp-daten\|diabetes\(tag\|mittel\)\|dokumentation.*htm\|einladung\|experten forum\|fortbildung\|haus\(ärzteverb\|arztvertr\)\|patientenbefrag\|pipettieren\|qualitätskrit\|schweigepflichts+entbindung\|verbandsstoffe\|vhk an\)[^/]*$\|.*\.wav\|.*\.nix\|.*/\(pict\|img\).*jpg\|.*/befund_.*\.pdf\|plan .*\|.*/[0-9. ()]*.\.\(tif\|jpg\)\|.*/\(192.168\|7komma7\|abrechnung\|acots\|act\(os\|rapid\)\|ada \|adipositas\|advan[tz]ia\|afghanistan\|aida-studie\|äkd\|akag\|aktuell\|amd phenom\|amper\|anfrage\|angebot\|anleit\|anmeld\|antrag\|antwort\|aok \|apo-bank\|approbat\|artikel\|ärzt\|auf\(trag\|zug\)\|aus\(geschrieben\|richt\|stehen\)\|autofax\|avoid\|avp\|axa\|b2b\|bad heilbrunn\|bahn\|barmenia\|base \|basin\|bay\(\.\|eris\)\|befr\(agu\|eiu\)\|behand\|begleit\|berlin\( ak\|sulin\)\|brmitschnitt\|canon\|dmp\|blahusch\|easd\|ekf \|empfohlen\|erinnerung\|erklärung\|euromed\|europe\|exenatide\|fachverband\|fahrrad\|falsche\|fehlende überw\|ffh \|filelist\|finanztest\|force 3d\|fortknox\|gkm \|gkv \|gloxo\|glucosepent\|goä\|hävg\|ing-\|motivat\|patmit\|predictive\|programme\|prüfung\|pumpengutachten\|patient\|patmit\|schulungs\|sidebar\|unbekannt\)[^/]*$' \( -not -iregex '.*an fax.*' -o -iregex '.*arztbrief.*' \) -name '*'|sort > "$liste" 
printf "\r$blau%d$reset zu untersuchende Dateien ab $blau$ab$reset gefunden, bearbeite sie ...\n" $(wc -l "$liste"|cut -f1 -d' ')
# printf "Liste der in den Karteikarten fehlenden Dokumente: $blau$PrtDt\nnicht gefunden:$reset\n"
printf "Nicht in den Turbomed-Karteikarten gefundene Dokumente aus $VzNG:\n" >> $PrtDt; 
mkdir -p "$VzKp"
for d in "$PrtDt" "$VzKp"; do 
  chown sturm:praxis "$d"
  chmod 774 "$d"
done;
# lese die $liste
while read -r file; do
    DNBef=;
    TBef=;
    nr=$(expr $nr + 1);            #    let nr=$nr+1 (geht nur in bash)
#    [ $nr = 21 ]&&exit;
    DBBef="mariadb --defaults-extra-file=~/.mysqlpwd quelle -s -e\"SELECT REPLACE(REPLACE(Pfad,'\\\\\\\\','/'),'$/TurboMed','/DATA/turbomed') FROM briefe WHERE name like '$(basename "$file"|sed 's/`/%%/g'|sed "s/'/\\\\'/g")' GROUP BY Pfad\""
    DBName=$(eval "$DBBef")
    if [ "$DBName" ];then 
     dzeile=;
     dvzeile=;
#    falls gleichnamige Datei in Datenbank gefunden ...      
#    mariadb --defaults-extra-file=~/.mysqlpwd -s quelle -e"select pfad from briefe where pfad like '%|%'" => 0 Ergebnisse
     DBName=$(echo "$DBName"|tr ' \n' '| ')
#     echo "$DBName"|hexdump -C
     for zeile in $DBName; do            #     while read -r zeile; do
      zeile=$(echo "$zeile"|tr '|' ' ');
      if test -f "$zeile"; then
       if diff "$file" "$zeile" > /dev/null; then 
        dzeile="$zeile";
        break;
       else
        dvzeile="$zeile";
       fi;
      fi;
     done;
#   else
    fi;
#    falls gleichnamige Datei in Datenbank nicht gefunden ...      
    init=$(basename "$file"|cut -d' ' -f1|sed "s/[-,.;_:]*$//;s/^\(.\{3\}\).*/\1/"|tr '`' "?")
    [ "$init" = Fax ]&&init=;
#      stat "$file";
#      sz=$(stat -c%s "$file")
    dn=$(dirname "$file");
    bn=$(basename "$file");
#    bn="${bn/\`/\\\`}";
    bn=$(echo $bn|sed 's/\([`$]\)/\\\1/g;s/ / \*/g'); # zwei Leerzeichen wurden zu einem
# falls Dateiname ein Leerzeichen am Schluss enthält
#     Größe der Datei
    if [ -z "$dn" ]; then
      echo file: $file;
      echo dn: $dn;
    fi;
    sBef="find \"$dn\" -regextype sed -regex \".*/ *$bn \{0,\}\" -exec stat -c%s {} \; -quit"; # Leerzeichen am Anfang oder Ende möglich
    [ $verb -gt 1 ]&&echo $sBef;
    sz=$(eval "$sBef");
    if [ $? != 0 ]; then
      echo nr: $nr, file: $file
      printf "bn: $blau$bn$reset\n";
      echo sz: $sz;
      echo sBef: $sBef;
      exit;
    fi;
#      MT=$(stat -c%Y "$file")
# falls Dateiname ein Leerzeichen am Schluss enthält
#     Änderungsdatum der Datei
    sBef="find \"$dn\" -regextype sed -regex \".*/ *$bn \{0,\}\" -exec stat -c%Y {} \; -quit"; # Leerzeichen am Anfang oder Ende möglich
    [ $verb -gt 1 ]&&echo $sBef;
    MT=$(eval "$sBef");
    if [ $? != 0 ]; then
      echo nr: $nr, file: $file
      echo sBef: $sBef;
      exit;
    elif [ -z "$MT" ]; then
      echo nr: $nr, file: $file
      echo sBef: $sBef;
    fi;
#    MT=$(echo "$MT"|cut -d' ' -f1); # 1697093139 1697093139
    MTme=$(expr $MT - 86400);  # 1 Tag
    if [ $? != 0 ]; then
      echo nr: $nr, file: $file
      echo MT: $MT;
      exit;
    fi;
    MTpt=$(expr $MT + 518400); # 5 Tage      #      let MTme=$MT-1 MTpt=$MT+86400;
    if [ $? != 0 ]; then
      echo nr: $nr, file: $file
      echo MT: $MT;
      exit;
    fi;
#      echo $init, $sz, $MTme, $MTpt
#     Dateien mit dieser Größe und ungefähr diesem Änderungdatum finden
    TBef="find \"$VzZS\" -type f -size ${sz}c -newermt @$MTme -not -newermt @$MTpt -iname \""$init"*\""
    [ $verb -gt 1 ]&&echo TBef: $TBef;
#     find /DATA/turbomed/Dokumente -name '*|*' => 0 Ergebnisse
    TName=$(eval "$TBef"|tr ' \n' '| ')
    if [ $? != 0 ]; then
      echo nr: $nr, file: $file
      echo TBef: $TBef;
      echo TName: $TName;
      exit;
    fi;

#    fi;
    # TName auswerten
    gefu=; # deshalb dürfen nachfolgend keine subshells verwendet werden
    vzeile=;
    DNBef=;
    DName=;
    for zeile in $TName; do            #     while read -r zeile; do
     zeile=$(echo "$zeile"|tr "|" " "|tr '`' "'"|sed "s/'/\\\\'/g")
     if test -f "$zeile"; then
       if diff "$file" "$zeile" > /dev/null; then 
         gefu=ja;
         break;
       else
         vzeile="$zeile";
       fi;
     fi;
    done;          #   done < <(echo "$TName");
    # ggf. Datei aus Datenbank verwenden
    if [ -z $gefu -a "$dzeile" ]; then
      gefu=ja;
      zeile="$dzeile";
    fi;
    if [ $gefu ]; then
      DNBef="mariadb --defaults-extra-file=~/.mysqlpwd quelle -s -e\"SELECT Name FROM briefe WHERE Pfad=REPLACE(REPLACE('"$zeile"','/DATA/turbomed','$/TurboMed'),'/','\\\\\\\\') GROUP BY Pfad\""
      DName=$(eval "$DNBef");
      if [ "$dzeile" -a "$DName" ]; then
        if [ $verb -gt 0 ]; then
          printf "Datei $lila$nr$reset: $blau$file$reset gefunden und in DB\n"
          printf "                zeile: $blau$zeile$reset\n";
          printf "               dzeile: $blau$dzeile$reset\n";
          printf "                DName: $blau$DName$reset\n";
        fi;
      elif [ "$DName" ]; then # -z $dzeile => $dvziele
        printf "${rot}Datei$reset $lila$nr$reset: $blau$file$reset\n"
        printf "                zeile: $blau$zeile$reset\n";
        printf "              dvzeile: $blau$dvzeile$reset\n";
        stat "$file"|egrep 'File|Size|Modify';
        stat "$dvzeile"|egrep 'File|Size|Modify';
        printf "                DName: $blau$DName$reset\n";
      else # $dzeile
        printf "${rot}Datei$reset $lila$nr$reset: $blau$file$reset\n"
        printf "                zeile: $blau$zeile$reset\n";
        printf "                       ${rot}nicht in Datenbank gefunden.$reset";
        printf "                 ${blau}DBBef$reset: $DBBef\n";
      fi;
      if [ $verb -gt 0 ]; then
        if [ "$DName" ]; then
          printf "     nach Größe+Datum: $lila$zeile$reset\n DNBef: $blau$DNBef$reset\n";
        else
          printf "     ${lila}DNBef$reset: $DNBef\n";
        fi;
      fi;
    else # [ $gefu ] => -z $gef
      printf "${rot}Datei $lila$nr$reset: $blau$file$rot nicht gefunden!\n";
      fnr=$(expr $fnr + 1);  
      printf "%4b: %s\n" $fnr "$(basename "$file"|sed "s/'/\\\\'/g")" >> $PrtDt;
      printf "                 ${blau}DBBef$reset: $DBBef\n";
      printf "     ${lila}TBef$reset : $TBef\n";
      if [ "$vzeile" ]; then
        printf "               vzeile: $blau$vzeile$reset\n";
        stat "$file"|egrep 'File|Size|Modify';
        stat "$vzeile"|egrep 'File|Size|Modify';
      fi;
      if [ "$DBName" ]; then
        if [ "$dzeile" ]; then
          printf "               dzeile: $blau$dzeile$reset\n";
        elif [ "$dvzeile" ]; then
          printf "              dvzeile: $blau$dvzeile$reset\n";
          stat "$file"|egrep 'File|Size|Modify';
          stat "$dvzeile"|egrep 'File|Size|Modify';
        fi;
      fi;
    fi;
done < "$liste";
printf "Fertig mit $blau%d$reset zu untersuchenden Dateien ab $blau$ab$reset\n"
