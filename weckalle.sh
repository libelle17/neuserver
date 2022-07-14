#!/bin/sh
# versucht, einen, mehrere oder alle PCs an der Fritzbox zu wecken; 
# zusammengeschrieben von/written together by: Gerald Schade 6.4.2019
# verwendet Tr-064 zur Kommunikation mit der Fritzbox (zum Aufwecken angeschlossener PCs und ggf. vorherigem Abfragen deren hierfür nötigen MAC-Adressen)

vorgaben() {
# vom Programmaufruf abhängige Parameter
  meingespfad="$(readlink -f "$0")"; # Name dieses Programms samt Pfad
  meinpfad="$(dirname $meingespfad)"; # Pfad dieses Programms ohne Name
  # Spaltenzahl des Bildschirms
  spzahl=50;# Vorgabe, falls kein Terminal (wie in cron)
  test -t 0 && spzahl=$(stty -a <$(tty)|sed -n 's/.*columns \([0-9]\+\).*/\1/;Ta;p;:a'); # um nicht zu schreiben: ..|grep -Po '(?<=columns )\d+'
# eher veränderbare Vorgaben:
  lgv=/var/log; # log-Verzeichnis
	ausgdt=$lgv/ergtr64.txt; # Ausgabe der aktuellen geraeteliste()-Abfrage
	[ -f "$ausgdt" -a ! -w "$ausgdt" ]&&sudo rm "$ausgdt" # wenn die Datei schon da ist und nicht beschreibbar, dann loeschen
	gesausdt=$lgv/gestr64.txt; # Vereinigungsmenge aller geraeteliste()-Abfragen (notwendig, da einige Anfragen unvollständige Ergebnisse liefern!)
	[ -f "$gesausdt" -a ! -w "$gesausdt" ]&&sudo chown $(whoami):users "$gesausdt" # wenn die Datei schon da ist und nicht beschreibbar, dann das ändern
	logdt=$lgv/logtr64.txt; # log-Datei für TR-064-Abfragen
	[ -f "$logdt" -a ! -w "$logdt" ]&&sudo rm "$logdt" # wenn die Datei schon da ist und nicht beschreibbar, dann loeschen
	listenintervall=7; # mit Parameter -al wird alle $listenintervall Tage die geraeteliste (in $gesausdt) durch eine neue TR-064-Abfrage ergänzt, 0 = nie
  loeschintervall=0; # Intervall in Tagen zum Löschen (und Neuerstellen) von $gesausdt, 0 = nie
	curlmaxtime=20; # maximale ms für 2. curl-Befehl (Abfrage der lua-Adresse aus dem 1.Befehl), wird bei Erfolglosigkeit automatisch erweitert
	IFerlau=; # IFerlau="802.11,Ethernet,-"; # erlaubte Interfaces (kommagetrennt ohne Leerzeichen)
	IFverbo=; # IFverbo="802.11"; # verbotene Interfaces (kommagetrennt ohne Leerzeichen)
# eher starre Vorgaben
	blau="\033[1;34m"; # für Programmausgaben
	rot="\033[1;31m";
	lila="\033[1;35m";
	reset="\033[0m"; # Farben zurücksetzen
  Pkt=" ......................................"; # als Tabulatorfüllzeichen für Tabellenausgabe
	FritzboxAdressen="fritz.box 169.254.1.1"; # wenn "fritz.box" nicht geht, dann geht "169.254.1.1"
# TR-064-Parameter für fragab(): für die beide Abfragen geraeteliste() und wecken()
	controlURL=hosts
	serviceType=Hosts:1
# Möglichkeiten von tr-064 anzeigen:
# for FB in $FritzboxAdressen;do curl http://$FB:49000/tr64desc.xml 2>/dev/null&&break;done;exit; 
}

