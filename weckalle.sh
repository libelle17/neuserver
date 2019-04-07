#!/bin/sh
# versucht (alle) PCs an der Fritzbox zu wecken; 
# zusammengeschrieben von/written together by: Gerald Schade 6.4.2019
blau="\033[1;34m";
rot="\033[1;31m";
lila="\033[1;35m";
reset="\033[0m";
FB="http://fritz.box:49000"
Ausgabe=ergtr64.txt
# curl $FB/tr64desc.xml

# Funktion für ein bis zwei TR-64-Abfragen
fragab() {
	if [ "$1" ];then filter="$1";else filter="sed -n p";fi;
  case $controlURL in /*);;*) controlURL=/upnp/control/$controlURL;;esac;
  case $serviceType in urn:*);;*) serviceType=urn:dslforum-org:service:$serviceType;;esac;
  [ "$verb" ]&&printf "controlURL: $blau$controlURL$reset\n"
  [ "$verb" ]&&printf "serviceType: $blau$serviceType$reset\n"
  [ "$verb" ]&&printf "Action: $blau$Action$reset\n"
  [ "$ParIn" ]&&[ "$verb" ]&&printf "Parin: $blau$ParIn$reset\n";
  [ "$Inhalt" ]&&[ "$verb" ]&&printf "Inhalt: $blau$Inhalt$reset\n";
  Soap="http://schemas.xmlsoap.org/soap";
  XML='<?xml version="1.0" encoding="utf-8"?>
  <s:Envelope s:encodingStyle="'$Soap'/encoding/" xmlns:s="'$Soap'/envelope/">
    <s:Body><u:'$Action' xmlns:u="'$serviceType'"'
  [ "$ParIn" ]&&XML=$XML'><'$ParIn'>'${Inhalt}'</'$ParIn'></u:'$Action'>'||XML=$XML' />'
  XML=$XML'</s:Body>\n</s:Envelope>' # mit neue-Zeile-Zeichen nach <s:Body> ging anrufen nicht
  # printf "XML derAbfrage: \n$blau$XML$reset\n"
  for ipv in 4 6;do
    printf "Trying/versuche ipv$ipv\r";
    befehl="curl -$ipv -k --anyauth -u \"$crede\" \\n\
          -H \"Content-Type: text/xml; charset=utf-8\" \\n\
          -H \"SoapAction: $serviceType#$Action\" \\n\
          \"$FB$controlURL\" \\n\
          -d '$XML'"; # 2>/dev/null zur Unterdrueckung der Verbindungsgeschwindigkeitsausgabe
    erg=$(eval $(echo $befehl|sed 's/\\n//g;s/\\t//g') 2>protok);
    ret=$?;
    awk 'BEGIN {while (c++<100) printf " ";printf "\r";}' # Zeile wieder säubern
    [ $ret -eq 0 -o $ipv -eq 4 ]&&[ "$verb" ]&&printf "Command/Befehl: $blau%b$reset\nRueckmeldung:\n$rot%b$reset" "$befehl" "$(cat protok)"
    # printf "Seifenaktion: "'SoapAction: '$serviceType'#'$Action 
    [ "$erg" ]&&[ "$verb" ]&&printf "\nReturn/Rueckgabe: \n$blau$erg$reset\n";
    case $erg in *.lua*)
      nurl=$(echo "$erg"|awk '/\.lua/{print gensub(/^[^>]*>([^<]*)<.*/,"\\1","1")}')
      case $nurl in *://*);;*)nurl=$FB$nurl;;esac
      [ "$verb" ]&&printf "New/Neue Url:\n$blau$nurl$reset\n";
      befehl="curl -m 20 \"$nurl\" 2>protok|eval "$filter" >\"$Ausgabe\"";# "--connect-timeout 1" schuetzt leider nicht vor Fehler 606 bei ipv4 # oder |tee
      [ "$verb" ]&&printf "$befehl\n";
      eval $befehl;
      ret=$?;
      awk 'BEGIN {while (c++<100) printf " ";printf "\r";}' # Zeile wieder säubern
      [ "$verb" ]&&\
        printf "its return/deren Rueckgabe: $blau$ret$reset (Result/Ergebnis in: $blau$Ausgabe$reset)\nRueckmeldung:\n$rot%b$reset\n" "$(cat protok)"
      [ "$ret" -eq 0 ]&&break;
      ;;
      *) [ "$ret" -eq 0 ]&&break;;
    esac;
  done;
}

