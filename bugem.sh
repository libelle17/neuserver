#!/bin/bash
# dash geht nicht: --exclude={,abc/,def/} wirkt nicht
# soll alle relevanten Datenen kopieren, aufgerufen aus bulinux.sh, butm.sh, buint.sh
#im aufrufenden Programm soll QL und buhost (z.B. durch bul1.sh) und kann ZL (je ohne Doppelpunkt) definiert werden, sonst ZL als commandline-Parameter
EXFEST=",Papierkorb/";
blau="\033[1;34m";
lila="\033[1;35m";
dblau="\033[0;34;1;47m";
rot="\033[1;31m";
reset="\033[0m";
kopbef="ionice -c2 nice -n10 rsync";
SD="Schutzdatei_bitte_belassen.doc" # Default fuer Einzeldatei-Modus "SD=<Pfad>"
SDLISTE=("Schutzdatei_bitte_belassen.doc" "Auch_eine_Schutzdatei_bitte_belassen.jpg" "zusätzliche_Schutzdatei_bitte_belassen.pdf") # bewusst unterschiedliche Anfangsbuchstaben (S/A/z), muessen alle an Quelle+Ziel inhaltlich uebereinstimmen, bevor kopiert wird
SDMAILEMPF="diabetologie@dachau-mail.de gerald.schade@gmx.de geraldschade@gmx.de" # Empfaenger der Ransomware-Verdachtswarnung, bei Bedarf weitere anhaengen (Leerzeichen-getrennt)
LINEINS=linux1;
maxz=0;

# $1 = Befehl, $2 = Farbe, $3=obdirekt (ohne Result, bei Befehlen z.B. wie "... && Aktv=1" oder "sh ...") $4=obimmer (auch wenn nicht echt)
# in dem Befehl sollen zur Uebergabe erst die \ durch \\ ersetzt werden, dann die $ durch \$ und die " durch \", dann der Befehl von " eingerahmt
ausf() {
  gz=;
  anzeige=$(echo "${1%\n}"|sed 's/%/%%/;s/\\/\\\\\\\\/g')$reset;
	[ "$verb" -o "$2" ]&&{ gz=1;printf "$2$anzeige";}; # escape für %, soll kein printf-specifier sein
  if [ "$obecht" -o "$4" ]; then
    if test "$3" = direkt; then
      $1;
    elif test "$3"; then 
      [ "$verb" ]&&echo "$1";
      eval "$1"; 
    else 
  #    ne=$(echo "$1"|sed 's/\([\]\)/\\\\\1/g;s/\(["]\)/\\\\\1/g'); # neues Eins, alle " und \ noch ein paar Mal escapen; funzt nicht
  #    printf "$rot$ne$reset";
      resu=$(eval "$1" 2>&1); 
    fi;
    ret=$?;
    resgedr=;
    [ $verb ]&& printf " -> ret: $blau$ret$reset";
    if [ -z "$3" ]; then 
      [ "$verb" -o \( "$ret" -ne 0 -a "$resu" \) ]&&{ 
        [ "$gz" ]||printf "$2$anzeige";
        [ "$ret" = 0 ]&& farbe=$blau|| farbe=$rot;
        printf "${reset}, resu:\n$farbe"; 
        resgedr=1;
        [ "$resu" ]&&{ [ "$maxz" -a "$maxz" -ne 0 -a $(echo "$resu"|wc -l) > "$maxz" ]&&resz="...\n"$(echo "$resu"|tail -n$maxz)||resz="$resu";};
        printf -- "$resz"|sed -e '$ a\'; # || echo -2: $resz; # Zeilenenden als solche ausgeben
        printf "$reset";
      }
    fi; # if [ -z "$3" ]; then 
  fi; # obecht
  [ "$gz" -a -z "$resgedr" ]&&printf "\n";
#  [ $resgedr ]||printf "\n";
} # ausf

ausfd() {
  ausf "$1" "$2" direkt "$4";
} # ausfd

