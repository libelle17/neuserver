#!/bin/sh
# versucht (alle) PCs an der Fritzbox zu wecken; 
# zusammengeschrieben von/written together by: Gerald Schade 6.4.2019

vorgaben() {
# eher veränderbare Vorgaben
	Ausgabe=ergtr64.txt;
	listenintervall=7; # alle $listenintervall Tage wird $Ausgabe erneuert
	curlmaxtime=20;
	# IFerl="802.11,Ethernet,-"; # erlaubte Interfaces
	IFverb="802.11"; #verbotene Interfaces
# eher starre Vorgaben
	blau="\033[1;34m";
	rot="\033[1;31m";
	lila="\033[1;35m";
	reset="\033[0m";
	FBadn="fritz.box 169.254.1.1";
# Parameter für fragab: für beide tr-064-Abfragen (geraeteliste und wecken)
	controlURL=hosts
	serviceType=Hosts:1
# for FB in $FBadn;do curl http://$FB:49000/tr64desc.xml 2>/dev/null&&break;done;exit; # Möglichkeiten von tr-064 anzeigen
}

# Funktion für ein bis zwei TR-064-Abfragen
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
		for adr in $FBadn;do
			FB=http://$adr:49000;
			printf "Trying/versuche ipv$ipv\r";
			befehl="curl -$ipv -k --anyauth -u \"$crede\" \\n\
						-H \"Content-Type: text/xml; charset=utf-8\" \\n\
						-H \"SoapAction: $serviceType#$Action\" \\n\
						\"$FB$controlURL\" \\n\
						-d '$XML'";
			erg=$(eval $(echo $befehl|sed 's/\\n//g;s/\\t//g') 2>protok);
			ret=$?;
			awk 'BEGIN {while (c++<100) printf " ";printf "\r";}' # Zeile wieder säubern
			[ $ret -ne 0 ]&&continue; # z.B. fritz.box konnte nicht aufgelöst werden
			[ $ret -eq 0 -o $ipv -eq 4 ]&&[ "$verb" ]&&printf "Command/Befehl: $blau%b$reset\nRueckmeldung:\n$rot%b$reset\n" "$befehl" "$(cat protok)"
			# printf "Seifenaktion: "'SoapAction: '$serviceType'#'$Action 
			[ "$erg" ]&&[ "$verb" ]&&printf "\nReturn/Rueckgabe: \n$blau$erg$reset\n";
			case $erg in *.lua*)
				nurl=$(echo "$erg"|awk '/\.lua/{print gensub(/^[^>]*>([^<]*)<.*/,"\\1","1")}')
				case $nurl in *://*);;*)nurl=$FB$nurl;;esac
				[ "$verb" ]&&printf "New/Neue Url:\n$blau$nurl$reset\n";
				befehl="curl -m $curlmaxtime \"$nurl\" 2>protok|eval "$filter" >\"$Ausgabe\"";# "--connect-timeout 1" schuetzt leider nicht vor Fehler 606 bei ipv4 # oder |tee
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
	 [ $ret -eq 0 ]&&break;
  done;
}

