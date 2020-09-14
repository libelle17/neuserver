#!/bin/bash
# Gerald Schade Backup gsbackup.sh
# stellt Sicherheitskopien von Serverzeichnissen auf Cifs-Laufwerken her oder kopiert statt dessen von dort Daten zurueck, wenn es feststellt, dass dort Dateien juenger sind, ohne in der Zukunft zu liegen

letzte_aend () {
# sucht aus übergebenem Verzeichnis und dessen Unterverzeichnissen die jüngste Datei raus und belegt die Variablen DName, DGroesse und DNmae mit deren Daten
 Erg=""
 DGroesse=""
 DDatum=""
 DName=""
 if test -d "$1"; then
  # echo "$1 ist ein Verzeichnis"
  Zahl=$(find "$1" -type f | wc -l) # wenn dieser Text fehlt, dann wird bei Fehlen einer Datei das aktuelle Verzeichnis durchsucht
  if (( $Zahl > 0 )); then 
   # echo "$1 hat $Zahl Dateien, somit mehr als 0"
   # -mmin +0: Dateien mit (falsch) zukueftigen Daten werden nicht beruecksichtigt
  echo `date +'%Y-%m-%d %H:%M:%S'` "Beginn find aus gsbackup \"$2\" \"$3\" \"$4\" \"$5\" letzte_aend: 'find "$1" -mmin +0 -type f -print0 | /usr/bin/xargs -0 ls -l --time-style="+%Y%m%d%H%M%S" | sort -r -k6 | head --lines=1 | tr -s " " | cut -d " " -f 5,6,7-'" >> "$protrsync"
###################
   Erg=$(find "$1" -mmin +0 -type f -print0 | /usr/bin/xargs -0 ls -l --time-style="+%Y%m%d%H%M%S" | sort -r -k6 | head --lines=1 | tr -s " " | cut -d " " -f 5,6,7-)
###################
  echo `date +'%Y-%m-%d %H:%M:%S'` "Ende find aus gsbackup \"$2\" \"$3\" \"$4\" \"$5\" letzte_aend: 'find "$1" -mmin +0 -type f -print0 | /usr/bin/xargs -0 ls -l --time-style="+%Y%m%d%H%M%S" | sort -r -k6 | head --lines=1 | tr -s " " | cut -d " " -f 5,6,7-'" >> "$protrsync"
#   echo "$Erg"
   DGroesse=$(expr match "$Erg" '\([^ ]*\) .*')
   DDatum=$(expr match "$Erg" '[^ ]* \([^ ]*\) .*')
   DName=$(expr match "$Erg" '[^ ]* [^ ]* \(.*\)')
#   echo "DGroesse $DGroesse"
#   echo "DDatum   $DDatum"
#   echo "DName    $DName"
  fi
 fi
}