# Befehlszeilenparameter auswerten
commandline() {
	while [ $# -gt 0 ]; do
   case "$1" in 
     SD=*) sdneu=2; SDQ=${1##*SD=};SD=${SDQ##*/};;
     SD) sdneu=1; SDQV=();
         for _sd in "${SDLISTE[@]}"; do
           [ ! -f "$_sd" ]&&{
             printf "Option '${blau}SD$reset' angegeben, aber $blau$_sd$reset nicht in "$blau$(readlink -f $0)$reset" gefunden, ${rot}breche ab$reset.\n";
             exit 3;
           };
           _sdq=$(readlink -f $0); _sdq=${_sdq%/*}/$_sd;
           SDQV+=("$_sdq");
         done;;
     -*|/*)
      para=${1#[-/]};
      case $para in
        d|-del) obdel=1;;
        e|-echt) obecht=1;;
        f|-force) obforce=1;;
        h|'?'|-h|'-?'|/?|-hilfe) obhilfe=1;; # Achtung: das Fragezeichen würde expaniert
        -help) obhilfe=e;; # englische Hilfe
        k|-kill) obkill=1;;
        m|-mehr) obmehr=1;;
        mz|-maxz) shift; maxz="$1";
                  echo "$maxz"|egrep -q "^[0-9 ]*$"||{ printf "Kann maximale Zeilenzahl: $blau$maxz$reset nicht auflösen. Breche ab.\n";exit;};;
        nv|-nichtvirt) obnv=1;;
        nd|-nurdrei) nurdrei=1;;
        nz|-nurzweidrei) nurzweidrei=1;;
        v|-verbose) verb=1;;
        dt|-nurdt|-nur-dateien) obdt=1;;  # Dateitransfer (dt1+dt2), keine DB
        dt1|-nur-dt1) obdt1=1;;           # nur Konfigdateien, keine DB
        dt2|-nur-dt2) obdt2=1;;           # nur Windows-Shares (/mnt/wser, /mnt/anmmw)
        dt3|-nur-dt3) obdt3=1;;           # nur /DATA-Verzeichnisse, keine DB
        db|-nurdb|-nur-db) obdb=1;;       # nur Datenbank, keine Dateien
        wh|-wh) _bu_wh_max="${2:-5}"; shift;;
        dberg|-dberg) obdberg=1;;  # nur DB-Ergebnisvergleich anzeigen
        dbrsync|-dbrsync) ;;  # 11.07.2026: veraltet/No-Op - Datadir-rsync ist bei "-u" jetzt Standard (s. bulinux.sh), Flag nur noch aus Kompatibilitaet akzeptiert
        dbdump|-dbdump) obdbdump=1;;  # erzwingt den langsameren, aber unabhaengig von der MariaDB-Version funktionierenden mariadb-dump-Weg statt des seit 11.07.2026 bei "-u" defaultmaessigen Datadir-rsync
        u|-u|-umg|-umgekehrt) obumg=1;;  # Richtung umkehren: Q↔Z  # DB-Dump Wiederholungen bei Verbindungsverlust
        z|-ziele) shift; ziele="$1";
          echo "$ziele"|egrep -q "^[0-9 ]*$"||{ printf "Kann Kopierziele: $blau$ziele$reset nicht auflösen. Breche ab.\n";exit;};;
        q|-quelle) shift; QL="$1";;
      esac;;
     *)
#      [ "$ZL" ]&&QL=$ZL; # z.B. linux0 linux7 # The source and destination cannot both be remote.
      ZL=${1%%:*};; # z.B. linux0
   esac;
   shift;
	done;
  QmD=$QL:;QmD=${QmD#:};
  ZmD=$ZL:;ZmD=${ZmD#:};
	if [ "$verb" ]; then
    printf "Parameter: $blau-v$reset => gesprächig\n";
		printf "obecht: $blau$obecht$reset\n";
		[ $obdel ]&&printf "obdel: $blau$obdel$reset => in butm.sh rsync mit --delete aufrufen\n";
		[ $obforce ]&&printf "obforce: $blau$obforce$reset => in butm.sh und buint.sh kopiermt ohne Altersprüfung aufrufen\n";
    [ $obkill ]&&printf "obkill: $blau$obkill$reset => in butm.sh und buint.sh ggf. Turbomed-Verbindungen zu Windows-Server killen zum Kopieren\n";
    [ $obmehr ]&&printf "obmehr: $blau$obmehr$reset => in buint.sh auch 2. auf linux{$ziele} und dort auf virtuelle Windows-Server kopieren\n";
    [ $obnv ]&&printf "obnv: $blau$obnv$reset => in butm.sh nicht auf virtuellen Windows-Server weiter kopieren\n"; 
		[ $sdneu ]&&printf "sdneu: $blau$sdneu$reset => Schutzdatei $SD wird verteilt\n";
		[ "$obdt" ]&&printf "obdt: ${blau}$obdt${reset} => Dateitransfer (keine DB)\n";
		[ "$obdt1" ]&&printf "obdt1: ${blau}$obdt1${reset} => nur Konfigdateien+MO\n";
		[ "$obdt2" ]&&printf "obdt2: ${blau}$obdt2${reset} => nur Windows-Shares\n";
		[ "$obdt3" ]&&printf "obdt3: ${blau}$obdt3${reset} => nur /DATA-Verzeichnisse\n";
		[ "$obdb" ]&&printf "obdb: ${blau}$obdb${reset} => nur Datenbank\n";
		[ "$_bu_wh_max" ]&&printf "wh: ${blau}$_bu_wh_max${reset} => DB-Dump Wiederholungen\n";
		printf "SD: $blau$SD$reset\n";
		printf "SDQ: $blau$SDQ$reset\n";
    [ "$QL" ]&&printf "QL: ${blau}$QL${reset}\n";
		printf "ZL: $blau$ZL$reset\n";
		printf "nichtvirt: $blau$obnv$reset\n";
		[ $nurdrei ]&&printf "nurdrei: $blau$nurdrei$reset => in buint.sh nur auf Zielrechnern zwischen virt.Windows und Linux kopieren\n";
		[ $nurzweidrei ]&&printf "nurzweidrei: $blau$nurzweidrei$reset => in buint.sh nur von linux1 auf Zielrechner und dort nach virtwin{$ziele} kopieren\n";
    printf "ziele: $blau$ziele$reset\n";
    printf "maximale Zeilenzahl: $blau$maxz$reset\n";
	fi;
} # commandline

#  USB:
#    QL=; 
#    ZL=;
#  weg:
#    QL=;
#    ZL=linux7
#  her:
#    QL=LINEINS
#    ZL=;
#    QVos=/ Pfad/zum/qv / # zum Kopieren der Schutzdatei
#    QVofs=/ Pfad/zum/qv[/]
#    obsub 1: qv, obsub: qv/
#    obdat 1: obsub und /Pfad/zum/qv = Datei
#    ZVos=/ Pfad/zum/zv / oder / Pfad/zum/zv/qv /, falls obsub # zum Vergleich einer Datei darin
#    ZVofs=/ Pfad/zum/zv/ oder / Pfad/zum/zv/qv, falls obdat

# ob eine Datei auf dem Zielsystem alt genug ist zum Kopieren, aufgerufen aus kopiermt: $1= Dateipfad, $2= Mindestalter [s]
# wird nicht aufgerufen, wenn nur eine Datei kopiert wird
obalt() {
	# $1 = Datei auf $QV und $ZV, deren Alter verglichen werden soll 
	# $2 = Zahl der Sekunden Altersunterschied, ab der kopiert werden soll
  # liefert 0, wenn auf Quelle vorhanden und (alt genug oder auf Ziel fehlend), sonst 1
  machssh;
  [ "$obdat" ]&&DaQ="/${QVos%/*}${1#/}"||DaQ="/$QVos/${1#/}";
  [ "$obdat" ]&&DaZ="/${ZVos%/*}${1#/}"||DaZ="/$ZVos/${1#/}";
	[ "$verb" ]&&{
		echo obalt "$1" "$2" "$3" "$4"
	  echo DaQ: $DaQ, DaZ: $DaZ
	}
  [ "$sdneu" ]&&return 0; # Altersprüfung im Modus der Schutzdateiverteilung nicht sinnvoll => hier immer weiter machen
	faq=; # <> "" = Datei fehlt auf Quelle
  # das Leerzeichen nach &1 schützt vor ambiguous redirect-Fehler
  eval "$qssh 'stat \"$DaQ\" >/dev/null 2>&1 '||{ faq=1; printf \"${blau}$DaQ ${rot}fehlt auf Quelle$reset\n\"; }"
	[ "$faq" ]&& return 1;
	ret=; # <> "" = Datei fehlt auf Ziel
  eval "$zssh 'stat \"$DaZ\" >/dev/null 2>&1 '||{ ret=0; printf \"${blau}$DaZ ${rot}fehlt auf Ziel$reset\n\"; }"
  if [ -z "$ret" ]; then
    ausf "$qssh 'date +%s -r \"$DaQ\"'" "" "" 1; geaenq=$resu;
    awk 'BEGIN{printf strftime("geändert Quelle: '$blau'%15s'$reset' s ('$blau'%d.%m.%Y %T'$reset' %z)\n", '$geaenq');}';
    ausf "$zssh 'date +%s -r \"$DaZ\"'" "" "" 1; geaenz=$resu;
    awk 'BEGIN{printf strftime("geändert   Ziel: '$blau'%15s'$reset' s ('$blau'%d.%m.%Y %T'$reset' %z)\n", '$geaenz');}';
  #	geaenq=$(expr $geaenq + 2000);
    diff=$(awk "BEGIN{print $geaenq-$geaenz+0}");
    ret=$(awk "BEGIN{print ($diff<$2);}"); # wenn richtig, liefert awk 1, sonst 0
  #  ! awk "func abs(v){return v<0?-v:v}; BEGIN{ exit abs($alterdort-$alterhier)>$2 }";
    printf "Altersdifferenz $blau $diff ";if test $ret/ = 0/; then printf ">="; else printf "<";fi; printf "$2$reset s\n";
    # wenn die Funktion 0 zurückliefert, wird in in "if obalt" verzweigt
  fi;
  return $ret;
} # obalt

# kopiere mit Test auf ausreichenden Speicher
kopiermt() { # mit test
  # $1 = Verzeichnis auf Quelle
  # $2 = Verzeichnis auf Ziel
  # $3 = excludes
  # $4 = Optionen 
	# $5 = Pfad zur Datei, die als Alterskriterium geprüft werden soll
	# $6 = Zahl der Sekunden Altersunterschied, ab der kopiert werden soll
  # $7 = ob ohne Platzprüfung
  # $8 = ob ohne Schutzdateivergleich
  # vorher müssen ggf. Quellrechner in $QL (z.Zt. nur: leer oder linux1) und Zielrechner in $ZL hinterlegt sein
  # P1obs=$(echo "$1"|sed 's/\\//g'); # Parameter 1 ohne backslashes

  QVofs=$(echo ${1#/}|sed 's/\([^\\]\) /\1\\ /g'); # Quellverzeichnis ohne führenden slash, mit "\ " statt " "
  QVos=${QVofs%/}; # letzten Slash entfernen
  case $QVofs in */)obsub=;;*)obsub=1;;esac;
  machssh;
  [ "$obsub" ]&&{ eval "$qssh '[ -f \"/$QVos\" ]'&&obdat=1||obdat=";}; # obdat=1 heisst, /$QVos ist eine Datei
  [ "$obsub" ]&&{ $qssh "[ -f \"/$QVos\" ]"&&obdat=1||obdat=;}; # das geht nicht mit zsh
  if [ -z "$2" -o "$2" = "..." ]; then ZVofs=${QVofs%/*}/; [ "$ZVofs" = "$QVofs/" ]&&ZVofs=""; else # letzteres für QVofs ohne /
  ZVofs=$(echo ${2#/}|sed 's/\([^\\]\) /\1\\ /g'); fi; # Zielverzeichnis ohne führenden slash, mit "\ " statt " "
	ZVos=${ZVofs%/}; ZVofs=$ZVos/;
	[ "$obsub" -a \( -z "$2" -o "$2" = "..." \) ]&&ZVos=$ZVos/${QVofs##*/};
  ZVos=${ZVos#/}; ZVofs=${ZVofs#/}; # bei QVofs ohne / noch nötig
  [ "$obdat" ]&&ZVofs=$ZVofs${QVofs##*/};
#  echo "neue Zeile 3";
  echo `date +%Y:%m:%d\ %T` "vor /$QVos" >> $PROT
  printf "${blau}kopiermt$reset Q: $blau$1$reset, Z: $blau$2$reset, Ex: $blau$3$reset, Opt: $blau$4$reset, AltPrf: $blau$5$reset, >s: $blau$6$reset, oPlP: $blau$7$reset, QL: $blau$QL$reset, /QVos: /$blau$QVos$reset, QVofs: $blau$QVofs$reset, ZL: $blau$ZL$reset, ZVos: $blau$ZVos$reset, ZVofs: $blau$ZVofs$reset, obsub: $blau$obsub$reset, obdat: $blau$obdat$reset, qssh: $blau$qssh$reset, zssh: $blau$zssh$reset\n";
	# Quelle auf Existenz prüfen – falls weder Datei noch Verzeichnis: überspringen
	_QVos_real=$(echo "/$QVos" | sed 's/\\ / /g');
	if ! eval "$qssh 'test -e \"$_QVos_real\"'" 2>/dev/null; then
		printf "${rot}$_QVos_real auf ${blau}${QL:-lokal}${rot} nicht vorhanden – übersprungen${reset}\n";
		return 0;
	fi;
  for pc in "$QL" "$ZL"; do
    [ "$pc" ]&&{ 
      printf "Überprüfe $blau$pc$reset:"
  #    ping -c1 -W1 "$QL">/dev/null 2>&1 && QL=192.168.178.2${QL#linux};
      if ping -c1 -W1 "$pc">/dev/null 2>&1; then 
        printf "$reset anpingbar.\n"; 
      else 
        printf "$rot nicht anpingbar, verlasse Funktion$reset\n"; 
        return;
      fi;
    }; 
  done;
  for zute in "/$QVos" "/$ZVos"; do # zutesten
    if test "$zute/" = "/$QVos/"; then hsh="$qssh"; Lfw=$QL; else hsh="$zssh"; Lfw=$ZL; fi;
    [ "$Lfw" ]||Lfw=$buhost" (hier) ";
    echo $zute|grep '^/amnt/' >/dev/null && isamnt=1||isamnt=;
    echo $zute|grep '^/mnt/' >/dev/null && ismnt=1||ismnt=;
    if [ "$isamnt" -o "$ismnt" ]; then # wenn offenbar zu mountendes Laufwerk drin
      ok=;
      zuteh=${zute%/}; # ohne letzten slash
      testz="$zuteh";
      gpc=${zute#/mnt/}; gpc=${zute#/amnt/}; gpc=${gpc%%/*}; # virtwinx
      [ "$gpc" ]&&{
        if ping -c1 -W1 "$gpc" >/dev/null 2>&1; then ok=1; else
          ok=;
          printf "$blau$gpc$reset nicht anpingbar, versuche ihn zu starten\n";
          nr=${gpc#virtwin};
          [ $nr/ = / ]&& wirt=linux1||wirt=linux$nr;
          pruefpc $wirt kopiermt;
          ausf "$tush VBoxManage startvm Win10 --type headless" "" "" 1;      
          for iru in $(seq 1 1 120); do 
            if ping -c1 -W1 "$gpc" >/dev/null 2>&1; then ok=1; break; fi;
          done;
          [ "$ok" ]&&printf "brauchte $blau$iru$reset Durchläufe;\n";
        fi; 
      }
      while :; do # rausfinden, ob ein linker Teil des Pfades auf dem Quellrechner gemountet ist
        [ "$testz" ]||break;
        # Wichtig: Prüfung auf dem REMOTE-Rechner (via $hsh), nicht lokal!
        eval "$hsh 'findmnt \"$testz\" -n >/dev/null'" 2>/dev/null&&{ ok=1;break;}
        testz=${testz%/*};
      done;
      [[ $ismnt && ! $ok ]]&&while :; do # wenn nicht, dann schauen, was zu mounten ist # [ $ismnt -a ! $ok ] => !: binary operator expected
        [ "$zuteh" -a "$zuteh" != /mnt ]||break;
        if [ -d "$zuteh" ]; then # das sollte dann ein schon bestehendes Verzeichnis sein
          echo "$hsh 'mountpoint -q \"$zuteh\"'"
  #        $hsh "mountpoint -q \"$zuteh\"||mount \"$zuteh\" >/dev/null 2>&1";
#          for vers in 3.11 3.11 3.02 3.02 3.0 3.0 2.1 2.1 2.0 2.0 1.0 1.0; do
					for vers in 3.11 3.02 3.0 2.1 2.0 1.0; do
           if ! $hsh "mountpoint -q \"$zuteh\""; then
             # das Leerzeichen nach &1 schützt vor ambiguous redirect-Fehler
             ausf "$hsh \"mount '$zuteh' -t cifs -o nofail,vers=$vers,credentials=/home/schade/.wincredentials >/dev/null 2>&1 \"" $blau "" 1;
             # das würde gehen:
#            ausf "$hsh \"mount $zuteh -t cifs -o nofail,vers=$vers,credentials=/home/schade/.wincredentials >/dev/null 2>&1 \"" $blau
             # hier geht gar nix:
#             ausf "$hsh \"mount \\\\\"$zuteh\\\\\" -t cifs -o nofail,vers=$vers,credentials=/home/schade/.wincredentials >/dev/null 2>&1 \"" $blau
           else
      #       printf " ${blau}$cifs$reset gemountet!\n"
             break;
           fi;
          done;
          if $hsh "mountpoint -q \"$zuteh\""; then ok=1; break; fi; # wenn eins gemountet is, o.k.
        fi;
        zuteh=${zuteh%/*}; # die Unterverzeichnisse raufhangeln
      done;
      [ "$ok" ]||{
        printf "Laufwerk $blau$zute$reset auf $blau$Lfw$reset weder gemountet noch zumounten, breche ab!\n";
        return 7;
      }
    fi;
  done;

#  case $QVos in */)ZVos=${ZVos%/};;*)ZVos=${ZVos%/}/${QVos##*/};QVos=${QVos%/};;esac;
#  QVos=${QVofs%/}; # Quellverzeichnis (ohne abschließenden slash)
#  [ "$2" = ... ]&&case $QVofs in */)ZVK=$QVofs;;*)ZVK=${QVos%/*};;esac||ZVK=$(echo ${2#/}|sed 's/\([^\\]\) /\1\\ /g'); # Ziel-Verzeichnis kurz; rsync-Grammatik berücksichtigen
# Zielverzeichnis: wegen der rsync-Grammatik das letzte Verzeichnis von $1 noch an $2 anhängen, falls kein / am Schluss; erstes / streichen
#  ZV=$ZVK;
#  case $QVofs in */);;*)ZV=${ZV%/}/$(echo ${1##*/}|sed 's/\([^\\]\) /\1\\ /g');ZV=${ZV#/};;esac;
# falls Alterskriterium nicht erfuellt, dann abbrechen	

  obaltgepr=; # ob Alter geprüft
  [ "$5" -a "$6" -a -z "$obdat" ]&&{
   obalt "$5" "$6"&&obaltgepr=1||return 1;
   [ "$faq" ]&&return 2;
	}
  EXREST=$EXGES;
  EXAKT=;
  while [ "$EXREST" ]; do
    EXHIER=$(readlink -f "${EXREST##*,}"); EXREST=${EXREST%,*};
    case "$EXHIER" in $(readlink -f "/$QVofs")*) EXAKT="$EXAKT,"${EXHIER%/}"/";; esac;
  done;
  EX="$3$EXAKT$EXFEST";
  [ "$verb" ]&&printf "EX: $blau$EX$reset\n"
# falls nur die Schutzdatei überall etabliert werden soll
# beim Kopieren einzelner Dateien hierauf verzichten
  [ "$sdneu" -a ! "$obdat" ]&&{
      # scp wird hier auch lokal verwendet, da es besser mit "\ " umgehen kann als cp
      # SD nur lokal verteilen (nicht auf Quell-Rechner):
      # Quell-Daten sollen vor der ersten Sicherung manuell geprüft und
      # SD dort separat per "bulinux.sh SD" auf dem Quellrechner verteilt werden.
      # sdneu=1 (Option "SD" ohne "="): ganze SDLISTE verteilen; sdneu=2 (Option "SD=<Pfad>"): nur die eine angegebene Datei
      if [ "$sdneu" = 1 ]; then _sd_quellen=("${SDQV[@]}"); _sd_namen=("${SDLISTE[@]}");
      else _sd_quellen=("$SDQ"); _sd_namen=("$SD"); fi;
      for _sdi in "${!_sd_namen[@]}"; do
        _sd_q="${_sd_quellen[$_sdi]}"; _sd_n="${_sd_namen[$_sdi]}";
        if [ -z "$ZL" ]; then
          tu2="mkdir -p /$ZVos; cp -a \"$_sd_q\" \"/$ZVos/$_sd_n\"";  # kein Quoting
        else
          # ZVos statt _ZVofs_real: Letzteres wird erst weiter unten in
          # kopiermt() berechnet und ist hier (fruehes return 0) noch leer -
          # das fuehrte dazu, dass die Schutzdatei per scp immer im
          # Wurzelverzeichnis des Remote-Ziels statt im jeweiligen
          # Backup-Unterverzeichnis landete.
          _sd_zvos="$ZVos";
          tu2="$zssh 'mkdir -p \"/$_sd_zvos\"';\
            scp -p \"$_sd_q\" \"$ZL:/$_sd_zvos/$_sd_n\"";
        fi;
        # wie ueberall sonst: nur bei -e (obecht) tatsaechlich ausfuehren,
        # sonst Simulation (geplante mkdir/cp/scp-Befehle nur anzeigen)
        ausf "$tu2" "$blau";
      done;
    return 0;
  }
# Schutzdateien ggf. vergleichen (Inhalt per SHA-256, alle aus SDLISTE muessen passen), beim Kopieren einzelner Dateien hierauf verzichten
  [ ! "$obdat" -a ! "$8" -a "${#SDLISTE[@]}" -gt 0 ]&&for SD in "${SDLISTE[@]}"; do
    if [ "$QL" ]; then
      PZiel=$QL;
    elif [ "$ZL" ]; then
      PZiel=$ZL;
    else
      PZiel=;
    fi;
    AND="$QL";[ "$AND" ]||AND=$ZL;
    [ "$PZiel" ]&&if ! ping -c1 -W100 "$AND" >/dev/null 2>&1; then
      printf "$rot$AND$reset nicht anpingbar! Kehre zurueck!\n";
      return 1;
    fi;
    # SD-Inhalt von Quelle und Ziel separat holen (SHA-256) – ermöglicht Fallunterscheidung; Backslash aus Pfad entfernen vor SSH
    _sdkmt_qvos=$(printf "%s" "$QVos" | sed "s/\\\\//g");
    _sdkmt_zvos=$(printf "%s" "$ZVos" | sed "s/\\\\//g");
    if [ "$QL" ]; then
      _sdkmt_q=$(ssh $(_backup_sshopts "$QL") "$QL" "sha256sum \"/$_sdkmt_qvos/$SD\" 2>/dev/null"|cut -d' ' -f1);
      _sdkmt_z=$(sha256sum "/$_sdkmt_zvos/$SD" 2>/dev/null|cut -d' ' -f1);
    elif [ "$ZL" ]; then
      _sdkmt_q=$(sha256sum "/$_sdkmt_qvos/$SD" 2>/dev/null|cut -d' ' -f1);
      _sdkmt_z=$(ssh $(_backup_sshopts "$ZL") "$ZL" "sha256sum \"/$_sdkmt_zvos/$SD\" 2>/dev/null"|cut -d' ' -f1);
    else
      _sdkmt_q=$(sha256sum "/$_sdkmt_qvos/$SD" 2>/dev/null|cut -d' ' -f1);
      _sdkmt_z=$(sha256sum "/$_sdkmt_zvos/$SD" 2>/dev/null|cut -d' ' -f1);
    fi;
    if [ -z "$_sdkmt_q" ]; then
      # a) SD fehlt auf Quelle – Quelle evtl. beschädigt
      which mail >/dev/null 2>&1 && \
      printf "Liebe Praxis,\nbeim Versuch der Sicherheitskopie fehlte die Schutzdatei\n${Q:-$LINEINS:}/$QVos/$SD.\nDa so etwas auch durch Ransomware verursacht werden könnte, wurde die Sicherheitskopie für dieses Verzeichnis unterlassen.\nBitte den Systemadiminstrator verständigen!\nMit besten Grüßen, Ihr Linuxrechner"|mail -s "Achtung, Sicherheitswarnung von ${QL:-$LINEINS:} zu /$QVos vor Kopie auf $ZL!" $SDMAILEMPF
      printf "${rot}Schutzdatei /$QVos/$SD auf Quelle nicht gefunden${reset} – überspringe $blau/$QVos$reset\n";
      return 1;
    elif [ -z "$_sdkmt_z" ]; then
      # b) SD fehlt auf Ziel – frisches/neues Ziel, Kopie erlaubt (weitere Schutzdateien der Liste werden noch geprüft)
      printf "${blau}Schutzdatei /$ZVos/$SD auf Ziel nicht vorhanden${reset} – Ziel frisch, kopiere\n";
      # kein return 1 – Kopie wird fortgesetzt
    elif [ "$_sdkmt_q" != "$_sdkmt_z" ]; then
      # c) Beide vorhanden, Inhalt (SHA-256) weicht ab – immer blockieren
      which mail >/dev/null 2>&1 && \
      printf "Liebe Praxis,\nbeim Versuch der Sicherheitskopie fand sich ein inhaltlicher Unterschied (SHA-256) bei der Schutzdatei zwischen\n${Q:-$LINEINS:}/$QVos/$SD und\n$ZL/$ZVos/$SD.\nDa so etwas auch durch Ransomware verursacht werden könnte, wurde die Sicherheitskopie für dieses Verzeichnis unterlassen.\nBitte den Systemadiminstrator verständigen!\nMit besten Grüßen, Ihr Linuxrechner"|mail -s "Achtung, Sicherheitswarnung von ${QL:-$LINEINS:} zu /$QVos vor Kopie auf $ZL!" $SDMAILEMPF
      printf "${rot}keine inhaltliche Übereinstimmung (SHA-256) bei \"$QL:/$QVos/$SD\" und \"$ZL:/$ZVos/$SD\"!$reset\n";
      return 1;
    fi;
    # diese Schutzdatei identisch oder Ziel frisch → weiter mit der naechsten aus SDLISTE bzw. mit der Kopie
  done;
  if [ "$7" -o \( -z "$QL" -a -z "$ZL" \) ]; then
  # keine Platzprüfung
    rest=1;
  else
    # Platz ausrechnen:
#    ausf "$zssh 'df /${ZVos%%/*}|sed -n \"/\//s/[^ ]* *[^ ]* *[^ ]* *\([^ ]*\).*/\1/p\"'"; rest=${resu:-0}; # die vierte Spalte der df-Ausgabe
    ausf "$zssh 'df /${ZVos%%/*}'| awk '/\//{print \$4*1}'" "" "" 1; rest=${resu:-0};
    # Variablen auf reine Ganzzahl bereinigen (Locale-Punkte, Leerzeichen entfernen):
    _int() { printf "%s" "${1:-0}" | tr -cd '0-9'; };
    rest=$(_int "$rest"); rest=${rest:-0};
    echo $rest|LC_ALL=de_DE.UTF-8 awk '{printf "verfügbar           : '$blau'%'"'"'15d'$reset' kB\n", $1}';
    if [ "${rest:-0}" -gt 0 ] 2>/dev/null; then
      ausf "$zssh 'test -d \"/$ZVos\"&&{ du /$ZVos -d0;:;}||{ stat /$ZVos -c %s 2>/dev/null||echo 0;}'|awk -F $'\t' '{print \$1*1}'" "" "" 1; schonda=${resu:-0};
      schonda=$(_int "$schonda"); schonda=${schonda:-0};
      echo $schonda|LC_ALL=de_DE.UTF-8 awk '{printf "schonda             : '$blau'%'"'"'15d'$reset' kB\n", $1}';
      ausf "$qssh 'test -f \"/$QVos\"&&{ stat /$QVos -c %s||echo 0;:;}||du /$QVos -d0;'|awk '{print \$1*1}'" "" "" 1; zukop=${resu:-0};
      zukop=$(_int "$zukop"); zukop=${zukop:-0};
      echo $zukop|LC_ALL=de_DE.UTF-8 awk '{printf "zukopieren          : '$blau'%'"'"'15d'$reset' kB\n", $1}';
      rest=$(( rest - zukop + schonda ));
      [ "$EX" ]&&for E in $(echo $EX|sed 's/ //g;s/,/ /g');do
         E=$(echo $E|sed 's/\\/\\ /g');
         case $E in /*) zQ=/${E#/};zZ=$zQ;;*) zQ=/$QVos/${E#/};zZ=/$ZVos/${E#/};;esac;
         echo E: $E, QVos: $QVos, ZVos: $ZVos, zZ: $zZ, zQ: $zQ;
         ausf "$zssh 'test -d \"$zZ\" && du $zZ -d0'|awk '{print \$1*1}'" "" "" 1; papz=${resu:-0};
         papz=$(_int "$papz"); papz=${papz:-0};
         ausf "$qssh 'test -d \"$zQ\" && du $zQ -d0'|awk '{print \$1*1}'" "" "" 1; papq=${resu:-0};
         papq=$(_int "$papq"); papq=${papq:-0};
         rest=$(( rest - papz + papq ));
      done;
      echo $rest|LC_ALL=de_DE.UTF-8 awk '{printf "Nach Kopie verfügbar: '$blau'%'"'"'15d'$reset' kB\n", $1}';
    fi;
  fi; # if [ "$7" ]
  # Zielverzeichnis anlegen falls fehlend:
  if [ "$obecht" ]; then
    if [ "$ZL" ]; then
      $zssh "mkdir -p \"/$ZVos\"" 2>/dev/null||true;
    else
      mkdir -p "/$ZVos" 2>/dev/null||true;
    fi;
  else
    printf "Simulation: mkdir -p /$ZVos\n";
  fi;
  if test $rest -gt 0; then
		case $QVos in *var/lib/mysql*)
			printf "stoppe mysql auf $blau$ZL$reset\n";
			ausf "$zssh 'systemctl stop mysql'";
      ausf "$zssh 'pkill -9 mysqld'";
			echo "Fertig mit Stoppen von mysql";;
	  esac;
    # die Excludes funktionieren so unter bash und zsh, aber nicht unter dash
    [ "$QL" -o "$ZL" ]&&ergae="--rsync-path='$kopbef'"||ergae=;
    _QVofs_real=$(echo "$QVofs" | sed 's/\\ / /g');
    # Trailing / wenn Ziel explizit angegeben und Quelle ein Verzeichnis:
    # rsync src/ dest/ kopiert Inhalt; rsync src dest/ legt dest/src/ an (falsch)
    [ "$obsub" -a -z "$obdat" -a -n "$2" -a "$2" != "..." ] \
      && _QVofs_real="${_QVofs_real%/}/";
    _ZVofs_real=$(echo "$ZVofs" | sed 's/\\ / /g');
    Quelle=$QmD/$_QVofs_real;[ "$QL" ]&&Quelle=\"$Quelle\";
		EX=${EX#,/,};
		EX=${EX#,};
    [ "$EX" ]&&AUSSCHL=" --exclude={""$EX""}"||AUSSCHL=;
#    QVos=/ Pfad/zum/qv / # zum Kopieren der Schutzdatei
#    QVofs=/ Pfad/zum/qv[/]
#    obsub 1: qv, obsub: qv/
#    obdat 1: obsub und /Pfad/zum/qv = Datei
#    ZVos=/ Pfad/zum/zv / oder / Pfad/zum/zv/qv /, falls obsub # zum Vergleich einer Datei darin
#    ZVofs=/ Pfad/zum/zv/ oder / Pfad/zum/zv/qv, falls obdat
    # X = Extended Attributes/SELinux-Kontext mitkopieren (Bugfix 11.07.2026
    # nach einem Korruptionsvorfall bei MariaDB-Datadir-rsync, s. bulinux.sh:
    # ohne -X bekommen frisch kopierte Dateien auf Enforcing-Systemen den
    # generischen Kontext des Zielpfads statt des vom jeweiligen Dienst
    # (z.B. smbd) erwarteten - fuehrt sonst zu schwer diagnostizierbaren
    # Zugriffsfehlern statt klarer Fehlermeldungen):
    [ $obaltgepr ]&&attr="avX"||attr="avuX";
    if [ "$obecht" ]; then
      ausf "$kopbef $Quelle \"$ZmD/$_ZVofs_real\" -$attr $4 $ergae$AUSSCHL" $dblau 1;
    else
      printf "Befehl wäre: $dblau$kopbef $Quelle \"$ZmD/$_ZVofs_real\" -$attr $4 $ergae$AUSSCHL$reset\n";
    fi;
    ausf "$qssh 'test -d \"/$(echo $QVos|sed s/\\\\//g)\"'" "" "" 1;[ "$ret" = 0 ]&&EXGES=${EXGES},/$QVos/;
    [ "$verb" ]&&printf "EXGES: $blau$EXGES$reset\n";
		case $QVos in *var/lib/mysql*)
			echo starte mysql auf $ZL;
			ausf "$zssh 'systemctl start mysql'";
			echo "Fertig mit Starten von mysql";;
	  esac;
		return 0;
  else
    printf "${rot}Kopieren nicht begonnen${reset}, Speicherreserve: $blau$rest$reset\n";
		return 1;
  fi;
} # kopiermt

kopiermt_delta() {
  # Inkrementelles Kopieren: nur geänderte Dateien (--files-from + find -newer).
  # Parameter identisch mit kopiermt ($1–$8).
  # Fällt auf kopiermt zurück bei: obforce, sdneu, --delete, Erstlauf.
  # Voraussetzung: bustate.sh muss gesourct sein.

  # --- Fallback-Prüfung ---
  local _grund=
  [ "$obforce" ]  && _grund="obforce";
  [ -z "$_grund" ] && [ "$sdneu" ] && _grund="sdneu";
  [ -z "$_grund" ] && printf '%s %s' "${4:-}" "${OBDEL:-}" | grep -q -- '--delete' \
    && _grund="delete";
  if [ "$_grund" ]; then
    [ "$verb" ] && printf "  ${blau}kopiermt_delta${reset}: Fallback→kopiermt (%s)\n" "$_grund";
    kopiermt "$@"; return $?;
  fi;

  # --- Pfade normalisieren (wie in kopiermt) ---
  local QVofs_d QVos_d ZVofs_d ZVos_d obsub_d obdat_d _QVofs_real _ZVofs_real
  QVofs_d=$(printf '%s' "${1#/}" | sed 's/\([^\\]\) /\1\\ /g');
  QVos_d=${QVofs_d%/};
  case $QVofs_d in */) obsub_d=;; *) obsub_d=1;; esac;
  machssh;
  [ "$obsub_d" ] && { $qssh "[ -f \"/$QVos_d\" ]" 2>/dev/null \
    && obdat_d=1 || obdat_d=; };

  local _zielhost="${ZL:-lokal}";
  local _tmplist="/tmp/bu_delta_$$_$(printf '%s' "$QVos_d" | tr '/ ' '__').lst";

  # --- Geänderte Dateien ermitteln ---
  bustate_changed "/$QVos_d" "$_zielhost" "$_tmplist";

  # Erstlauf → vollständiger Abgleich via kopiermt
  if [ "$bustate_erstlauf" ]; then
    printf "  ${blau}kopiermt_delta${reset} /${QVos_d}: ${blau}Erstlauf${reset} → vollständiger Abgleich\n";
    rm -f "$_tmplist";
    kopiermt "$@"; return $?;
  fi;

  # Keine Änderungen → überspringen
  if [ "$bustate_count" -eq 0 ]; then
    printf "  ${blau}kopiermt_delta${reset} /${QVos_d}: ${blau}unverändert${reset}\n";
    echo "$(date +%Y:%m:%d\ %T) /$QVos_d unverändert (delta)" >> "$PROT";
    rm -f "$_tmplist";
    return 0;
  fi;

  echo "$(date +%Y:%m:%d\ %T) vor /$QVos_d (delta: $bustate_count Dateien)" >> "$PROT";
  printf "  ${blau}kopiermt_delta${reset} /${QVos_d}: ${blau}%s${reset} Dateien\n" "$bustate_count";

  # --- Quelle prüfen ---
  _QVofs_real=$(echo "$QVofs_d/" | sed 's/\\ / /g');
  if ! eval "$qssh 'test -e \"/${QVos_d}\"'" 2>/dev/null; then
    printf "${rot}/%s auf ${blau}%s${rot} nicht vorhanden – übersprungen${reset}\n" \
      "$QVos_d" "${QL:-lokal}";
    rm -f "$_tmplist"; return 0;
  fi;

  # --- Erreichbarkeit prüfen ---
  local _pc;
  for _pc in "$QL" "$ZL"; do
    [ "$_pc" ] && {
      if ! ping -c1 -W1 "$_pc" >/dev/null 2>&1; then
        printf "${rot}%s nicht anpingbar – übersprungen${reset}\n" "$_pc";
        rm -f "$_tmplist"; return 1;
      fi;
    };
  done;

  # --- Zielverzeichnis berechnen (wie in kopiermt) ---
  if [ -z "$2" ] || [ "$2" = "..." ]; then
    ZVofs_d="${QVofs_d%/*}/";
    [ "$ZVofs_d" = "$QVofs_d/" ] && ZVofs_d="";
  else
    ZVofs_d=$(printf '%s' "${2#/}" | sed 's/\([^\\]\) /\1\\ /g');
  fi;
  ZVos_d=${ZVofs_d%/}; ZVofs_d="${ZVos_d}/";
  [ "$obsub_d" ] && { [ -z "$2" ] || [ "$2" = "..." ]; } && \
    ZVos_d="${ZVos_d}/${QVofs_d##*/}";
  ZVos_d="${ZVos_d#/}"; ZVofs_d="${ZVofs_d#/}";

  # --- Zielverzeichnis anlegen ---
  if [ "$obecht" ]; then
    if [ "$ZL" ]; then
      $zssh "mkdir -p \"/$ZVos_d\"" 2>/dev/null || true;
    else
      mkdir -p "/$ZVos_d" 2>/dev/null || true;
    fi;
  else
    printf "  Simulation: mkdir -p /%s\n" "$ZVos_d";
  fi;

  # --- Rsync mit --files-from aufrufen ---
  local _ergae _Quelle _ZVofs_real _bef _ret;
  { [ "$QL" ] || [ "$ZL" ]; } && _ergae="--rsync-path='$kopbef'" || _ergae=;
  _ZVofs_real=$(printf '%s' "$ZVofs_d" | sed 's/\\ / /g');
  _Quelle="${QmD}/${_QVofs_real}";
  [ "$QL" ] && _Quelle="\"$_Quelle\"";
  _bef="$kopbef --files-from=\"$_tmplist\" $_Quelle \"${ZmD}/${_ZVofs_real}\" -avX ${4:+$4} ${_ergae:+$_ergae}";
  _ret=0;
  if [ "$obecht" ]; then
    ausf "$_bef" "$dblau" 1;
    _ret=${ret:-0};
  else
    printf "Befehl wäre: %b%s%b\n" "$dblau" "$_bef" "$reset";
  fi;

  # In EXGES aufnehmen (wie kopiermt)
  eval "$qssh 'test -d \"/$QVos_d\"'" 2>/dev/null && EXGES="${EXGES},/$QVos_d/";
  [ "$verb" ] && printf "EXGES: %b%s%b\n" "$blau" "$EXGES" "$reset";

  rm -f "$_tmplist";
  return $_ret;
} # kopiermt_delta