# Befehlszeilenparameter auswerten
commandline() {
	obneu=0; # 1=Fritzboxbenutzer und Passwort neu eingeben
	while [ $# -gt 0 ]; do
		para="$1";
		case $para in
			-neu|-new) obneu=1;;
			-pcs|-nur|-bloß|-only) pcs=$2;; # kann komma-getrennte Liste zu weckender Geräte sein
			-zeig|-show|--zeig|--show) zeig=1;; # zeigt nur die Liste der PCs an
			-only*|-bloß*) pcs=$(echo "$para"|awk '{print gensub(/["'\''](.*)["'\'']/,"\\1",1,substr($0,6))}');; # Anführungszeichen und Parameternamen entfernen
			-erl|-all|--erlaubt|--allowed) IFverb=;IFerl=$2;; # erlaubte Interfaces neu festlegen, dazu keine verbieten
			-erl*|-all*) IFverb=;IFerl=$(echo "$para"|awk '{print gensub(/["'\''](.*)["'\'']/,"\\1",1,substr($0,4))}');; # erlaubte Interfaces neu festlegen
			--erlaubt*|--allowed*) IFverb=;IFerl=$(echo "$para"|awk '{print gensub(/["'\''](.*)["'\'']/,"\\1",1,substr($0,10))}');; # erlaubte Interfaces neu festlegen
			-verbo|-forbi|--verboten|--forbidden) IFverb=$2;; # verbotene Interfaces neu festlegen
			-verbo*|-forbi*) IFverb=$(echo "$para"|awk '{print gensub(/["'\''](.*)["'\'']/,"\\1",1,substr($0,6))}');; # verbotene Interfaces neu festlegen
			--verboten*) IFverb=$(echo "$para"|awk '{print gensub(/["'\''](.*)["'\'']/,"\\1",1,substr($0,11))}');; # verbotene Interfaces neu festlegen
			--forbidden*) IFverb=$(echo "$para"|awk '{print gensub(/["'\''](.*)["'\'']/,"\\1",1,substr($0,12))}');; # verbotene Interfaces neu festlegen
			--alteliste|--oldlist) alteliste=1;;
			-v|--verbose) verb=1;;
			-h|--h|--hilfe|-hilfe|-?|/?|--?)
				printf "$blau$0 [-neu] [-bloß[ ]<PC1>[,PC2...]] [-verbo[ ]<Interface1>[,Interface2...]] [-erl[ ]<Interface1>[,Interface2...]] [-zeig] [--alteliste] [-v] [-h|--hilfe|-?]$reset\n";
				printf "  $blau-neu$reset: frägt Fritzboxbenutzer und -passwort neu ab\n";
				printf "  $blau-bloß$reset: versucht bloß die angegebenen PCs (Mac,IP,Hostname,Interface) statt alle zu wecken\n";
				printf "  $blau-verbo$reset: berücksichtigt die mit Komma getrennten Interfaces nicht ('-' für leeres Interface)\n";
				printf "  $blau-erl$reset: berücksichtigt allenfalls die mit Komma getrennten Interfaces\n";
				printf "  $blau-zeig$reset: zeigt nur die Liste der Geräte an\n";
				printf "  $blau--alteliste$reset: aktualisiert die Geräteliste seltener\n";
			exit;;
			--help|-help)
				printf "$blau$0 [-new] [-only[ ]<pc1>[,pc2...]] [-forbi[ ]<Interface1>[,Interface2...]] [-all[ ]<Interface1>[,Interface2...]] [-show] [--oldlist] [-v] [-h|--hilfe|-help]$reset\n";
				printf "  $blau-new$reset: asks again for the fritz box user und password\n";
				printf "  $blau-only$reset: tries to wake up only the specified pcs (Mac,ip,hostname,interface) instead of all\n";
				printf "  $blau-forbi$reset: ignores the comma separated interfaces ('-' for empty interface)\n";
				printf "  $blau-all$reset: doesn't allow other than the comma separated interfaces\n";
				printf "  $blau-show$reset: shows only the list of the devices\n";
				printf "  $blau--oldlist$reset: updates the list of the devices not so often\n";
			exit;;
		esac
		[ "$verb" ]&&printf Parameter: "$blau$para$reset\n";
		shift;
	done;
	if [ "$verb" ];then
		printf "allowed/erlaubte Interfaces: $blau$IFerl$reset\n";
		printf "forbidden/verbotene Interfaces: $blau$IFverb$reset\n";
	fi;
}

# Autorisierung ermitteln/festlegen
authorize() {
	credfile="$(getent passwd $(logname 2>/dev/null||whoami)|cut -d: -f6)/.tr64cred"; # ~  # $HOME
	crede=$(cat $credfile 2>/dev/null);
	if [ -z "$crede" -o $obneu = 1 ]; then
		 printf "Please enter the fritz box user/Bitte Fritzboxbenutzer eingeben: ";read fbuser;
		 printf "Please enter the password for/Bitte Passwort für $blau$fbuser$reset eingeben: ";read fbpwd;
		 crede="$fbuser:$fbpwd";
		 printf "$crede" >"$credfile";
	fi;
}

