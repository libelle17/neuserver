#!/bin/bash
#// string substitution geht nur in bash, nicht in dash, welches auf deb-Systemen standardmaessig durch sh aufgerufen wird
#// => in diesem Fall Aufruf in bash-Aufruf umwandeln
#// [ -z "$BASH_SOURCE" ]&&{ bash "$0";exit;}
# normalerweise redundant, nur nicht, falls diese Datei manuell umbenannt wird ...
#// (( AUFRUFE += 1 ));
AUFRUFE=$(expr $AUFRUFE + 1)
ICH=$(basename "$0")
if [ $ICH = -bash ]; then 
	declare -r ICHges=$(readlink -f "${BASH_SOURCE[0]}")
	ICH=$(basename $ICHges)
fi
# die naechsten zwei Variablen werden in configure gebraucht
#// DPROG=autofax;
[ -f pname ]&&DPROG=$(cat pname)||case $0 in *_*) DPROG=${0%%_*};; *) DPROG=${PWD##*/};; esac;
# in .git/config steht z.B. "        url = ssh://git@github.com/<GITV>/<DPROG>.git"
GITV=$([ -f .git/config ]&&sed -n '/ *url =.*com/{s/.*com\/\([^/]*\).*/\1/p}' .git/config);
#// wenn nicht vorhanden, dann schauen, ob gitvdt existiert
#// [ -z $GITV ]&& [ -f gitvdt ]&& GITV=$(sed 's/"//g' gitvdt);
# die naechste Zeile wird im Makefile in transfer: und git: editiert
[ -z $GITV ]&& GITV=libelle17;
#// echo vor Entscheidung,DPROG: $DPROG, GITV: $GITV
# diese Datei wird wegen obigem in configure und indirekt in viall gesourct, soll dann hier abbrechen
if test "$ICH" != configure -a "$ICH" != viall -a "$ICH" != modziel.sh -a $AUFRUFE -lt 2; then
	#// echo nach Entscheidung,DPROG: $DPROG, GITV: $GITV
	# aPWD=`pwd` 
	# nPWD=${PWD##*/}
	# wenn $DPROG schon das aktuelle Verzeichnis ist und wenn es dort einige notwendige Dateien gibt, dann nicht mehr neu runterladen ...
	ERF=0;
	[ -f Makefile -o -f Makefile.roh ]&&[ -f $DPROG.cpp -a -f configure ]&& ERF=1;
	[ $ERF = 1 ]&& 
	{
		. ./configure;
		printf "${blau}Installing/ Installiere $rot$DPROG$reset ...\n";:;
	}|| 
	{ # ... sonst moegliche alte Quelldateiverzeichnisse $DPROG umbenennen, aktuelle Version neu herunterladen ...
		printf "Downloading/ Lade runter $DPROG ...\n"
		cd ~; 
		T=$DPROG.tar.gz;
		HOSTER=github.com
		wget https://$HOSTER/$GITV/$DPROG/archive/master.tar.gz -O "$T" && 
		tar xpvf $T && 
		rm -f $T &&  
		{ VORIGE=$(ls -d ~/${DPROG}_* 2>/dev/null| cut -d"_" -f2 | sort -nr);
			for i in $VORIGE; do  
				case $i in 
					""|*[!0-9]*)
						;; 
					*) 
						j=$((i+1)); 
						printf "mv ${DPROG}_$i ${DPROG}_$j\n"; 
						mv ${DPROG}_$i ${DPROG}_$j; 
				esac; 
			done; 
			test -e $DPROG && mv $DPROG ${DPROG}_1; 
			mv $DPROG-master $DPROG && 
			{
				cd $DPROG; 
				echo $DPROG >pname
				. ./configure
				Q=../${DPROG}_1/$INSTLOG; test -f $Q && cp -a $Q .||:
				Q=../${DPROG}_1/$UNF; test -f $Q && cp -a $Q .||:
			}
		} || 
		exit;
	}
	$SPR make >/dev/null ||  
	{ printf "GNU make missing/fehlt\n"; exit;
	}
	# ... und dann kompilieren und installieren
	make opts && ${SUDC}make install; 
	erg=$?;
	[ $erg = 0 ]&& farbe=$blau||farbe=$rot;
	printf "Result code/ Ergebniscode: ${farbe}$erg${reset}\n";
fi