kopieros() {
  # $1 = Dateiname oder Verzeichnisname unter /root/
  # Bei Einzeldateien (z.B. .fbcredentials): Schutzdatei in ~ prüfen
  # Bei Verzeichnissen: Schutzdatei im Verzeichnis prüfen (bisheriges Verhalten via kopiermt)
  machssh;
  _ist_datei=;
  # Prüfen ob $1 eine einzelne Datei ist (auf Quellrechner):
	if eval "$qssh 'test -f /root/$1'" 2>/dev/null; then
		_ist_datei=1;
	elif ! eval "$qssh 'test -e /root/$1'" 2>/dev/null; then
		printf "${rot}/root/$1 auf Quelle nicht gefunden – überspringe$reset\n";
		return 0;
	fi;
  # SD-Modus: kein SD-Vergleich in ~, Einzeldateien überspringen
  if [ "$sdneu" ]; then
    [ -z "$_ist_datei" ] && kopiermt "root/$1" "root" "" "--exclude='.*.swp'" "" "" 1;
    return 0;
  fi;
  if [ "$_ist_datei" ]; then
    # Einzeldatei – Schutzdateien in ~ vergleichen (Inhalt per SHA-256, gecacht pro Session, alle aus SDLISTE muessen passen)
    if [ -z "$_kopieros_sd_geprueft" ]; then
      _kopieros_sd_geprueft=1;
      _kopieros_sd_status=ok; # ok | fehlt_quelle | abweichung
      for _sd in "${SDLISTE[@]}"; do
        _ksdq=$(eval "$qssh 'sha256sum /root/$_sd 2>/dev/null'"|cut -d' ' -f1);
        _ksdz=$(eval "$zssh 'sha256sum /root/$_sd 2>/dev/null'"|cut -d' ' -f1);
        if [ -z "$_ksdq" ]; then
          # a) Fehlt auf Quelle
          printf "${rot}Schutzdatei /root/$_sd auf Quelle nicht gefunden${reset} – sensitive Dateien werden übersprungen\n";
          _kopieros_sd_status=fehlt_quelle;
          break;
        elif [ -z "$_ksdz" ]; then
          # b) Fehlt auf Ziel – Ziel frisch, kein Fehler, weitere Schutzdateien der Liste noch prüfen
          printf "${blau}Schutzdatei /root/$_sd auf Ziel nicht vorhanden${reset} – Ziel frisch, kopiere\n";
        elif [ "$_ksdq" != "$_ksdz" ]; then
          # c) Beide vorhanden, Inhalt (SHA-256) weicht ab – immer blockieren
          printf "${rot}Schutzdatei /root/$_sd in ~ inhaltlich verschieden${reset} (Q: $blau$_ksdq$reset / Z: $blau$_ksdz$reset) – sensitive Dateien werden übersprungen\n";
          _kopieros_sd_status=abweichung;
          break;
        fi;
      done;
    fi;
    if [ "$_kopieros_sd_status" != ok ]; then
      return 1;  # Meldung bereits in Cache-Block ausgegeben
    fi;
    # alle Schutzdateien identisch (oder auf Ziel frisch) – Kopie durchführen:
		ausf "$kopbef -avuX --no-owner --no-group ${QmD}/root/$1 ${ZmD}/root/" "$dblau" 1;
		# .ssh-Rechte auf Ziel absichern (SSH-Key-Auth darf nicht brechen):
		# /root Eigentümer + Rechte wiederherstellen (rsync kann sie verändern)
		if [ "$ZL" ]; then
		  eval "$zssh 'chown root:root /root; chmod 700 /root; setfacl -m mask::x /root 2>/dev/null; [ -d /root/.ssh ] && { chown root:root /root/.ssh; chmod 700 /root/.ssh; chmod 600 /root/.ssh/authorized_keys 2>/dev/null; }'";
		else
		  chown root:root /root; chmod 700 /root; setfacl -m mask::x /root 2>/dev/null;
		  [ -d /root/.ssh ] && { chown root:root /root/.ssh; chmod 700 /root/.ssh; chmod 600 /root/.ssh/authorized_keys 2>/dev/null; };
		fi;
  else
    # Verzeichnis – --chmod=D0700 setzt /root-Rechte direkt, kein ControlMaster nötig
    if [ "$ZL" ]; then
      kopiermt "root/$1" "root" "" "--no-owner --no-group --no-perms --chmod=D0700 --exclude='.*.swp'" "" "" 1;
      ssh $(_backup_sshopts "$ZL") "$ZL" 'chown root:root /root; chmod 700 /root; setfacl -m mask::x /root 2>/dev/null; [ -d /root/.ssh ] && { chown root:root /root/.ssh; chmod 700 /root/.ssh; chmod 600 /root/.ssh/authorized_keys 2>/dev/null; }' 2>/dev/null || true;
    else
      kopiermt "root/$1" "root" "" "--no-owner --no-group --no-perms --chmod=D0700 --exclude='.*.swp'" "" "" 1;
      chown root:root /root; chmod 700 /root; setfacl -m mask::x /root 2>/dev/null;
      [ -d /root/.ssh ] && { chown root:root /root/.ssh; chmod 700 /root/.ssh;
        chmod 600 /root/.ssh/authorized_keys 2>/dev/null; };
    fi;
  fi;
}

