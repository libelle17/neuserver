#!/bin/sh
# versucht (alle) PCs an der Fritzbox zu wecken; 
# zusammengeschrieben von/written together by: Gerald Schade 6.4.2019

vorgaben() {
# eher veränderbare Vorgaben
  meinpfad="$(dirname "$(readlink -f "$0")")";
	ausgdt=$meinpfad/ergtr64.txt; # Ausgabe der aktuellen geraeteliste()-Abfrage
	gesausdt=$meinpfad/gestr64.txt; # Vereinigungsmenge aller geraeteliste()-Abfragen (notwendig, da einige Anfragen unvollständige Ergebnisse liefern!)
	logdt=$meinpfad/logtr64.txt; # log-Datei für TR-064-Abfragen
	listenintervall=7; # mit Parameter -al wird alle $listenintervall Tage die geraeteliste (in $gesausdt) durch eine neue TR-064-Abfrage ergänzt, 0 = nie
  loeschintervall=1; # Intervall zum Löschen (und Neuerstellen) von $gesausdt, 0 = nie
	curlmaxtime=20;
	IFerl=; # "802.11,Ethernet,-"; # erlaubte Interfaces
	IFverb="802.11"; #verbotene Interfaces (kommagetrennt)
# eher starre Vorgaben
	blau="\033[1;34m";
	rot="\033[1;31m";
	lila="\033[1;35m";
	reset="\033[0m"; # Farben zurücksetzen
	FritzboxAdressen="fritz.box 169.254.1.1"; # wenn fritz.box nicht geht, dann geht 169.254.1.1
# TR-064-Parameter für fragab(): für beide Abfragen (geraeteliste() und wecken())
	controlURL=hosts
	serviceType=Hosts:1
# Möglichkeiten von tr-064 anzeigen:
# for FB in $FritzboxAdressen;do curl http://$FB:49000/tr64desc.xml 2>/dev/null&&break;done;exit; 
}

# Funktion für ein bis zwei TR-064-Abfragen
fragab() {
	if [ "$1" ];then filter="$1";else filter="sed -n p";fi; # ggf. leerer Filter
  case $controlURL in /*);;*) controlURL=/upnp/control/$controlURL;;esac; # immer gleiche Vorsilben
  case $serviceType in urn:*);;*) serviceType=urn:dslforum-org:service:$serviceType;;esac; # immer gleiche Vorsilben
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
		for adr in $FritzboxAdressen;do
			FB=http://$adr:49000;
			printf "$blau$adr$reset, Action: $blau$Action $ParIn $Inhalt$reset, trying/versuche ${blau}ipv$ipv$reset\r";
			befehl="curl -$ipv -k --anyauth -u \"$crede\" \\n\
						-H \"Content-Type: text/xml; charset=utf-8\" \\n\
						-H \"SoapAction: $serviceType#$Action\" \\n\
						\"$FB$controlURL\" \\n\
						-d '$XML'";
      tufrag "$befehl" umw "$FB$controlURL";
#			erg=$(eval $(echo $befehl|sed 's/\\n//g;s/\\t//g') 2>"$logdt");
#			ret=$?;
#			awk 'BEGIN {while (c++<99) printf " ";printf "\r";}' # Zeile wieder weitgehend säubern
			[ $ret -ne 0 ]&&continue; # z.B. fritz.box konnte nicht aufgelöst werden
#			if [ $ret -eq 0 -o $ipv -eq 4 ]&&[ "$verb" ]; then
#        printf "Command/Befehl: $blau%b$reset\n" "$befehl";
#        printf " Ausgabe/output:\n$rot%b$reset\n" "$([ -f "$logdt" ]&&cat "$logdt"||echo ' (fehlt/missing)')";
#      fi;
			# printf "Seifenaktion: "'SoapAction: '$serviceType'#'$Action 
			[ "$erg" ]&&[ "$verb" ]&&printf "\nReturn/Rueckgabe: \n$blau$erg$reset\n";
			# wenn Ergebnis mit .lua zurückgeliefert wird, dann muss diese Adresse ...
			case $erg in *.lua*)
				neuurl=$(echo "$erg"|awk '/\.lua/{print gensub(/^[^>]*>([^<]*)<.*/,"\\1","1")}') # ... aus dem XML-Code herausgelöst werden ...
				case $neuurl in *://*);;*)neuurl=$FB$neuurl;;esac # ... ggf. um den Fritzbox-Namen erweitert werden ...
				[ "$verb" ]&&printf "New/Neue Url:\n$blau$neuurl$reset\n";
				for faktor in "" 0 00; do # wenn die Zeit nicht reicht, dann verzehnfachen
					# "--connect-timeout 1" schuetzt leider nicht vor Fehler 606 bei ipv4 # oder |tee
					befehl="curl -m ${curlmaxtime}$faktor \"$neuurl\" 2>"$logdt"|eval "$filter" >\"$ausgdt\"";
          tufrag "$befehl" "" "$neuurl" "$ausgdt"; # ... und dann nochmal mit curl aufgerufen werden