# Funktion für eine oder (falls deren Rückgabe als http-Adresse für eine zweite verwendet werden muss) zwei TR-064-Abfragen
# Parameter: 1 (optional): sed-filter für die zweite Abfrage
fragab() {
	[ "$verb" ]&&printf "fragab($1)\n";
	if [ "$1" ];then filter="$1";else filter="sed -n p";fi; # ggf. leerer Filter
  case $controlURL in /*);;*) controlURL=/upnp/control/$controlURL;;esac; # ggf. immer gleiche Vorsilben ergänzen
  case $serviceType in urn:*);;*) serviceType=urn:dslforum-org:service:$serviceType;;esac; # ggf. immer gleiche Vorsilben ergänzen
  [ "$verb" ]&&printf "controlURL: $blau$controlURL$reset\n"; # im gesprächigen Modus tr-064-Parameter anzeigen ...
  [ "$verb" ]&&printf "serviceType: $blau$serviceType$reset\n";
  [ "$verb" ]&&printf "Action: $blau$Action$reset\n";
  [ "$verb" ]&&[ "$ParIn" ]&&printf "Parin: $blau$ParIn$reset\n"; # Parametername für Eingaben
  [ "$verb" ]&&[ "$Inhalt" ]&&printf "Inhalt: $blau$Inhalt$reset\n"; # dessen Inhalt
  Soap="http://schemas.xmlsoap.org/soap";
  XML='<?xml version="1.0" encoding="utf-8"?>
  <s:Envelope s:encodingStyle="'$Soap'/encoding/" xmlns:s="'$Soap'/envelope/">
    <s:Body><u:'$Action' xmlns:u="'$serviceType'"';
  [ "$ParIn" ]&&XML=$XML'><'$ParIn'>'${Inhalt}'</'$ParIn'></u:'$Action'>'||XML=$XML' />'
  XML=$XML'</s:Body>\n</s:Envelope>' # mit neue-Zeile-Zeichen nach <s:Body> ging anrufen nicht
  # printf "XML derAbfrage: \n$blau$XML$reset\n"
  for ipv in 4 6;do # der Reihe nach ipv4 und ipv6 versuchen
		for adr in $FritzboxAdressen;do
			FB=http://$adr:49000;
			printf "$blau$adr$reset, Action: $blau$Action $ParIn $Inhalt$reset, trying/versuche ${blau}ipv$ipv$reset";
      while true; do
        befehl="curl -$ipv -k --anyauth -u \"$crede\" \\n\
              -H \"Content-Type: text/xml; charset=utf-8\" \\n\
              -H \"SoapAction: $serviceType#$Action\" \\n\
              \"$FB$controlURL\" \\n\
              -d '$XML'";
        tufrag "$befehl" 1 "$FB$controlURL";
        [ $ret -ne 0 ]&&continue; # z.B. "fritz.box" konnte nicht aufgelöst werden
        # printf "Seifenaktion: "'SoapAction: '$serviceType'#'$Action 
        [ "$erg" ]&&[ "$verb" ]&&printf "Return/Rueckgabe: \n$blau$erg$reset\n";
        case "$erg" in 
           *Unauthorized*) 
             echo "Berechtigungsfehler bei Fritzbox-Abfrage: crede: $crede";
             obneu=1;
             authorize;;
           *) break;;
        esac;
      done;
			# wenn Ergebnis mit .lua zurückgeliefert wird, dann muss diese Adresse ...
			case $erg in *.lua*)
				neuurl=$(echo "$erg"|awk '/\.lua/{print gensub(/^[^>]*>([^<]*)<.*/,"\\1","1")}') # ... aus dem XML-Code herausgelöst werden ...
				case $neuurl in *://*);;*)neuurl=$FB$neuurl;;esac # ... ggf. um den Fritzbox-Namen erweitert werden ...
				[ "$verb" ]&&printf "New/Neue Url:\n$blau$neuurl$reset\n";
				for faktor in "" 0 00; do # wenn die Zeit nicht reicht, dann verzehnfachen
					# "--connect-timeout 1" schuetzt leider nicht vor Fehler 606 bei ipv4 # oder |tee
					befehl="curl -m ${curlmaxtime}$faktor \"$neuurl\" 2>"$logdt"|eval "$filter" >\"$ausgdt\"";
					printf "Folgeaufruf/Second call: ";
          tufrag "$befehl" "" "$neuurl" "$ausgdt"; # ... und dann nochmal mit curl aufgerufen werden
					[ -s "$ausgdt" ]&&break; # wenn Ausgabedatei in ${curlmaxtime}$faktor erstellt werden konnte
  			done;
				[ "$ret" -eq 0 ]&&break; # wenn nach 2. curl-Befehl in tufrag Fehlercode 0
				;;
				*) [ "$ret" -eq 0 ]&&break;; # wenn nach 1. curl-Befehl in tufrag Fehlercode 0
			esac;
	 done;
	 [ $ret -eq 0 ]&&break;
  done;
	[ "$verb" ]&&printf "Ende fragab()\n";
} # fragab

