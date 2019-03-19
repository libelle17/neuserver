#!/bin/bash
blau="\e[1;34m";
reset="\e[0m";
FB="http://fritz.box:49000"
Ausgabe=neueurl.xml
# curl $FB/tr64desc.xml

controlURL=/igdupnp/control/WANCommonIFC1
serviceType=urn:schemas-upnp-org:service:WANCommonInterfaceConfig:1
Action=GetCommonLinkProperties
ParIn=

controlURL=x_storage
serviceType=X_AVM-DE_Storage:1
Action=GetInfo
ParIn=

controlURL=x_contact
serviceType=X_AVM-DE_OnTel:1
Action=GetCallList
ParIn=

controlURL=deviceconfig
serviceType=DeviceConfig:1
Action=X_AVM-DE_CreateUrlSID
ParIn=

controlURL=hosts
serviceType=Hosts:1
Action=X_AVM-DE_GetHostListPath
ParIn=

controlURL=x_voip
serviceType=X_VoIP:1
Action=X_AVM-DE_DialNumber
ParIn=NewX_AVM-DE_PhoneNumber
Inhalt="616380";

controlURL=x_filelinks
serviceType=X_AVM-DE_Filelinks:1
Action=GetFilelinkListPath
ParIn=

obneu=0; # Fritzboxbenutzer und Passwort neu eingeben
while [ $# -gt 0 ]; do
	para="$1";
	case $para in
		-neu) obneu=1;;
		-c)  controlURL="$2";shift;; # das mit den Anführungszeichen unten war eine Gratis-Übung: Bash und Dash streichen sie selbst ...
		-c*) controlURL=$(echo "$para"|awk '{print gensub(/["'\''](.*)["'\'']/,"\\1",1,substr($0,3))}');;# alles hinter -c ohne Anführungszeichen; einleitd.Leerz.verboten
		-s)  serviceType="$2";shift;;
		-s*) serviceType=$(echo "$para"|awk '{print gensub(/["'\''](.*)["'\'']/,"\\1",1,substr($0,3))}');;
		-a)  Action="$2";shift;;
		-a*) Action=$(echo "$para"|awk '{print gensub(/["'\''](.*)["'\'']/,"\\1",1,substr($0,3))}');; 
	esac
	echo $para;
	shift;
done;

case $controlURL in /*);;*) controlURL=/upnp/control/$controlURL;;esac;
case $serviceType in urn:*);;*) serviceType=urn:dslforum-org:service:$serviceType;;esac;
printf "controlURL: $blau$controlURL$reset\n"
printf "serviceType: $blau$serviceType$reset\n"
printf "Action: $blau$Action$reset\n"
[ -n "$ParIn" ]&&printf "Parin: $blau$ParIn$reset\n";
[ -n "$Inhalt" ]&&printf "Inhalt: $blau$Inhalt$reset\n";

credfile="$(getent passwd $(logname)|cut -d: -f6)/.tr64cred"; # ~  # $HOME
crede=$(cat $credfile 2>/dev/null);
if [ -z "$crede" -o $obneu = 1 ]; then
	 printf "Bitte Fritzboxbenutzer eingeben: ";read fbuser;
	 printf "Bitte Passwort für $blau$fbuser$reset eingeben: ";read fbpwd;
	 crede="$fbuser:$fbpwd";
	 printf "$crede" >"$credfile";
fi;

Soap="http://schemas.xmlsoap.org/soap";
XML='<?xml version="1.0" encoding="utf-8"?>
<s:Envelope s:encodingStyle="'$Soap'/encoding/" xmlns:s="'$Soap'/envelope/">
  <s:Body><u:'$Action' xmlns:u="'$serviceType'"'
[ -n "$ParIn" ]&&XML=$XML'><'$ParIn'>'${Inhalt}'</'$ParIn'></u:'$Action'>'||XML=$XML' />'
XML=$XML'</s:Body>\n</s:Envelope>' # mit neue-Zeile-Zeichen nach <s:Body> ging anrufen nicht
printf "XML derAbfrage: \n$blau$XML$reset\n"

for ipv in 6 4;do
erg=$(curl -$ipv -k --anyauth -u "$crede"                                   \
  "$FB$controlURL"                                     \
  -H 'Content-Type: text/xml; charset="utf-8"'                           \
  -H 'SoapAction: '$serviceType'#'$Action \
	-d "$XML";printf "\n") # 2>/dev/null zur Unterdrueckung der Verbindungsgeschwindigkeitsausgabe
# printf "Seifenaktion: "'SoapAction: '$serviceType'#'$Action 
printf "\nRueckgabe: \n$blau$erg$reset\n";
ret=1;
case $erg in *.lua*)
	nurl=$(echo "$erg"|awk '/\.lua/{print gensub(/^[^>]*>([^<]*)<.*/,"\\1","1")}')
	case $nurl in *://*);;*)nurl=$FB$nurl;;esac
	printf "Neue Url:\n$blau$nurl$reset\n";
	curl -m 20 "$nurl" > $Ausgabe # "--connect-timeout 1" schuetzt leider nicht vor Fehler 606 bei ipv4 # oder |tee
	ret=$?;
	printf "\nAbfrageergebnis der neuen Url: $blau$ret$reset (Ergebnis in: $blau$Ausgabe$reset)\n"
	[ "$ret" -eq 0 ]&&break;
	;;
	*)break;;
esac;
done;


#netcat -4 fritz.box 1012

