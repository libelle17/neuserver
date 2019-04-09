#!/bin/sh
# versucht (alle) PCs an der Fritzbox zu wecken; 
# zusammengeschrieben von/written together by: Gerald Schade 6.4.2019

vorgaben() {
# eher veränderbare Vorgaben
	Ausgabe=ergtr64.txt;
	listenintervall=7; # alle $listenintervall Tage wird $Ausgabe erneuert
	curlmaxtime=40;
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
				for faktor in "" 0 00; do # wenn die Zeit nicht reicht, dann verzehnfachen
					befehl="curl -m ${curlmaxtime}$faktor \"$nurl\" 2>protok|eval "$filter" >\"$Ausgabe\"";# "--connect-timeout 1" schuetzt leider nicht vor Fehler 606 bei ipv4 # oder |tee
					[ "$verb" ]&&printf "$befehl\n";
					eval $befehl;
					ret=$?;
					[ "$verb" ]&&awk 'BEGIN {while (c++<100) printf " ";printf "\r";}' # Zeile wieder säubern
					[ -s "$Ausgabe" ]&&break;
  			done;
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
      -nicht|-not|--nicht|--not) npc=$2;shift;; # kann komma-getrennte Liste nicht zu weckender Geräte sein
			-not*) npc=$(echo "$para"|awk '{print gensub(/["'\''](.*)["'\'']/,"\\1",1,substr($0,5))}');; 
			-nicht*) npc=$(echo "$para"|awk '{print gensub(/["'\''](.*)["'\'']/,"\\1",1,substr($0,7))}');; 
#			-pcs|-nur|-bloß|-only|--pcs|--nur|--bloß|--only) pcs=$2;shift;; # kann komma-getrennte Liste zu weckender Geräte sein
#			-pcs*|-nur*) pcs=$(echo "$para"|awk '{print gensub(/["'\''](.*)["'\'']/,"\\1",1,substr($0,5))}');; # Anführungszeichen und Parameternamen entfernen
#			-only*|-bloß*) pcs=$(echo "$para"|awk '{print gensub(/["'\''](.*)["'\'']/,"\\1",1,substr($0,6))}');; 
			-erl|-all|--erlaubt|--allowed) IFverb=;IFerl=$2;shift;; # erlaubte Interfaces neu festlegen, dazu keine verbieten
			-erl*|-all*) IFverb=;IFerl=$(echo "$para"|awk '{print gensub(/["'\''](.*)["'\'']/,"\\1",1,substr($0,5))}');; # erlaubte Interfaces neu festlegen
			--erlaubt*|--allowed*) IFverb=;IFerl=$(echo "$para"|awk '{print gensub(/["'\''](.*)["'\'']/,"\\1",1,substr($0,10))}');;
			-verbo|-forbi|--verboten|--forbidden) IFverb=$2;shift;; # verbotene Interfaces neu festlegen
			-verbo*|-forbi*) IFverb=$(echo "$para"|awk '{print gensub(/["'\''](.*)["'\'']/,"\\1",1,substr($0,6))}');; # verbotene Interfaces neu festlegen
			--verboten*) IFverb=$(echo "$para"|awk '{print gensub(/["'\''](.*)["'\'']/,"\\1",1,substr($0,11))}');; # verbotene Interfaces neu festlegen
			--forbidden*) IFverb=$(echo "$para"|awk '{print gensub(/["'\''](.*)["'\'']/,"\\1",1,substr($0,12))}');; # verbotene Interfaces neu festlegen
			-zeig|-show|--zeig|--show) zeig=1;; # zeigt nur die Liste der PCs an
			-zeigu|-showu|--zeigu|--showu) zeig=1;ungefiltert=1;; # zeigt nur die Liste der PCs an
			-al|-ol|--alteliste|--oldlist) alteliste=1;;
			-v|--verbose) verb=1;;
			-h|--h|--hilfe|-hilfe|-?|/?|--?)
				printf "$blau$0 [-neu] [-nicht[ ]<PC1>[,PC2...]] [<PC1>[,PC2...]] [-verbo[ ]<Interface1>[,Interface2...]] [-erl[ ]<Interface1>[,Interface2...]] [-zeig] [-al] [-v] [-h|--hilfe|-?]$reset\n";
				printf "  $blau-neu$reset: frägt Fritzboxbenutzer und -passwort neu ab\n";
        printf "  $blau-nicht$reset: spart die angegebenen PCs (Mac,IP,Hostname,Interface) aus\n";
				printf "  $blau[<PC1>[,PC2...]]$reset: versucht bloß die angegebenen PCs (Mac,IP,Hostname,Interface) statt alle zu wecken\n";
				printf "                    Wenn bloß MAC-Adressen angegeben werden, so arbeitet das Programm ohne Geräteliste (und schneller).\n";
				printf "  $blau-verbo$reset: berücksichtigt die mit Komma getrennten Interfaces nicht ('-' für leeres Interface)\n";
				printf "  $blau-erl$reset: berücksichtigt allenfalls die mit Komma getrennten Interfaces\n";
				printf "  $blau-zeig$reset: zeigt nur die Liste der Geräte an\n";
				printf "  $blau-al$reset: aktualisiert die Geräteliste seltener\n";
			exit;;
			--help|-help)
				printf "$blau$0 [-new] [-not[ ]<pc1>[,pc2...]] [<pc1>[,pc2...]] [-forbi[ ]<Interface1>[,Interface2...]] [-all[ ]<Interface1>[,Interface2...]] [-show] [-ol] [-v] [-h|--hilfe|-help]$reset\n";
				printf "  $blau-new$reset: asks again for the fritz box user und password\n";
        printf "  $blau-not$reset: excludes the specified pcs (Mac,IP,Hostname,Interface)\n";
				printf "  $blau[<pc1>[,pc2...]]$reset: tries to wake up only the specified pcs (Mac,ip,hostname,interface) instead of all\n";
				printf "                    If only MAC-addresses are given, the program works without the list of devices (and faster).\n";
				printf "  $blau-forbi$reset: ignores the comma separated interfaces ('-' for empty interface)\n";
				printf "  $blau-all$reset: doesn't allow other than the comma separated interfaces\n";
				printf "  $blau-show$reset: shows only the list of the devices\n";
				printf "  $blau-ol$reset: updates the list of the devices not so often\n";
			exit;;
			*) pcs="$para";;
		esac
		[ "$verb" ]&&printf "Parameter: $blau$para$reset\n";
		shift;
	done;
	[ "$npc" ]&&npc=$(echo "$npc"|sed 's/,/ /g');
	if [ "$pcs" ]; then 
		pcs=$(echo "$pcs"|sed 's/,/ /g');
		if [ -z "$zeig" ]; then
			nurmac=1; # nur MAC-Acressen angegeben => $Ausgabe muß nicht verwendet werden, geraeteliste nicht aufgerufen werden
			for pc in $pcs; do
				echo $pc|sed -n '/^[0-9a-fA-F]\{2\}:[0-9a-fA-F]\{2\}:[0-9a-fA-F]\{2\}:[0-9a-fA-F]\{2\}:[0-9a-fA-F]\{2\}:[0-9a-fA-F]\{2\}$/q1'&&{ nurmac=;break;}; # wenn $pc keine mac
			done;
		fi;
	fi;
	if [ "$verb" ]; then
		[ "$pcs" ]&&printf "pcs: $blau$pcs$reset\n";
		printf "nurmac: $blau$nurmac$reset\n";
		[ "$npc" ]&&printf "npc: $blau$npc$reset\n";
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
      # wenn Interfacetyp (außer -) bei IFverb dabei, dann Zeile auslassen
			[ "$IFverb" ]&&filter=$filter"/\\\("$(echo $IFverb|sed 's/-,//g;s/,*-//g;s/,/\\\|/g')"\\\)</b;" 
      # wenn dieser (außer -) bei IFerl dabei, dann diesen bereinigt an Hold-Register anhängen, dieses holen, Zeilenumbruch entfernen, drucken
			filter=$filter"/\\\("$(echo $IFerl|sed 's/-,//g;s/,*-//g;s/,/\\\|/g')"\\\)</{s/<'\\\$T'>\(.*\)<\/'\\\$T'>/\\\\1/;H;x;s/\\\\n/ /g;p;};" 
			filter=$filter"};"; # Ende Zeile, die <InterfaceType enthält
			filter=$filter"';}\"";  # o.g. shell-Block abschließen, der die Variablendefinition enthält
      if [ "$ungefiltert" ]; then
        fragab; # fragab ohne filter würde die ganze xml-Datei erzeugen
      else
        fragab "$filter"; # der fertige Filter wird mit -v angezeigt
      fi;
  	fi;
}