# die tatsächliche TR-064-Abfrage durchführen
# Parameter: 1: befehl, 2: umw (ob Befehl umgewandelt werden soll), 3: html-Adresse, 4: Datei, in die Ausgabe umgeleitet wurde
tufrag() {
  if [ "$verb" ]; then
    printf "\nBefehl/Command: $blau%b$reset\n" "$1";
  else
    printf ", url für/for tr-064: $blau$3$reset ...\r";
  fi;
  if [ "$2" ]; then
    befehl="$(echo "$1"|sed ':a;N;$!ba;s/\\n/ /g;s/\s\+/ /g')"; # Zeilenumbrüche und ggf. Tabulatoren entfernen
    [ "$verb" ]&&printf "%b\n" "$befehl";
  else
    befehl="$1";
  fi;
  erg=$(eval "$befehl" 2>"$logdt"); # hier wird der Befehl ausgeführt
  ret=$?;
  if [ "$verb" ]; then
    if [ "$4" ]; then
      printf " its return/dessen Rueckgabe: $blau$ret$reset\n";
      [ -s "$4" ]&&printf "(Ergebnis in: $blau$4$reset)\n"; # Ausgabedatei
    fi;
    printf "Ausgabe/output:\n$rot%b$reset\n" "$([ -f "$logdt" ]&&cat "$logdt"||echo ' (fehlt/missing)')";
  else
    awk 'BEGIN {while (c++<'$spzahl') printf " ";printf "\r";}' # Zeile wieder weitgehend säubern
  fi;
}