# Beginn Hauptprogramm
# Beispielbelegungen der Kommandozeilenvariablen
#   CifsV="/mnt/anmeldl/daten"
#   VerzQ="/DATA/turbomed/Dokumente/DMP/n ix"
# VerzZ="/mnt/anmeldl/daten/turbomed/Dokumente/DMP/n ix"
# Variablenfestlegung
protDat="/root/gsbackup.prot"
protFeh="/root/gsbackupfehler.prot"
protrsync="/var/log/rsync.log"
# wenn weniger oder mehr als 3 Befehlszeilenparameter übergeben werden, dann Anzeige der Syntax dieses Skripts anstatt Ausführung desselben
if (( $# < 3)); then
 echo "Syntax: $0 <Mount-Verzeichnis> <Quellverzeichnis ohne Endslash> <Zielverzeichnis ohne Endslash> [<exclude-Muster 1> [<exclude-Muster 2> [<exclude-Muster 3 [<exclude-Muster 4]]]]"
 exit
fi
# Streichen eventueller abschließender "/" der Befehlszeilenparameter
if test ${1:$((${#1}-1)):1} == "/"; then CifsV=${1:0:$((${#1}-1))};else CifsV=$1; fi # letztes "/" streichen
if test ${2:$((${#2}-1)):1} == "/"; then VerzQ=${2:0:$((${#2}-1))};else VerzQ=$2; fi # letztes "/" streichen
if test ${3:$((${#3}-1)):1} == "/"; then VerzZ=${3:0:$((${#3}-1))};else VerzZ=$3; fi # letztes "/" streichen
echo "VerzQ=$VerzQ, VerzZ=$VerzZ, CifsV=$CifsV " >> "$protDat" 
echo `date "+%Y%m%d_%H%M%S"` >> "$protFeh"
if test -z "$(mount | grep "${CifsV}")"; then
 /etc/init.d/cifs start
fi
if test ! -z "$(mount | grep "${CifsV}")"; then
# echo $CifsV gemountet
 date "+  Untersuche: %d.%m.%Y %H:%M:%S" >> "$protDat" 2>>"$protFeh"
 z1=`date +%s`
 letzte_aend "$VerzQ" "$*"
 QD=$DDatum
 letzte_aend "$VerzZ" "$*"
 ZD=$DDatum
  aktDat=`date "+%Y%m%d%H%M%S"`
#  echo $aktDat
#  echo $ZD
  diff=$((aktDat-ZD))
  if (( diff < -10000 )); then
   echo -e "Zeitstempel der Datei \n       "$DName"\n liegt mit \n       "$ZD"\nmehr als eine Stunde in der Zukunft. Breche ab." >> "$protDat" 2>>"$protFeh"
   exit
  fi;
 date "+     Kopiere: %d.%m.%Y %H:%M:%S" >> "$protDat" 2>>"$protFeh"
 if [[ $QD < $ZD ]]; then
  echo "$QD < $ZD, Rueckkopie noetig" >> "$protDat" 2>>"$protFeh"
  echo "wegen Datei: \"$DName\"" >> "$protDat" 2>>"$protFeh"
  echo "Fuehre aus: 'ionice -c 3 rsync -avuz --iconv=iso885915,utf8 \""$VerzZ/"\" \""$VerzQ"\" | tail --lines=2 >> \"$protDat\" 2>>\"$protFeh\"'" >> "$protDat" 2>>"$protFeh" 
  echo `date +'%Y-%m-%d %H:%M:%S'` "Beginn rsync aus gsbackup \"$1\" \"$2\" \"$3\" \"$4\" \"$5\" Rueckkopie aus Hauptprogramm: 'ionice -c 3 rsync -avuz --iconv=iso885915,utf8 \""$VerzZ/"\" \""$VerzQ"\" | tail --lines=2 >> \"$protDat\" 2>>\"$protFeh\"'" >> "$protrsync"
 ###################
 ionice -c 3 rsync -avuz --iconv=iso885915,utf8 "$VerzZ/" "$VerzQ" | tail --lines=2 >> "$protDat" 2>>"$protFeh" 
 ###################
  echo `date +'%Y-%m-%d %H:%M:%S'` "Ende rsync aus gsbackup \"$1\" \"$2\" \"$3\" \"$4\" \"$5\" Rueckkopie aus Hauptprogramm: 'ionice -c 3 rsync -avuz --iconv=iso885915,utf8 \""$VerzZ/"\" \""$VerzQ"\" | tail --lines=2 >> \"$protDat\" 2>>\"$protFeh\"'" >> "$protrsync"
 else 
  echo "$QD >= $ZD, Ruekkopie nicht noetig" >> "$protDat" 2>>"$protFeh"
 fi

 if (( $# == 3 )); then
  echo "Fuehre aus: 'ionice -c 3 rsync -avuz --iconv=utf8,iso885915 --delete --ignore-errors \""$VerzQ/"\" \""$VerzZ"\" | tail --lines=2 >> \"$protDat\" 2>>"$protFeh"'" >> "$protDat" 2>>"$protFeh" 
    echo `date +'%Y-%m-%d %H:%M:%S'` "Beginn rsync aus gsbackup \"$1\" \"$2\" \"$3\" \"$4\" \"$5\" Hauptprogramm: 'ionice -c 3 rsync -avuz --iconv=utf8,iso885915 --delete --ignore-errors \""$VerzQ/"\" \""$VerzZ"\" | tail --lines=2 >> \"$protDat\" 2>>\"$protFeh\"'" >> "$protrsync"
###################
  ionice -c 3 rsync -avuz --iconv=utf8,iso885915 --delete --ignore-errors "$VerzQ/" "$VerzZ" | tail --lines=2 >> "$protDat" 2>>"$protFeh"
###################
    echo `date +'%Y-%m-%d %H:%M:%S'` "Ende rsync aus gsbackup \"$1\" \"$2\" \"$3\" \"$4\" \"$5\" Hauptprogramm: 'ionice -c 3 rsync -avuz --iconv=utf8,iso885915 --delete --ignore-errors \""$VerzQ/"\" \""$VerzZ"\" | tail --lines=2 >> \"$protDat\" 2>>\"$protFeh\"'" >> "$protrsync"

# sind weitere Kommandozeilenparameter angegeben, so werden sie als Ausschlußmuster verwendet
 elif (( $# == 4 )); then
  echo "Fuehre aus: 'ionice -c 3 rsync -avuz --iconv=utf8,iso885915 --delete --ignore-errors \""$VerzQ/"\" \""$VerzZ"\" \"--exclude="$4"\" | tail --lines=2 >> \"$protDat\" 2>>\"$protFeh\"'" >> "$protDat" 2>>"$protFeh" 
    echo `date +'%Y-%m-%d %H:%M:%S'` "Beginn rsync aus gsbackup \"$1\" \"$2\" \"$3\" \"$4\" \"$5\" Hauptprogramm: 'ionice -c 3 rsync -avuz --iconv=utf8,iso885915 --delete --ignore-errors \""$VerzQ/"\" \""$VerzZ"\" \"--exclude="$4"\" | tail --lines=2 >> \"$protDat\" 2>>\"$protFeh\"'" >> "$protrsync"
###################
  ionice -c 3 rsync -avuz --iconv=utf8,iso885915 --delete --ignore-errors "$VerzQ/" "$VerzZ" --exclude="$4" | tail --lines=2 >> "$protDat" 2>>"$protFeh"
###################
    echo `date +'%Y-%m-%d %H:%M:%S'` "Ende rsync aus gsbackup \"$1\" \"$2\" \"$3\" \"$4\" \"$5\" Hauptprogramm: 'ionice -c 3 rsync -avuz --iconv=utf8,iso885915 --delete --ignore-errors \""$VerzQ/"\" \""$VerzZ"\" \"--exclude="$4"\" | tail --lines=2 >> \"$protDat\" 2>>\"$protFeh\"'" >> "$protrsync"

 elif (( $# == 5 )); then
  echo "Fuehre aus: 'ionice -c 3 rsync -avuz --iconv=utf8,iso885915 --delete --ignore-errors \""$VerzQ/"\" \""$VerzZ"\" \"--exclude="$4"\" \"--exclude="$5"\" | tail --lines=2 >> \"$protDat\" 2>>"$protFeh"'" >> "$protDat" 2>>"$protFeh" 
###################
    echo `date +'%Y-%m-%d %H:%M:%S'` "Beginn rsync aus gsbackup \"$1\" \"$2\" \"$3\" \"$4\" \"$5\" Hauptprogramm: 'ionice -c 3 rsync -avuz --iconv=utf8,iso885915 --delete --ignore-errors \""$VerzQ/"\" \""$VerzZ"\" \"--exclude="$4"\" \"--exclude="$5"\" | tail --lines=2 >> \"$protDat\" 2>>\"$protFeh\"'" >> "$protrsync"
  ionice -c 3 rsync -avuz --iconv=utf8,iso885915 --delete --ignore-errors "$VerzQ/" "$VerzZ" --exclude="$4" --exclude="$5" | tail --lines=2 >> "$protDat" 2>>"$protFeh"
###################
    echo `date +'%Y-%m-%d %H:%M:%S'` "Ende rsync aus gsbackup \"$1\" \"$2\" \"$3\" \"$4\" \"$5\" Hauptprogramm: 'ionice -c 3 rsync -avuz --iconv=utf8,iso885915 --delete --ignore-errors \""$VerzQ/"\" \""$VerzZ"\" \"--exclude="$4"\" \"--exclude="$5"\" | tail --lines=2 >> \"$protDat\" 2>>\"$protFeh\"'" >> "$protrsync"

 elif (( $# == 6 )); then
  echo "Fuehre aus: 'ionice -c 3 rsync -avuz --iconv=utf8,iso885915 --delete --ignore-errors \""$VerzQ/"\" \""$VerzZ"\" \"--exclude="$4"\" \"--exclude="$5"\" \"--exclude="$6"\" | tail --lines=2 >> \"$protDat\" 2>>\"$protFeh\"'" >> "$protDat" 2>>"$protFeh" 
    echo `date +'%Y-%m-%d %H:%M:%S'` "Beginn rsync aus gsbackup \"$1\" \"$2\" \"$3\" \"$4\" \"$5\" Hauptprogramm: 'ionice -c 3 rsync -avuz --iconv=utf8,iso885915 --delete --ignore-errors \""$VerzQ/"\" \""$VerzZ"\" \"--exclude="$4"\" \"--exclude="$5"\" \"--exclude="$6"\" | tail --lines=2 >> \"$protDat\" 2>>\"$protFeh\"'" >> "$protrsync"
###################
  ionice -c 3 rsync -avuz --iconv=utf8,iso885915 --delete --ignore-errors "$VerzQ/" "$VerzZ" --exclude="$4" --exclude="$5" --exclude="$6" | tail --lines=2 >> "$protDat" 2>>"$protFeh"
###################
    echo `date +'%Y-%m-%d %H:%M:%S'` "Ende rsync aus gsbackup \"$1\" \"$2\" \"$3\" \"$4\" \"$5\" Hauptprogramm: 'ionice -c 3 rsync -avuz --iconv=utf8,iso885915 --delete --ignore-errors \""$VerzQ/"\" \""$VerzZ"\" \"--exclude="$4"\" \"--exclude="$5"\" \"--exclude="$6"\" | tail --lines=2 >> \"$protDat\" 2>>\"$protFeh\"'" >> "$protrsync"

 elif (( $# == 6 )); then
  echo "Fuehre aus: 'ionice -c 3 rsync -avuz --iconv=utf8,iso885915 --delete --ignore-errors \""$VerzQ/"\" \""$VerzZ"\" \"--exclude="$4"\" \"--exclude="$5"\" \"--exclude="$6"\" \"--exclude="$7"\" | tail --lines=2 >> \"$protDat\" 2>>"$protFeh"'" >> "$protDat" 2>>"$protFeh" 
    echo `date +'%Y-%m-%d %H:%M:%S'` "Beginn rsync aus gsbackup \"$1\" \"$2\" \"$3\" \"$4\" \"$5\" Hauptprogramm: 'ionice -c 3 rsync -avuz --iconv=utf8,iso885915 --delete --ignore-errors \""$VerzQ/"\" \""$VerzZ"\" \"--exclude="$4"\" \"--exclude="$5"\" \"--exclude="$6"\" \"--exclude="$7"\" | tail --lines=2 >> \"$protDat\" 2>>\"$protFeh\"'" >> "$protrsync"
###################
  ionice -c 3 rsync -avuz --iconv=utf8,iso885915 --delete --ignore-errors "$VerzQ/" "$VerzZ" --exclude="$4" --exclude="$5" --exclude="$6" --exclude="$7" | tail --lines=2 >> "$protDat" 2>>"$protFeh"
###################
    echo `date +'%Y-%m-%d %H:%M:%S'` "Ende rsync aus gsbackup \"$1\" \"$2\" \"$3\" \"$4\" \"$5\" Hauptprogramm: 'ionice -c 3 rsync -avuz --iconv=utf8,iso885915 --delete --ignore-errors \""$VerzQ/"\" \""$VerzZ"\" \"--exclude="$4"\" \"--exclude="$5"\" \"--exclude="$6"\" \"--exclude="$7"\" | tail --lines=2 >> \"$protDat\" 2>>\"$protFeh\"'" >> "$protrsync"
 fi
 z2=`date +%s`
 echo "        "`date "+Ende: %d.%m.%Y %H:%M:%S"`" ("$((z2-z1))" s)" >> "$protDat" 2>>"$protFeh"
else
 echo "$CifsV nicht gemountet!" >> "$protDat" 2>>"$protFeh"
fi
echo "" >> "$protDat" 2>>"$protFeh"
echo "" >> "$protFeh" 
tail ""$protDat"" --lines=20