# hier geht's los
obneu=0; # Fritzboxbenutzer und Passwort neu eingeben
while [ $# -gt 0 ]; do
	para="$1";
	case $para in
		-neu|-new) obneu=1;;
    -pcs|-nur|-bloß|-only) pcs=$2;; # kann komma-getrennte Liste zu weckender Geräte sein
		-zeig|-show|--zeig|--show) zeig=1;; # zeigt nur die Liste der PCs an
    -only*|-bloß*) pcs=$(echo "$para"|awk '{print gensub(/["'\''](.*)["'\'']/,"\\1",1,substr($0,6))}');; # Anführungszeichen und Parameternamen entfernen
    -v|--verbose) verb=1;;
    -h|--h|--hilfe|-hilfe|-?|/?|--?)
      printf "$blau$0 [-neu] [-bloß|-only[ ]<Mac-Adresse1>[,Mac-Adresse2...]] [-zeig] [-v|--verbose] [-h|--hilfe|-?]$reset\n";
      printf "  $blau-neu$reset: frägt Fritzboxbenutzer und -passwort neu ab\n";
      printf "  $blau-bloß$reset: versucht bloß die PCs mit den angegebenen statt allen Mac-Adressen zu wecken\n";
			printf "  $blau-zeig$reset: zeigt nur die Liste der Geräte an\n";
    exit;;
    --help|-help)
      printf "$blau$0 [-new] [-only[ ]<Mac-Address1>[,Mac-Address2...]] [-show] [-v|--verbose] [-h|--hilfe|-help]$reset\n";
      printf "  $blau-new$reset: asks again for the fritz box user und password\n";
      printf "  $blau-only$reset: tries to wake up only the pcs with the specified mac-addresses instead of all \n";
			printf "  $blau-show$reset: shows only the list of the devices\n";
    exit;;
	esac
	[ "$verb" ]&&printf Parameter: "$blau$para$reset\n";
	shift;
done;
# Autorisierung ggf. festlegen
credfile="$(getent passwd $(logname)|cut -d: -f6)/.tr64cred"; # ~  # $HOME
crede=$(cat $credfile 2>/dev/null);
if [ -z "$crede" -o $obneu = 1 ]; then
	 printf "Please enter the fritz box user/Bitte Fritzboxbenutzer eingeben: ";read fbuser;
	 printf "Please enter the password for/Bitte Passwort für $blau$fbuser$reset eingeben: ";read fbpwd;
	 crede="$fbuser:$fbpwd";
	 printf "$crede" >"$credfile";
fi;
# Parameter für beide Abfragen (Liste der Geräte abfragen und Geräte wecken)
controlURL=hosts
serviceType=Hosts:1
# 1) ggf. Liste aller Geräte abfragen
if [ -z "$pcs" ];then
  Action=X_AVM-DE_GetHostListPath
  ParIn=
  Inhalt=
	# XML parsen: Zeilen aus Mac,IP und Hostname erstellen; aus Gründen der Übersichtlichkeit wird hier sed verwendet; Kommentare sind dort leider schlecht möglich
	filter="\"{ I=IPAddress;M=MACAddress;H=HostName;sed -n '/'\\\$I'>/{s/<'\\\$I'>\(.*\)<\/'\\\$I'>/\\\\1/;h};/'\\\$I' \/>/{s/.*//;x;b;};/'\\\$M'>/{s/<'\\\$M'>\(.*\)<\/'\\\$M'>/\\\\1/;G;s/\\\\n/ /;h};/'\\\$M' \/>/{s/.*//;x;b;};/'\\\$H'/{x;/^$/b;x;s/<'\\\$H'>\(.*\)<\/'\\\$H'>/\\\\1/;H;x;s/\\\\n/ /p;}';}\""; 
  fragab "$filter";
fi;
if [ "$zeig" ];then
  awk '{printf "%i: '$blau'%s '$lila'%s '$blau'%s'$reset'\n",z++,$1,$2,$3;}' $Ausgabe;
	exit;
fi;
# 2) (alle) Gerät(e) wecken
Action=X_AVM-DE_WakeOnLANByMACAddress
ParIn=NewMACAddress
if [ "$pcs" ];then
	# Parameter in Mac-Adressen umwandeln
	bloss=
	for pc in $(echo "$pcs"|sed 's/,/ /g');do
		bloss="$bloss "$(sed '/'$pc'/!d;s/ .*//' $Ausgabe);
	done;
	# diese wecken
  for Inhalt in $bloss;do
   printf "${lila}Waking up/Wecke$reset: $blau$Inhalt$reset\n";
   fragab;
  done;
else
	# alle wecken
  zahl=0;
  geszahl=$(wc -l <$Ausgabe);
  while read -r zeile; do
    zahl=$(printf $zahl|awk '{print $0+1}');
    printf "${lila}Waking up/wecke ($zahl/$geszahl)$reset: $blau$zeile$reset\n";
    for Inhalt in $zeile; do # bis zum ersten Leerzeichen= Mac-Adresse
      fragab;
      break;
    done;
  done << EOF
$(cat $Ausgabe)
EOF
# $(eval $befehl)
fi;