# Befehlszeilenparameter auswerten
commandline() {
	obneu=0; # 1=Fritzboxbenutzer und Passwort neu eingeben, s.u.
  obgrue=0; # 1=gruendlicher wecken, s.u.
	while [ $# -gt 0 ]; do
    para=$(echo "$1"|sed 's;^/;-;');
		case $para in
			-neu|-new) obneu=1;;
      -grue|-prof) obgrue=1;;
      -nicht|-not|--nicht|--not) npc=$2;shift;; # kann komma-getrennte Liste nicht zu weckender Geräte sein
			-not*) npc=$(echo "$para"|awk '{print gensub(/["'\''](.*)["'\'']/,"\\1",1,substr($0,5))}');; 
			-nicht*) npc=$(echo "$para"|awk '{print gensub(/["'\''](.*)["'\'']/,"\\1",1,substr($0,7))}');; 
			-erl|-all|--erlaubt|--allowed) IFverbo=;IFerlau=$2;shift;; # erlaubte Interfaces neu festlegen, dazu keine verbieten
			-erl*|-all*) IFverbo=;IFerlau=$(echo "$para"|awk '{print gensub(/["'\''](.*)["'\'']/,"\\1",1,substr($0,5))}');; # erlaubte Interfaces neu festlegen
			--erlaubt*|--allowed*) IFverbo=;IFerlau=$(echo "$para"|awk '{print gensub(/["'\''](.*)["'\'']/,"\\1",1,substr($0,10))}');;
			-verbo|-forbi|--verboten|--forbidden) IFverbo=$2;shift;; # verbotene Interfaces neu festlegen
			-verbo*|-forbi*) IFverbo=$(echo "$para"|awk '{print gensub(/["'\''](.*)["'\'']/,"\\1",1,substr($0,6))}');; # verbotene Interfaces neu festlegen
			--verboten*) IFverbo=$(echo "$para"|awk '{print gensub(/["'\''](.*)["'\'']/,"\\1",1,substr($0,11))}');; # verbotene Interfaces neu festlegen
			--forbidden*) IFverbo=$(echo "$para"|awk '{print gensub(/["'\''](.*)["'\'']/,"\\1",1,substr($0,12))}');; # verbotene Interfaces neu festlegen
			-zeig|-show|--zeig|--show) zeig=1;; # zeigt nur die Liste der PCs an
			-zeigu|-showu|--zeigu|--showu) zeig=1;ungefiltert=1;; # zeigt nur die Liste der PCs an
      -scan) scan=1;; # scannt nur die Geraete
			-al|-ol|--alteliste|--oldlist) alteliste=1;;
      -vi) obvi=1;;
			-v|--verbose) verb=1;;
			-h|--h|--hilfe|--help|-?|/?|--?)
        printf "Programm $blau$0$reset: versucht, einen, mehrere oder alle PCs an der Fritzbox zu wecken,\n";
        printf "  Aktuelle Geraeteliste: $blau$ausgdt$reset, Gesamtliste: $blau$gesausdt$reset, Log-Datei: $blau$logdt$reset\n";
        printf "  zusammengeschrieben von: Gerald Schade 6.4.2019\n";
        printf "  Benutzung:\n";
				printf "$blau$0 [-neu] [-grue] [-nicht[ ]<PC1>[,PC2...]] [<PC1>[,PC2...]] [-verbo[ ]<Interface1>[,Interface2...]] [-erl[ ]<Interface1>[,Interface2...]] [-zeig] [-al] [-vi] [-v] [-h|--hilfe|-?]$reset\n";
				printf "  $blau-neu$reset: frägt Fritzboxbenutzer und -passwort neu ab\n";
        printf "  $blau-grue$reset: weckt gruendlicher (alle MAC, die je seit Beginn der Aufzeichnungen diese/n IP/Namen hatten\n";
        printf "  $blau-nicht$reset: spart die angegebenen PCs (Mac,IP,Hostname,Interface) aus\n";
				printf "  $blau[<PC1>[,PC2...]]$reset: versucht bloß die angegebenen PCs (Mac,IP,Hostname,Interface) statt alle zu wecken\n";
				printf "                    Wenn bloß MAC-Adressen angegeben werden, so arbeitet das Programm ohne Geräteliste (und schneller).\n";
				printf "  $blau-verbo$reset: berücksichtigt die mit Komma getrennten Interfaces nicht ('-' für leeres Interface)\n";
				printf "  $blau-erl$reset: berücksichtigt allenfalls die mit Komma getrennten Interfaces\n";
				printf "  $blau-zeig$reset: zeigt nur die Liste der Geräte an statt diese aufzuwecken\n";
				printf "  $blau-al$reset: aktualisiert die Geräteliste seltener\n";
				printf "  $blau-vi$reset: lädt die Gerätelisten und das Script in vi\n";
			exit;;
			--help|-help)
        printf "Program $blau$0$reset: tries to wake one, several or all pcs at a fritzbox,\n";
        printf "  written together by: Gerald Schade 6.4.2019\n";
        printf "  Usage:\n";
				printf "$blau$0 [-new] [-not[ ]<pc1>[,pc2...]] [<pc1>[,pc2...]] [-forbi[ ]<interface1>[,interface2...]] [-all[ ]<interface1>[,interface2...]] [-show] [-ol] [-v] [-h|--hilfe|-help]$reset\n";
				printf "  $blau-new$reset: asks again for the fritz box user und password\n";
        printf "  $blau-prof$reset: wakes up more profound (all MACs that ever since the beginning of the documentation hat this ip/name\n";
        printf "  $blau-not$reset: excludes the specified pcs (Mac,IP,Hostname,Interface)\n";
				printf "  $blau[<pc1>[,pc2...]]$reset: tries to wake only the specified pcs (Mac,ip,hostname,interface) instead of all\n";
				printf "                    If only MAC-addresses are given, the program works without the list of devices (and faster).\n";
				printf "  $blau-forbi$reset: ignores the comma separated interfaces ('-' for empty interface)\n";
				printf "  $blau-all$reset: doesn't allow other than the comma separated interfaces\n";
				printf "  $blau-show$reset: shows only the list of the devices instead of waking them\n";
				printf "  $blau-ol$reset: updates the list of the devices not so often\n";
				printf "  $blau-vi$reset: loads the device list and this script in vi\n";
			exit;;
			*) pcs="$para";;
		esac;
		[ "$verb" ]&&printf "Parameter: $blau$para$reset\n";
		shift;
	done;
	[ "$npc" ]&&npc=$(echo "$npc"|sed 's/,/ /g'); # Komma-Liste in Leerzeichen-getrennte Liste umwandeln
	if [ "$pcs" ]; then  # falls PCs angegeben
		pcs=$(echo "$pcs"|sed 's/,/ /g'); # Kommas durch Leerzeichen ersetzen
		if [ -z "$zeig" ]; then # mit zeigen gäbe obnurmac=1 keinen Sinn
			obnurmac=1; # nur MAC-Acressen angegeben => $ausgdt muß nicht verwendet werden, geraeteliste nicht aufgerufen werden
			for pc in $pcs; do  # jeden PC prüfen ...
				echo $pc|sed -n '/^[0-9a-fA-F]\{2\}:[0-9a-fA-F]\{2\}:[0-9a-fA-F]\{2\}:[0-9a-fA-F]\{2\}:[0-9a-fA-F]\{2\}:[0-9a-fA-F]\{2\}$/q1'&&\
          { obnurmac=;break;}; # ... ob keine MAC-Adresse
			done;
		fi;
	fi;
	if [ "$verb" ]; then
		printf "obnurmac: $blau\"$obnurmac\"$reset\n";
		printf "pcs: $blau\"$pcs\"$reset\n";
		printf "npc: $blau\"$npc\"$reset\n";
		printf "allowed/erlaubte Interfaces: $blau\"$IFerlau\"$reset\n";
    printf "alteliste: $blau\"$alteliste\"$reset\n";
    printf "vi: $blau\"$vi\"$reset\n";
    printf "listenintervall [Tage]: $blau\"$listenintervall\"$reset\n";
		printf "forbidden/verbotene Interfaces: $blau\"$IFverbo\"$reset\n";
	fi;
  if [ "$obvi" ]; then
    vi $gesausdt $ausgdt $0 -p
    exit
  fi;
}