# Backup-Heartbeat: schreibt/ersetzt eine Zeile in linux1:/DATA/Backup-Status_<Zielrechner>.txt,
# eine Datei je Zielrechner, eine Zeile je aufrufendem Skript (bumo.sh/bunacht.sh/bulinux.sh).
# $1 = Status (Standard: OK). Zielrechner: im Push-Modus $ZL, im Pull-Modus (ZL leer) der
# eigene Rechner ($buhost). Die Datei liegt immer auf linux1 - im Pull-Modus also per ssh
# auf $QL geschrieben, im Push-Modus lokal (da dann auf linux1 gelaufen wird).
backupstatus() {
  local _bs_status="${1:-OK}";
  local _bs_skript="$(basename "${MUPR:-$0}")";
  local _bs_ziel="${ZL:-$buhost}";
  local _bs_datei="/DATA/Backup-Status_${_bs_ziel}.txt";
  local _bs_zeile;
  _bs_zeile="$(printf '%-12s %s  %s' "$_bs_skript" "$(date '+%Y-%m-%d %H:%M:%S')" "$_bs_status")";
  local _bs_cmd="mkdir -p /DATA 2>/dev/null; touch \"$_bs_datei\" 2>/dev/null; { grep -v \"^$_bs_skript \" \"$_bs_datei\" 2>/dev/null; echo \"$_bs_zeile\"; } | sort -o \"$_bs_datei.neu\" -; mv \"$_bs_datei.neu\" \"$_bs_datei\"";
  machssh;
  if [ "$QL" ]; then
    eval "$qssh '$_bs_cmd'" 2>/dev/null;
  else
    eval "$_bs_cmd" 2>/dev/null;
  fi;
} # backupstatus