#					[ "$verb" ]&&printf "Befehl/Command: $blau$befehl$reset\n"||printf "Rufe ab/Evaluating: $blau$neuurl$reset ...\r";
#					eval $befehl; # ... und dann nochmal mit curl aufgerufen werden
#					ret=$?;
#					[ -z "$verb" ]&&awk 'BEGIN {while (c++<99) printf " ";printf "\r";}' # Zeile wieder weitgehend säubern
					[ -s "$ausgdt" ]&&break;
  			done;
#				if [ "$verb" ]; then
#					printf " its return/dessen Rueckgabe: $blau$ret$reset (Result/Ergebnis in: $blau$ausgdt$reset)\n";
#          printf " Ausgabe/output:\n$rot%b$reset\n" "$([ -f "$logdt" ]&&cat "$logdt"||echo ' (fehlt/missing)')";
#        fi;
				[ "$ret" -eq 0 ]&&break;
				;;
				*) [ "$ret" -eq 0 ]&&break;;
			esac;
	 done;
	 [ $ret -eq 0 ]&&break;
  done;
}

# die tatsächliche TR-064-Abfrage durchführen
tufrag() {
  if [ "$verb" ]; then
    printf "Befehl/Command: $blau%b$reset\n" "$1";
  else
    printf "Rufe ab/Evaluating: $blau$3$reset ...\r";
  fi;
  if [ "$2" ]; then
    befehl="$(echo "$1"|sed 's/\\n//g;s/\\t//g')";
  else
    befehl="$1";
  fi;
  erg=$(eval "$befehl" 2>"$logdt");
  ret=$?;
  if [ "$verb" ]; then
    if [ "$4" ]; then
      printf " its return/dessen Rueckgabe: $blau$ret$reset";
      [ -s "$3" ]&&printf "(Result/Ergebnis in: $blau$3$reset)";
      printf "\n";
    fi;
    printf " Ausgabe/output:\n$rot%b$reset\n" "$([ -f "$logdt" ]&&cat "$logdt"||echo ' (fehlt/missing)')";
  else
    awk 'BEGIN {while (c++<99) printf " ";printf "\r";}' # Zeile wieder weitgehend säubern
  fi;
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
	[ "$npc" ]&&npc=$(echo "$npc"|sed 's/,/ /g'); # Komma-Liste in Leerzeichen-getrennte Liste umwandeln
	if [ "$pcs" ]; then 
		pcs=$(echo "$pcs"|sed 's/,/ /g');
		if [ -z "$zeig" ]; then
			nurmac=1; # nur MAC-Acressen angegeben => $ausgdt muß nicht verwendet werden, geraeteliste nicht aufgerufen werden
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
  # auf mint geht logname nicht mehr, dafür Ersatzbefehl
	credfile="$(getent passwd $(logname 2>/dev/null||loginctl user-status|sed -n '1s/\(.*\) .*/\1/p'||whoami)|cut -d: -f6)/.tr64cred"; # ~  # $HOME
	crede=$(cat $credfile 2>/dev/null);
	if [ -z "$crede" -o $obneu = 1 ]; then
		 printf "Please enter the fritz box user/Bitte Fritzboxbenutzer eingeben: ";read fbuser;
		 printf "Please enter the password for/Bitte Passwort für $blau$fbuser$reset eingeben: ";read fbpwd;
		 crede="$fbuser:$fbpwd";
		 printf "$crede" >"$credfile";
	fi;
}