# Autorisierung ermitteln/festlegen
authorize() {
	# in $credfile werden in dem Verzeichnis, in dem auch private SSH-Schlüssel untergebracht sind, Benutzer und Passwort für die Fritzbox gespeichert
  # auf mint geht logname nicht mehr, dafür Ersatzbefehl
	credfile="$(getent passwd $(logname 2>/dev/null||loginctl user-status|sed -n '1s/\(.*\) .*/\1/p'||whoami)|cut -d: -f6)/.tr64cred"; # ~  # $HOME
	crede=$(cat $credfile 2>/dev/null); # der Inhalt von crede
	if [ -z "$crede" -o $obneu = 1 ]; then # falls Inhalt leer oder erneuert werden soll ...
		 printf "Please enter the fritz box user/Bitte Fritzboxbenutzer eingeben: ";read fbuser;
		 printf "Please enter the password for/Bitte Passwort für $blau$fbuser$reset eingeben: ";read fbpwd;
		 crede="$fbuser:$fbpwd";
		 printf "$crede" >"$credfile";
	fi;
}

# Liste aller von der Fritzbox gemerkten Geräte ggf. abfragen und in $ausgdt speichern
geraeteliste() {
	  if [ -z "$alteliste" ]; then # Befehlszeilenparaaltelistemeter, dass die zeitaufwendige Abfrage ausgelassen werden soll ...
      [ "$verb" ]&& printf "erstelle Liste neu, da Parameter 'alteliste' \"$alteliste\".\n";
			neueliste=1;
		elif [ "$listenintervall" != 0 ]; then # ... oder die alte Liste ist zu alt ...
			if ! find "$lgv" -mtime -$listenintervall -wholename "$ausgdt"|grep -q .; then # ob Datei mit Höchstalter an der Stelle zu finden ...
        [ "$verb" ]&& printf "erstelle Liste neu, da '${blau}listenintervall$reset' \"$blau$listenintervall$reset\" (Tage) und keine so junge \"$blau$ausgdt$reset\" gefunden.\n";
				neueliste=1;
			fi;
		fi;
	  if [ "$neueliste" ]; then
			Action=X_AVM-DE_GetHostListPath;
			ParIn=; # diese Abfrage hat keinen solchen Parameter
			Inhalt=;
      # XML parsen: Zeilen aus Mac,IP und Hostname erstellen; sed wird natürlich aus Gründen der Übersichtlichkeit verwendet :-)
      filter="\"{ I=IPAddress;M=MACAddress;H=HostName;T=InterfaceType;" # Variablen für XML-Namen angeben
      # IP-Adresse mit 15 Zeichen ins hold-Register stellen
      filter=$filter"sed -n '/'\\\$I'>/{s/<'\\\$I'>\(.*\)<\/'\\\$I'>/\\\\1/;s/$/              /;s/^\(.\{15\}\).*/\1/;h};" 
			filter=$filter"/'\\\$I' \/>/{s/.*/-              /;x;b;};" # falls keine IP-Adresse angegeben, dann "-" in hold-Register schreiben
      # Mac-Adresse im pattern-Register merken und die IP-Adresse anhängen, Zeilenumbruch entfernen
			filter=$filter"/'\\\$M'>/{s/<'\\\$M'>\(.*\)<\/'\\\$M'>/\\\\1/;G;s/\\\\n/ /;h};" 
			filter=$filter"/'\\\$M' \/>/{s/.*//;x;b;};" # Mac-Zeile ohne Mac-Adresse: Hold-Register löschen
      # Host-Zeile: falls Hold-Register leer, weiter, sonst Hostname mit 20 Zeichen anhängen
			filter=$filter"/'\\\$H'/{x;/^$/{x;b;};x;s/<'\\\$H'>\(.*\)<\/'\\\$H'>/\\\\1/;s/$/                             /;s/^\(.\{30\}\).*/\1/;H;};" 
			filter=$filter"/<'\\\$T'/{"; # Zeile, die <InterfaceType enthält
			filter=$filter"x;/^$/b;x;" # falls Hold-Register leer, Zeile auslassen
			filter=$filter"/<'\\\$T' \/>/{"; # falls diese Zeile einen leeren Interface-Typ enthält
      filter=$filter"s/.*/-/;H;x;s/\\\\n/ /g;p;" # dann '-' als Symbol für leeres Interface anhängen und drucken	
			filter=$filter"};"; # Ende leerer Interface-Typ
      # Interfacetyp bereinigt an Hold-Register anhängen, dieses holen, Zeilenumbruch entfernen, drucken
			filter=$filter"/<'\\\$T'>/{s/<'\\\$T'>\(.*\)<\/'\\\$T'>/\\\\1/;H;x;s/\\\\n/ /g;p;};" 
			filter=$filter"};"; # Ende Zeile, die <InterfaceType enthält
			filter=$filter"';}\"";  # o.g. shell-Block abschließen, der die Variablendefinition enthält
      if [ "$ungefiltert" ]; then # Debugging-Funktion, mit der die ganze XML-Datei in 
        fragab; # fragab ohne filter erzeugt die ganze xml-Datei in $ausgdt gespeichert wird
      else
        fragab "$filter"; # der fertige Filter wird mit -v unter "Befehl/command" nach ... eval  angezeigt
				# gesausdt alle $loeschintervall Tage löschen und ganz erneuern
				if [ "$loeschintervall" != 0 ]; then
					if ! find "$meinpfad" -mtime -$loeschintervall -wholename "$gesausdt"|grep -q .; then # wenn die Summendatei zu alt ist ...
						rm -f "$gesausdt"; # .. dann loeschen
					fi;
				fi;
				# neue Zeilen in Datei $ausgdt an $gesausdt anhängen, solche mit "-" als Netz durch andere ersetzen
        begz=$(echo $LINENO|awk '{print $0+1}');
        awk '
          function sortorder(i1,v1,i2,v2,li,re) { # Sortierfunktion für asort() kurz vor der Ausgabe
            split(v1,arr1," ");
            li=arr1[3]arr1[1]arr1[2]arr1[4];
            split(v2,arr2," ");
            re=arr2[3]arr2[1]arr2[2]arr2[4];
            if (li<re) return -1;
            if (li==re) return 0;
            return 1;
          }
          function liesein(var,datei) { # liest die bisherigen Datensätze (aus $gesausdt) abzgl. doppelter/abschließender Leerzeichen ein
            i=0;
            while ((getline zwi < datei)>0) {
              var[++i]=gtrim(zwi);
              split(var[i],arr," ");
              mac[i]=arr[1];
              ip[i]=arr[2];
              name[i]=arr[3];
              netz[i]=arr[4]
            }
            close(datei);
          } 
          function gtrim(s) {  # loesche Leerzeichen am Schluss und ersetze mehrere in der Mitte durch eines 
            sub(/[ \t\r\n]+$/,"",s); 
            s2=gensub(/[ \t\r\n]+/," ","g",s);
            return s2;
          }
          BEGIN {
            ausg="'$gesausdt'";
            liesein(ch,ausg);
          }
          {                  # Abschnitt für jede Zeile aus $ausgdt:
           trimzl=gtrim($0);
           if (trimzl!="") { # falls keine Leerzeile
              obschreib=1;
              for(j in ch) {
                if (ch[j]==trimzl ||(mac[j]==$1 && ip[j]==$2 && name[j]==$3 && $4=="-")) { # falls Zeile schon da oder schon aussagekräftiger da ...
                  obschreib=0;    # dann nicht schreiben
									break;
                } else if (mac[j]==$1 && ip[j]==$2 && name[j]==$3 && netz[j]=="-" && $4!="-") { # falls Zeile aussagekräftiger ...
                  obschreib=0;
                  if (0'$verb'==1) system("printf \"Ersetze: '$blau'"trimzl"'$reset'\\n\"");
                  ch[j]=trimzl; # dann ersetzen
                  netz[j]=$4;
									break;
                }
              }
              if (obschreib) { # falls nicht "nicht schreiben" ermittelt oder ersetzt, dann Datensatz anfügen
                ch[length(ch)+1]=trimzl;
                if (0'$verb'==1) system("printf \"Ergaenze: '$blau'"trimzl"'$reset'\\n\"");
              }
            }
          }
          END {
            for(j=10;j>0;j--) {
              system("mv -f "ausg"_"j" "ausg"_"j+1" 2>/dev/null"); # alte Sicherungskopien verrutschen ...
            }
            system("mv -f "ausg" "ausg"_1 2>/dev/null");
            asort(ch,chs,"sortorder"); # die Sätze sortieren s.o. ...
            # for(j in chs) system("printf \""chs[j]"\" | xxd -ps -c 200 | tr -d \\\\n; echo \" \""chs[j]); # Debugging evtl. kryptischer Zeichen
            for(j in chs) {
              if (j==1 || chs[j]!=chs[j-1]) { # keine doppelten Zeilen drucken
                print chs[j] >> (ausg); # die eindeutigen Sätze alle in die Gesamtdatei schreiben
              } else {
								if (0'$verb'==1) system("printf \"Doppelt: '$blau'"chs[j]"'$reset'\\n\""); # evtl. doppelte (weggelassene) anzeigen
              }
            }
          }
        ' "$ausgdt";
        endz=$(echo $LINENO|awk '{print $0-1}'); # Zeilennummer merken
#        [ "$verb" ]&&sed "$begz,$endz!d" "$meinpfad/$0";  # wär doch a bißl lang ...
        [ "$verb" ]&&printf "$blau$gesausdt$reset += $blau$ausgdt$reset (mit awk (Zeilen $begz-$endz in $meingespfad))\n";
      fi;
  	fi;
}