# alle oder gewünschte Geräte wecken
wecken() {
	Action=X_AVM-DE_WakeOnLANByMACAddress
	ParIn=NewMACAddress
	# wecken
	zahl=0;
	if [ "$nurmac" ]; then
		geszahl=$(echo "$pcs"|awk 'END{print NF}');
		for Inhalt in $pcs; do
		  zahl=$(printf $zahl|awk '{print $0+1}');
			printf "${lila}Waking up/wecke ($zahl/$geszahl)$reset: $blau$Inhalt$reset\n";
			fragab;
		done;
	else
		geszahl=$(wc -l <$Ausgabe);
		[ -f "$Ausgabe" ]||{ printf "File/Datei $blau$Ausgabe$reset not found/nicht gefunden\n";exit;};
		[ -s "$Ausgabe" ]||{ printf "File/Datei $blau$Ausgabe$reset empty/leer\n";exit;};
		while read -r zeile; do
			# falls pcs angegeben, dann danach filtern; falls '-' in pcs, dann ' -' verwenden, da '-' im hostname enthalten sein kann
			[ "$npc" ]&&{ gefu=;for pc in $npc;do [ $pc = "-" ]&&pc=" -";echo "$zeile"|sed -n "/$pc/q1"||{ gefu=1;break;};done;[ "$gefu" ]&&continue;}; 
			[ "$pcs" ]&&{ gefu=;for pc in $pcs;do [ $pc = "-" ]&&pc=" -";echo "$zeile"|sed -n "/$pc/q1"||{ gefu=1;break;};done;[ "$gefu" ]||continue;}; 
			zahl=$(printf $zahl|awk '{print $0+1}');
			if [ "$zeig" ];then # zeigt die Liste an
				echo "$zeile"|awk '{printf "'$zahl'/'$geszahl': '$blau'%s '$lila'%s '$blau'%s '$lila'%s'$reset'\n",$1,$2,$3,$4}';
			else
				printf "${lila}Waking up/wecke ($zahl/$geszahl)$reset: $blau$zeile$reset\n";
				for Inhalt in $zeile; do # bis zum ersten Leerzeichen = Mac-Adresse
					fragab;
					break;
				done;
			fi;
		done << EOF
$(cat $Ausgabe)
EOF
 fi;
}

# hier geht's los
vorgaben;
commandline "$@";
authorize;
[ -z "$nurmac" ]&&geraeteliste;
wecken;