# Liste aller von der Fritzbox gemerkten Geräte ggf. abfragen und in $ausgdt speichern
geraeteliste() {
	  if [ -z "$alteliste" ]; then
			neueliste=1;
		elif [ "$listenintervall" != 0 ]; then
			if ! find "$meinpfad" -mtime -$listenintervall -wholename "$ausgdt"|grep -q .; then
				neueliste=1;
			fi;
		fi;
	  if [ "$neueliste" ]; then
			Action=X_AVM-DE_GetHostListPath;
			ParIn=;
			Inhalt=;
			# XML parsen: Zeilen aus Mac,IP und Hostname erstellen; sed wird natürlich aus Gründen der Übersichtlichkeit verwendet;
			filter="\"{ I=IPAddress;M=MACAddress;H=HostName;T=InterfaceType;sed -n '/'\\\$I'>/{s/<'\\\$I'>\(.*\)<\/'\\\$I'>/\\\\1/;h};" # Namen angeben, IP-Adresse ins hold-Register stellen
			filter=$filter"/'\\\$I' \/>/{s/.*/-/;x;b;};" # falls keine IP-Adresse angegeben, dann "-" in hold-Register schreiben
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
        fragab; # fragab ohne filter erzeugt die ganze xml-Datei
      else
        fragab "$filter"; # der fertige Filter wird mit -v angezeigt
				# gesausdt alle $loeschintervall Tage löschen und ganz erneuern
				if [ "$loeschintervall" != 0 ]; then
					if ! find "$meinpfad" -mtime -$loeschintervall -wholename "$gesausdt"|grep -q .; then
						rm -f "$gesausdt";
					fi;
				fi;
				# neue Zeilen in Datei $ausgdt an $gesausdt anhängen, solche mit - als Netz durch andere ersetzen
        begz=$(echo $LINENO|awk '{print $0+1}');
        awk '
          function sortorder(i1,v1,i2,v2,li,re) { # Sortierfunktion für asort() kurz vor der Ausgabe
            split(v1,arr1," ");
            li=arr1[3]arr[2];
            split(v2,arr2," ");
            re=arr2[3]arr[2];
            if (li<re) return -1;
            if (li==re) return 0;
            return 1;
          }
          function liesein(var,datei) { # liest die bisherigen Datensätze (aus $gesausdt) ein
            i=0;
            while ((getline var[++i] < datei)>0) {
              split(var[i],arr," ");
              mac[i]=arr[1];
              ip[i]=arr[2];
              name[i]=arr[3];
              netz[i]=arr[4]
            }
            delete var[i];
            close(datei);
          }
          BEGIN {
            ausg="'$gesausdt'";
            liesein(ch,ausg);
          }
          {
           if ($0!="") { # falls keine Leerzeile
              obschreib=1;
              for(j in ch) {
                if (ch[j]==$0 || (mac[j]==$1 && ip[j]==$2 && name[j]==$3 && $4=="-")) { # falls Zeile schon da oder schon aussagekräftiger da ...
                  obschreib=0;    # dann nicht schreiben
                } else if (mac[j]==$1 && ip[j]==$2 && name[j]==$3 && netz[j]=="-") { # falls Zeile aussagekräftiger ...
                  obschreib=0;
                  if (0'$verb'==1) system("printf \"Ersetze: '$blau'"$0"'$reset'\\n\"");
                  ch[j]=$0; # dann ersetzen
                  netz[j]=$4;
                }
              }
              if (obschreib) { # falls nicht "nicht schreiben" ermittelt oder ersetzt, dann Datensatz anfügen
                ch[length(ch)+1]=$0;
                if (0'$verb'==1) system("printf \"Ergaenze: '$blau'"$0"'$reset'\\n\"");
              }
            }
          }
          END {
            for(j=10;j>0;j--) {
              system("mv "ausg"_"j" "ausg"_"j+1" 2>/dev/null"); # alte Sicherungskopien verrutschen ...
            }
            system("mv "ausg" "ausg"_1 2>/dev/null");
            asort(ch,chs,"sortorder"); # sortieren s.o.
            for(j in chs) {
              if (j==1 || chs[j]!=chs[j-1]) { # keine doppelten Zeilen drucken
                print chs[j] >> (ausg);
              } else {
                if (0'$verb'==1) system("printf \"Doppelt: '$blau'"chs[j]"'$reset'\\n\"");
              }
            }
          }
        ' "$ausgdt";
        endz=$(echo $LINENO|awk '{print $0-1}');
#        [ "$verb" ]&&sed "$begz,$endz!d" "$meinpfad/$0";  # wär doch a bißl lang ...
        [ "$verb" ]&&printf "$blau$gesausdt$reset += $blau$ausgdt$reset (mit awk (Zeilen $begz-$endz in $meinpfad/$0))\n";
      fi;
  	fi;
}

# alle oder gewünschte Geräte wecken
wecken() {
	Action=X_AVM-DE_WakeOnLANByMACAddress
	ParIn=NewMACAddress
	# wecken
	zahl=0;
	if [ "$nurmac" ]; then # wecken ohne geraeteliste(), wenn nur MAC-Adressen angegeben
		geszahl=$(echo "$pcs"|awk 'END{print NF}');
		for Inhalt in $pcs; do
		  zahl=$(printf $zahl|awk '{print $0+1}');
			printf "${lila}Waking up/wecke ($zahl/$geszahl)$reset: $blau$Inhalt$reset\n";
			fragab; # hier geschieht das Wecken
		done;
	else
		geszahl=$(wc -l <"$gesausdt");
		[ -f "$gesausdt" ]||{ printf "File/Datei $blau$gesausdt$reset not found/nicht gefunden\n";exit;};
		[ -s "$gesausdt" ]||{ printf "File/Datei $blau$gesausdt$reset empty/leer\n";exit;};
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
					fragab; # hier geschieht das Wecken
					break;
				done;
			fi;
		done << EOF
$(cat "$gesausdt")
EOF
 fi;
}

# hier geht's los
vorgaben;
commandline "$@";
authorize;
[ -z "$nurmac" ]&&geraeteliste;
wecken;