# alle oder gewünschte Geräte wecken
wecken() {
	Action=X_AVM-DE_WakeOnLANByMACAddress
	ParIn=NewMACAddress
	zahl=0;
	if [ "$obnurmac" ]; then # wecken ohne geraeteliste(), wenn nur MAC-Adressen angegeben => geht schneller
		geszahl=$(echo "$pcs"|awk 'END{print NF}');
		for Inhalt in $pcs; do # hier keine Anführungszeichen!
		  zahl=$(printf $zahl|awk '{print $0+1}'); # zahl++
			printf "${lila}Waking/wecke ($zahl/$geszahl)$reset: $blau$Inhalt$reset\n";
			fragab; # hier geschieht das Wecken
		done;
	else
		geszahl=$(wc -l <"$gesausdt"); # Zeilenzahl von $gesausdt
		[ -f "$gesausdt" ]||{ printf "File/Datei $blau$gesausdt$reset not found/nicht gefunden\n";exit;};
		[ -s "$gesausdt" ]||{ printf "File/Datei $blau$gesausdt$reset empty/leer\n";exit;};
		while read -r zeile; do
			# falls pcs angegeben, dann danach filtern; falls '-' in pcs, dann ' -' verwenden, da '-' im hostname enthalten sein kann
      [ "$IFverbo" ]&&{ echo "$zeile"|awk '{if  (match("'$IFverbo'",$4)) exit 1;}' || continue;};
      [ "$IFerlau" ]&&{ echo "$zeile"|awk '{if (!match("'$IFerlau'",$4)) exit 1;}' || continue;};
			[ "$npc" ]&&{ gefu=;for pc in $npc;do [ $pc = "-" ]&&pc=" -";echo "$zeile"|sed -n "/$pc/q1"||{ gefu=1;break;};done;[ "$gefu" ]&&continue;}; 
			[ "$pcs" ]&&{ gefu=;for pc in $pcs;do [ $pc = "-" ]&&pc=" -";echo "$zeile"|sed -n "/$pc/q1"||{ gefu=1;break;};done;[ "$gefu" ]||continue;}; 
			zahl=$(printf $zahl|awk '{print $0+1}'); # zahl++
			if [ "$zeig" ];then # zeigt die Liste an
				echo "$zeile"|
          awk '{printf "%4s/%4s: '$blau'%17s '$lila'%.15s '$blau'%.30s '$lila'%s'$reset'\n",'$zahl','$geszahl',$1,$2"'"$Pkt"'",$3"'"$Pkt"'",$4}';
			else
        aktpc=$(echo $zeile|awk 'END{print $3" "$4}');
        for iru in 1; do # nur wegen break
          if [ $obgrue/ != 1/ ]; then # Verkürzungsmöglichkeit nur, wenn nicht obgrue=1
            case "$schonda" in *$aktpc*) break;; esac; # falls PC schon mal abgefragt, dann Schleife verlassen
          fi;
          schonda="$schonda $aktpc";
          [ "$verb" ]&&printf "schonda: $rot$schonda$reset\n"; 
          printf "${lila}Waking/wecke ($zahl/$geszahl)$reset: $blau$zeile$reset\n";
          Inhalt=${zeile%% *}; # das erste Wort: Mac-Adresse
          fragab; # hier geschieht das Wecken
        done; # iru in 1
			fi;
		done << EOF
$(tac "$gesausdt")
EOF
 fi;
}

# hier geht's los
vorgaben;
commandline "$@"; # alle Befehlszeilenparameter übergeben
authorize;
[ -z "$obnurmac" -o "$scan" ]&&geraeteliste;
[ "$scan" ]&&exit;
wecken;