# Liste aller von der Fritzbox gemerkten Geräte ggf. abfragen und in $Ausgabe speichern
geraeteliste() {
	  if [ -z "$alteliste" ]; then
			neueliste=1;
		elif ! find . -mtime -$listenintervall -name "$Ausgabe"|grep -q .; then
			neueliste=1;
		fi;
	  if [ "$neueliste" ]; then
			Action=X_AVM-DE_GetHostListPath;
			ParIn=;
			Inhalt=;
			# XML parsen: Zeilen aus Mac,IP und Hostname erstellen; sed wird natürlich aus Gründen der Übersichtlichkeit verwendet;
			filter="\"{ I=IPAddress;M=MACAddress;H=HostName;T=InterfaceType;sed -n '/'\\\$I'>/{s/<'\\\$I'>\(.*\)<\/'\\\$I'>/\\\\1/;h};" # Namen angeben, IP-Adresse ins hold-Register stellen
			filter=$filter"/'\\\$I' \/>/{s/.*//;x;b;};" # falls keine IP-Adresse angegeben, dann hold-Register (von der letzten Zeile her noch) löschen
			filter=$filter"/'\\\$M'>/{s/<'\\\$M'>\(.*\)<\/'\\\$M'>/\\\\1/;G;s/\\\\n/ /;h};" # Mac-Adresse im pattern-Register merken und die IP-Adresse anhängen, Zeilenumbruch entfernen
			filter=$filter"/'\\\$M' \/>/{s/.*//;x;b;};" # Mac-Zeile ohne Mac-Adresse: Hold-Register löschen
			filter=$filter"/'\\\$H'/{x;/^$/{x;b;};x;s/<'\\\$H'>\(.*\)<\/'\\\$H'>/\\\\1/;H;};" # Host-Zeile: falls Hold-Register leer, weiter, sonst Hostname anhängen
			filter=$filter"/<'\\\$T'/{"; # Zeile, die <InterfaceType enthält
			filter=$filter"x;/^$/b;x;" # falls Hold-Register leer, Zeile auslassen
			filter=$filter"/<'\\\$T' \/>/{"; # falls diese Zeile einen leeren Interface-Typ enthält
			case "$IFverb" in *-*) # wenn IFverb '-' als Symbol für leeres Interface enthält
				filter=$filter"b;";; # dann Zeile auslassen
				*)
				case "$IFerl" in ""|*-*) # wenn IFerl leer oder '-' als Symbol für leeres Interface angegeben wurde
					filter=$filter"s/.*/-/;H;x;s/\\\\n/ /g;p;";; # dann '-' als Symbol für leeres Interface anhängen und drucken	
					*) filter=$filter"b;";; # sonst Zeile auslassen
				esac;;
			esac;
			filter=$filter"};"; # Ende leerer Interface-Typ
			# wenn Interfacetyp bei IFverb dabei, dann Zeile auslassen
			[ "$IFverb" ]&&filter=$filter"/\\\("$(echo $IFverb|sed 's/,/\\\|/g')"\\\)</b;" 
			# wenn dieser bei IFerl dabei, dann diesen bereinigt an Hold-Register anhängen, dieses holen, Zeilenumbruch entfernen, drucken
			filter=$filter"/\\\("$(echo $IFerl|sed 's/,/\\\|/g')"\\\)</{s/<'\\\$T'>\(.*\)<\/'\\\$T'>/\\\\1/;H;x;s/\\\\n/ /g;p;};" 
			filter=$filter"};"; # Ende Zeile, die <InterfaceType enthält
			filter=$filter"';}\"";  # o.g. shell-Block abschließen, der die Variablendefinition enthält
		# fragab;exit; # fragab ohne filter würde die ganze xml-Datei erzeugen
			fragab "$filter"; # der fertige Filter wird mit -v angezeigt
  	fi;
		if [ "$zeig" ];then # zeigt die Liste an
			awk '{printf "%i: '$blau'%s '$lila'%s '$blau'%s '$lila'%s'$reset'\n",z++,$1,$2,$3,$4}' $Ausgabe;
			exit;
		fi;
}

# alle oder gewünschte Geräte wecken
wecken() {
	Action=X_AVM-DE_WakeOnLANByMACAddress
	ParIn=NewMACAddress
	# wecken
	zahl=0;
	geszahl=$(wc -l <$Ausgabe);
	pcs=$(echo "$pcs"|sed 's/,/ /g');
	[ -f "$Ausgabe" ]||{ printf "File/Datei $blau$Ausgabe$reset not found/nicht gefunden\n";exit;};
	[ -s "$Ausgabe" ]||{ printf "File/Datei $blau$Ausgabe$reset empty/leer\n";exit;};
	while read -r zeile; do
		[ "$pcs" ]&&{ gefu=;for pc in $pcs;do echo $zeile|sed -n '/'$pc'/q1'||{ gefu=1;break;};done;[ "$gefu" ]||continue;}; # falls pcs angegeben, dann danach filtern
		zahl=$(printf $zahl|awk '{print $0+1}');
		printf "${lila}Waking up/wecke ($zahl/$geszahl)$reset: $blau$zeile$reset\n";
		for Inhalt in $zeile; do # bis zum ersten Leerzeichen = Mac-Adresse
			fragab;
			break;
		done;
	done << EOF
$(cat $Ausgabe)
EOF
}

# hier geht's los
vorgaben;
commandline "$@";
authorize;
geraeteliste;
wecken;