kopieretc() {
  kopiermt etc/$1 "etc/" "" "" "" "" 1
}

pruefpc() {
  [ $verb ]&&printf "${blau}pruefpc()$reset \"$1\", aufgerufen aus \"$2\"\n";
  [ "$1" ]||break;
  for iru in 1 2; do
    [ $verb ]&&printf "iru: $iru, vor ping -c1 -W10 \"$1\" \>/dev/null 2\>\&1\n"
    if ping -c1 -W10 "$1" >/dev/null 2>&1; then break; fi;
    [ $verb ]&&printf "iru: $iru, nach ping -c1 -W10 \"$1\" \>/dev/null 2\>\&1\n"
    if [ $iru = 1 -a ! $2/ = kurz/ ]; then
      transverb=; [ $verb ]&&transverb=-v;
      weckalle.sh "$1" -grue $transverb; # muss noch klären, warum er ohne grue linux8 nicht weckt
      [ $verb ]&&printf "Nach weckalle.sh\n";
      seqmax=100;
      for ii in $(seq 1 1 $seqmax); do # 100
        [ $verb ]&&printf "ii: $ii, vor ping -c1 -W10 \"$1\" \>/dev/null 2\>\&1\n"
        ping -c1 -W10 "$1" >/dev/null 2>&1&&{
         [ $verb ]&&printf "nach erfolgreichem ping -c1 -W10 \"$1\" \>/dev/null 2\>\&1\n"
         [ $gewdat ]||gewdat=${MUPR%/*}/geweckt$(date +%s); #  $((1 + $RANDOM % 100000))
         [ $verb ]&&printf "${blau}gewdat: ${lila}$gewdat$reset\n";
         [ $verb ]&&printf "füge $1 hinzu\n";
         if [ -f "$gewdat" ]; then  # geweckten PC zusätzlich in $gewdat eintragen, falls noch nicht enthalten
           cat $gewdat|grep -q "$1"||printf "$1 " >>$gewdat;
         else
           printf "$1 " >$gewdat;
         fi;
         [ "$verb" ]&&{ gdi=;[ $gewdat ]&&gdi="$(cat "$gewdat" && echo .)"; gdi=${gdi%.}; printf "${lila}gewdat: ${blau}%s$reset\n" "$gdi";};
         break;
        } #         ping -c1 -W10 "$1" >/dev/null 2>&1&&
       [ $verb ]&&printf "ii: $ii, nach erfolglosem ping -c1 -W10 \"$1\" \>/dev/null 2\>\&1\n"
      done;
      [ $verb ]&&printf "nach for ii in \$(seq 1 1 $seqmax)\n";
    else
     printf "$1 nicht erreichbar";[ ! $2/ = kurz/ ]&&printf "und nicht weckbar.";printf " Lasse ihn aus.\n";
     return 1;
    fi;
  done;
  printrueck=;
  for iru in $(seq 1 1 60); do
   if ssh "$1" echo '' >/dev/null 2>&1; then printf "\r"; break; fi;
   printrueck=1;
   sleep 1;
   printf ".";
  done;
  [ $printrueck ]&&printf "\r";
  ssh "$1" echo '' >/dev/null 2>&1 &&retu=0||retu=1;
  [ $verb ]&&printf "Ende ${blau}pruefpc()$reset \"$1\", aufgerufen aus \"$2\", retu: $retu\n";
  return $retu;
} # pruefpc

gutenacht() {
  [ $verb ]&&printf "${blau}gutenacht()$reset\n";
  if [ "$gewdat" -a -f "$gewdat" ]; then 
    [ "$verb" ]&&printf "${rot}gewdat: ${blau}%s$reset\n ${blau}%s$reset\n" "$gewdat" "$(cat "$gewdat")";
    for pc in $(cat "$gewdat");do  
     printf "${lila}Fahre PC $blau$pc$lila herunter!$reset\n";
     ssh $pc shutdown now;
    done;
    rm "$gewdat";
  fi;
} # gutenacht

# eingeschraenkter Key fuer den Push-Kanal linux1->linux0/linux7 (bumo.sh/bunacht.sh):
# statt des normalen root-Keys, damit ein kompromittiertes linux1 dort keine freie
# Shell bekommt (s. backup_ssh_wrapper.sh, Anleitung_Ransomware_Vorsorge_und_Notfall.md).
# Wirkt nur beim ZIEL linux0/linux7 - der Pull-Kanal (bulinux.sh auf linux0/linux7
# Richtung linux1) ist davon nicht betroffen und nutzt weiter den normalen Zugriff.
_backup_sshopts() {
  case "$1" in
    linux0|linux7) printf -- "-i /root/.ssh/id_ed25519_backup -o IdentitiesOnly=yes ";;
  esac
} # _backup_sshopts

machssh() {
[ "$QL" ]&&{ qssh="ssh $(_backup_sshopts "$QL")$QL";pruefpc "$QL" "machssh";:;}||qssh="sh -c";
[ "$ZL" ]&&{ zssh="ssh $(_backup_sshopts "$ZL")$ZL";pruefpc "$ZL" "machssh";:;}||zssh="sh -c";
# [ "$QL" ]&&qssh="ssh $QL"||qssh="sh -c";
# [ "$ZL" ]&&zssh="ssh $ZL"||zssh="sh -c";
#  [ "$verb" ]&&printf "qssh: \'$blau$qssh$reset\', zssh: \'$blau$zssh$reset\'\n";
} # machssh

testobvirt() {
  ot=opt/turbomed;
  otP=/$ot/PraxisDB;
  resD=PraxisDB-res;
  otr=/$ot/$resD;
  wserD=PraxisDB-wser;
  otw=/$ot/$wserD;
  obvirt=;
	[ $verb ]&&printf "tush: $tush: otr: $otr, otP: $otP, otw: $otw\n";
  if eval "$tush 'test -d $otr'"; then # -res gibts
    if eval "$tush 'test -d $otP'"; then # beide gibt's
      if eval "$tush 'find $otP -maxdepth 1 -size -9M -iname objects.dat|grep .' >/dev/null" &&
        eval "$tush 'find $otr -maxdepth 1 -size +10G -iname objects.dat|grep .' >/dev/null"; then
        obvirt=1;
      fi; 
    else # nur PraxisDB-res gibt's
      obvirt=1;
    fi;
  elif eval "$tush 'test -d $otw'"; then # -wser gibts
    if eval "$tush 'test -d $otP'"; then # beide gibt's
      if eval "$tush 'find $otP -maxdepth 1 -size -9M -iname objects.dat|grep .' >/dev/null" &&
        eval "$tush 'find $otw -maxdepth 1 -size +10G -iname objects.dat|grep .' >/dev/null"; then
        obvirt=2;
      fi; 
    else # nur PraxisDB-wser gibt's
      obvirt=2;
    fi;
  else
    if eval "$tush 'test -d $otP'"; then # nur PraxisDB gibt's
      obvirt=0;
  #  else # keines gibt's
    fi;
  fi;
  if [ -z "$obvirt" ]; then
    printf "${rot}Nicht ermittelbar, ob virtueller Betrieb oder nicht, breche ab.$reset\n";
    exit;
  fi;
} # testobvirt


# hier geht's los
verb=;
obecht=;
obdel=;
obforce=;
obkill=;
obmehr=;
obnv=;
obhilfe=;
obumg=;
obdt=;
obdt1=;
obdt2=;
obdt3=;
obdb=;
obdberg=;
obdbdump=;
_bu_wh_max=;
sdneu=;
nurdrei=;
nurzweidrei=;
commandline "$@"; # alle Befehlszeilenparameter übergeben, ZL aus commandline festlegen
case $0 in *bu*)
if [ \( "${0##*/}" != buint.sh -a "${0##*/}" != bumo.sh -a "${0##*/}" != bunacht.sh -a "${0##*/}" != buwser.sh -a "${0##*/}" != budbaus.sh -a "$buhost"/ = "$LINEINS"/ -a -z "$ZL" \) -o "$obhilfe" ]; then 
  case "${0##*/}" in *buint.sh)
    printf "%b\n" \
    "$blau$0$reset, Syntax: $blau"$(basename $0)" <-e/-f/-k/-m/-mz <zahl>/-z \"\"> <zielhost> <SD=/Pfad/zur/Schutzdatei>$reset" \
    " ${blau}SD[=/Pfad/zur/Schutzdatei]${reset} bewirkt Kopieren jener Datei auf alle Quellen und Ziele und anschließenden Vergleich dieser Dateien vor jedem Kopiervorgang" \
    " ${blau}-e${reset} bewirkt echten Lauf" \
    " ${blau}-f${reset} bewirkt, dass auch kopiert wird, wenn die Testdatei ${blau}objects.dat${reset} nicht aelter ist" \
    " ${blau}-h${reset} bewirkt das Anzeigen dieser Hilfe" \
    " ${blau}-k${reset} bewirkt, dass ggf. die virtuellen Windows-Server neu gestartet werden, wenn gesperrt" \
    " ${blau}-m${reset} bewirkt, dass noch mehr getan wird (Dateien auf ${blau}/opt${reset} auf andere Server kopiert und von dort aus auf die virtuallen Windowsserver)" \
    " ${blau}-mz${reset} maximale Zeilenzahl für Ergebnisausgaben" \
    " ${blau}-nz${reset} bewirkt, dass nur der 2. + 3. Teil (auf Zielrechner und dort virt.Wind.<->linux kopieren) ausgeführt wird." \
    " ${blau}-nd${reset} bewirkt, dass nur der 3. Teil (auf Zielrechnern virt.Wind.<->linux kopieren) ausgeführt wird." \
    " ${blau}-z|--zielev${reset} verwendet den nächsten Parameter zur Bestimmung der Kopierziele, z.B. '0 7' => linux0, linux7" \
    " ${blau}-v${reset} bewirkt gesprächigere Ausgabe";
    ;; *butm.sh)
    printf "%b\n" \
    "$blau$0$reset, Syntax: $blau"$(basename $0)" <-d/-e/-f/-k/-m/-mz <zahl>/-nv/-z \"\"> <zielhost> <SD=/Pfad/zur/Schutzdatei>$reset" \
    " ${blau}-d$reset bewirkt auf dem Zielrechner Loeschen der auf dem Quellrechner nicht vorhandenen Dateien" \
    " ${blau}SD[=/Pfad/zur/Schutzdatei]${reset} bewirkt Kopieren jener Datei auf alle Quellen und Ziele und anschließenden Vergleich dieser Dateien vor jedem Kopiervorgang" \
    " ${blau}-e${reset} bewirkt echten Lauf" \
    " ${blau}-f${reset} bewirkt, dass auch kopiert wird, wenn die Testdatei ${blau}objects.dat${reset} nicht aelter ist" \
    " ${blau}-h${reset} bewirkt das Anzeigen dieser Hilfe" \
    " ${blau}-k${reset} bewirkt, dass ggf. die virtuellen Windows-Server neu gestartet werden, wenn gesperrt" \
    " ${blau}-mz${reset} maximale Zeilenzahl für Ergebnisausgaben" \
    " ${blau}-nv${reset} bewirkt, dass die Dateien auf dem virtuellen Windows-Server nicht mit kopiert werden." \
    " ${blau}-z|--zielev${reset} verwendet den nächsten Parameter zur Bestimmung der Kopierziele, z.B. '0 7' => linux0, linux7" \
    " ${blau}-v${reset} bewirkt gesprächigere Ausgabe";
  ;; *bulinux.sh)
    printf "%b\n" \
    "$blau$0$reset, Syntax: $blau"$(basename $0)" [-dt|-dt1|-dt2|-dt3|-db|-dberg] [-u] [-e] [-f] [-v] [-wh [n]] [-h] [SD[=/Pfad/zur/SD]] <zielhost>$reset" \
    " ${blau}Zielhost${reset}          Zielrechner (z.B. linux0, linux7); leer wenn lokal" \
    " ${blau}-dt${reset}               Dateitransfer (dt1+dt2); Datenbank wird ausgelassen" \
    " ${blau}-dt1${reset}              nur Konfigdateien+MO (nicht /DATA); kein DB-Transfer" \
    " ${blau}-dt2${reset}              nur Windows-Shares (/mnt/wser, /mnt/anmmw); kein DB-Transfer" \
    " ${blau}-dt3${reset}              nur /DATA-Verzeichnisse; kein DB-Transfer" \
    " ${blau}-dt1${reset}              nur Konfigdateien+MO (nicht /DATA); kein DB-Transfer" \
    " ${blau}-dt2${reset}              nur Windows-Shares (/mnt/wser, /mnt/anmmw); kein DB-Transfer" \
    " ${blau}-dt3${reset}              nur /DATA-Verzeichnisse; kein DB-Transfer" \
    " ${blau}-dt1 -db${reset}          Konfigdateien+MO UND Datenbank (kein /DATA)" \
    " ${blau}-dt2 -db${reset}          Windows-Shares UND Datenbank" \
    " ${blau}-dt3 -db${reset}          /DATA UND Datenbank (keine Konfigdateien)" \
    " ${blau}-db${reset}               nur Datenbank; Dateitransfer wird ausgelassen" \
    " ${blau}SD${reset}                Schutzdateien (${blau}${SDLISTE[*]}${reset}) auf alle Zielverz. verteilen (kein Datei-/DB-Transfer); braucht -e fuer echten Lauf" \
    " ${blau}SD=/Pfad/Datei${reset}    verteilt nur die eine angegebene Datei (abweichender Name/Pfad möglich), statt der ganzen Liste; braucht -e fuer echten Lauf" \
    " ${blau}-e${reset}                echter Lauf (ohne: Simulation)" \
    " ${blau}-f${reset}                Vollabgleich erzwingen (ohne: inkrementell)" \
    " ${blau}-v${reset}                gesprächigere Ausgabe" \
    " ${blau}-u${reset}                 Richtung umkehren: statt Q→Z wird Z→Q kopiert (z.B. Rückspiegelung)" \
    " ${blau}-wh [n]${reset}           bei Verbindungsverlust: bis zu n mal wiederholen (Standard: 5); ohne -wh: auch 5" \
    " ${blau}-dberg${reset}            nur Datenbankvergleich anzeigen (ohne Transfer); nutzbar nach Import zur Kontrolle" \
    " ${blau}-h / -? / --help${reset}  diese Hilfe anzeigen";
    [ "$obhilfe" ] && exit 0;  # nach Hilfe beenden
  ;; esac; 
fi;;
esac;

[ "$sdneu"/ = 2/ ]&&{
  [ "$SD" -a ! -f "$SDQ" ]&&{ printf "$rot$SDQ$reset nicht gefunden. Breche ab.\n"; exit 1; }
  sed -i.bak "/^SD=/c\\SD=\"$SD\"" "$0"
  echo SD: $SD;
  echo SDQ: $SDQ;
  [ "$SD" ]||exit 0;
}

PROT=/var/log/$(echo $0|sed 's:.*/::;s:\..*::')prot.txt;
[ "$verb" ]&&printf "Prot: $blau$PROT$reset\n"
[ "$obdel" ]&&OBDEL="--delete"||OBDEL=;
[ "$verb" ]&&echo QL: $QL, ZL: $ZL;
# [ "$verb" ]&&echo `date +%Y:%m:%d\ %T` "vor chown" > $PROT
chown root:root -R /root/.ssh
chmod 600 -R /root/.ssh
