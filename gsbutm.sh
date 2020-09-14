#!/bin/bash
# Gerald Schade Backup Turbomed Shellscript (gsbutm)
# stellt Sicherheitskopien der Datenbankdateien von Turbomed aus den Unterverzeichnissen PraxisDB, StammDB, Dictionary und DruckDB des uebergebenen Turbomed-Verzeichnisses auf CIFS-Laufwerken her oder kopiert diese von dort aus zurueck, wenn es feststellt, dass die Datenbank dort juenger und nicht kleiner sind

l_aend_object_dat () {
# ermittelt Name, Groesse und letztes Aenderungsdatum einer Datei "objects.dat" oder "_objects.dat" uebergebenen Verzeichnis und stellt diese in Variable DName, DGroesse, DDatum 
 Erg=""
 DGroesse=""
 DDatum=""
 DName=""
 if test -d "$1"; then
  # echo "$1 ist ein Verzeichnis"
  Zahl=$(find "$1" -maxdepth 1 -iregex '.*/_?objects.dat' -type f | wc -l) # wenn dieser Text fehlt, dann wird bei Fehlen einer Datei das aktuelle Verzeichnis durchsucht
  if (( $Zahl > 0 )); then 
   # echo "$1 hat $Zahl Dateien, somit mehr als 0"
   Erg=$(find "$1" -maxdepth 1 -iregex '.*/_?objects.dat' -type f -print0 | /usr/bin/xargs -0 ls -l --time-style="+%Y%m%d%H%M%S" | sort -r -k6 | head --lines=1 | tr -s " " | cut -d " " -f 5,6,7-)
   DGroesse=$(expr match "$Erg" '\([^ ]*\) .*')
   DDatum=$(expr match "$Erg" '[^ ]* \([^ ]*\) .*')
   DName=$(expr match "$Erg" '[^ ]* [^ ]* \(.*\)')
   echo $2":" $DName ", Groesse" $DGroesse ", Datum:" $DDatum >> "$protDat" 2>>"$protFeh"
  fi
 fi
}

Kopiere () {
# kopiert die Turbomeddatenbanken PraxisDB, StammDB, Dict und DruckDB auf das cifs-Laufwerk und schreibt in die Protokolldateien
    echo `date +'%Y-%m-%d %H:%M:%S'` "Fuehre aus: 'ionice -c 3 rsync -avuz --iconv=utf8,iso885915 \""$VerzQ/$UVz"\" \""$VerzZ/$UVz"\" | tail --lines=2 >> \"$protDat\" 2>>\"$protFeh\"'" >> "$protDat" 2>>"$protFeh" 
    echo `date +'%Y-%m-%d %H:%M:%S'` "Beginn rsync aus gsbutm \""$1"\" \""$2"\" \""$3"\" Kopiere(): 'ionice -c 3 rsync -avuz --iconv=utf8,iso885915 \""$VerzQ/$UVz"\" \""$VerzZ/$UVz"\" | tail --lines=2 >> \"$protDat\" 2>>\"$protFeh\"'" >> "$protrsync"
###################
    ionice -c 3 rsync -avuz --delete --iconv=utf8,iso885915 "$VerzQ/$UVz/" "$VerzZ/$UVz" | tail --lines=2 >> "$protDat" 2>>"$protFeh"
###################
    echo `date +'%Y-%m-%d %H:%M:%S'`" Ende rsync aus gsbutm \""$1"\" \""$2"\" \""$3"\" Kopiere(): 'ionice -c 3 rsync -avuz --iconv=utf8,iso885915 \""$VerzQ/$UVz"\" \""$VerzZ/$UVz"\" | tail --lines=2 >> \"$protDat\" 2>>\"$protFeh\"'" >> "$protrsync"
}

Rueckkopiere () {
# kopiert die Turbomeddatenbanken PraxisDB, StammDB, Dict und DruckDB aus dem cifs-Laufwerk wieder zurück und schreibt in die Protokolldateien
    echo `date +'%Y-%m-%d %H:%M:%S'` "Fuehre aus: 'ionice -c 3 rsync -avuz --iconv=iso885915,utf8 \""$VerzZ/$UVz"\" \""$VerzZ/$UVz"\" | tail --lines=2 >> \"$protDat\" 2>>\"$protFeh\"'" >> "$protDat" 2>>"$protFeh" 
    echo `date +'%Y-%m-%d %H:%M:%S'` "Beginn rsync aus gsbutm \""$1"\" \""$2"\" \""$3"\" Rueckkopiere(): 'ionice -c 3 rsync -avuz --iconv=iso885915,utf8 \""$VerzZ/$UVz"\" \""$VerzZ/$UVz"\" | tail --lines=2 >> \"$protDat\" 2>>\"$protFeh\"'" >> "$protrsync"
 
###################
   ionice -c 3 rsync -avuz --iconv=iso885915,utf8 "$VerzZ/$UVz/" "$VerzQ/$UVz" | tail --lines=2 >> "$protDat" 2>>"$protFeh"
###################
    echo `date +'%Y-%m-%d %H:%M:%S'` "Ende rsync aus gsbutm \""$1"\" \""$2"\" \""$3"\" Rueckkopiere(): 'ionice -c 3 rsync -avuz --iconv=iso885915,utf8 \""$VerzZ/$UVz"\" \""$VerzZ/$UVz"\" | tail --lines=2 >> \"$protDat\" 2>>\"$protFeh\"'" >> "$protrsync"
}

umben () {
 echo `date +'%Y-%m-%d %H:%M:%S'` "Benenne um: \"$1\" -> \"$1_"`date "+%Y%m%d_%H%M%S"` >> "$protDat" 2>>"$protFeh"
################### mv "$1" "$1"_`date "+%Y%m%d_%H%M%S"` ################### # echo "Benenne um: alle Dateien in " $1
  # zahl=0
  # Anhang=`date "+%Y%m%d_%H%M%S"`
  # while read file; do
  #   mv "$file" "$file"_$Anhang
  #   ((zahl+=1))
  # done < <( find $1 -type f )
  # echo $zahl "Dateien umbenannt mit: '$Anhang'"
}


# Hier fängt das Hauptprogramm an
# CifsV="/mnt/anmeldl/daten"
# VerzQ="/opt/turbomed"
# VerzZ="/mnt/anmeldl/turbomed"
protDat="/var/log/gsbutm.log"
protFeh="/var/log/gsbutmfehler.log"
protrsync="/var/log/rsync.log"

# wenn weniger oder mehr als 3 Befehlszeilenparameter übergeben werden, dann Anzeige der Syntax dieses Skripts anstatt Ausführung desselben
if (( $# != 3)); then
 echo "Syntax: $0 <Mount-Verzeichnis> <Quellverzeichnis ohne Endslash> <Zielverzeichnis ohne Endslash>"
 exit
fi
# Streichen eventueller abschließender "/" der Befehlszeilenparameter
if test ${1:$((${#1}-1)):1} == "/"; then CifsV=${1:0:$((${#1}-1))};else CifsV=$1; fi # letztes "/" streichen
if test ${2:$((${#2}-1)):1} == "/"; then VerzQ=${2:0:$((${#2}-1))};else VerzQ=$2; fi # letztes "/" streichen
if test ${3:$((${#3}-1)):1} == "/"; then VerzZ=${3:0:$((${#3}-1))};else VerzZ=$3; fi # letztes "/" streichen
echo $CifsV, $VerzQ, $VerzZ
echo "" >> "$protDat" 
echo `date "+%Y%m%d_%H%M%S"` >> "$protFeh"
echo "VerzQ=$VerzQ, VerzZ=$VerzZ, CifsV=$CifsV " >> "$protDat" 2>>"$protFeh"
# CIFS-Laufwerke sicherheitshalber starten
if test -z "$(mount | grep "${CifsV}")"; then
 /etc/init.d/cifs start
fi
if test ! -z "$(mount | grep "${CifsV}")"; then
# echo $CifsV gemountet
 date "+  Untersuche: %d.%m.%Y %H:%M:%S" >> "$protDat" 2>>"$protFeh"
# z1 mit der aktuellen Sekundenzahl belegen, um später die Laufdauer ausgeben zu können
 z1=`date +%s`
# für jedes der Unterverzeichnisse PraxisDB, StammDB, Dictionary und DruckDB anhand des Zeitstempels der Datei "objects.dat" oder einer Kopie derselben überprüfen, ob Sicherheitskopie der Datenbank erstellt werden muß oder Rückkopie und diese dann für alle darin enthaltenen Dateien umsetzen
 for UVz in "PraxisDB" "StammDB" "Dictionary" "DruckDB"; do
  l_aend_object_dat "$VerzQ/$UVz" "Indexdatei Quellverzeichnis"
  QGro=$DGroesse
  QDat=$DDatum
  QNam=$DName
  l_aend_object_dat "$VerzZ/$UVz" "Indexdatei Zielverzeichnis "
  ZGro=$DGroesse
  ZDat=$DDatum
  ZNam=$DName
  aktDat=`date "+%Y%m%d%H%M%S"`
  diff=$((aktDat-ZDat))
  echo "Zeitdifferenz der Zieldatei zu jetzt: $diff" >> "$protDat" 2>>"$protFeh"
  if (( diff < -10000 )); then
   echo -e "Zeitstempel der Datei \n       "$DName"\n liegt mit \n       "$ZD"\nmehr als eine Stunde in der Zukunft. Breche ab." >> "$protDat" 2>>"$protFeh"
   exit
  fi
#  QDat="20110819231244"
#  QDat="20110811231244"
#  QGro="7"
#  QGro="11111111111111111"
#  echo $QGro, $ZGro, $QDat, $ZDat
  if   ((QGro>=ZGro)) && ((QDat>=ZDat));  then  # if [[ ( QGro -gt ZGro ) && ( QDat -gt ZDat ) ]] ;  then
    echo "Kopieren eindeutig" >> "$protDat" 2>>"$protFeh"                                #  => einfach kopieren
    Kopiere $*
  elif ((QGro>=ZGro)) && ((QDat<ZDat)); then  #    [[ ( QGro -gt ZGro ) && ( QDat -le ZDat ) ]] ;  then
    echo "Groesse zwar groesser, aber Datum kleiner gleich" >> "$protDat" 2>>"$protFeh"      #  => Sicherheitskopie, dann kopieren
    umben "$VerzZ/$UVz"
    Kopiere $*
  elif ((QGro<ZGro)) && ((QDat>=ZDat)); then   #   [[ ( QGro -le ZGro ) && ( QDat -gt ZDat ) ]] ;  then
    echo "Groesse zwar kleiner gleich, aber Datum groesser"  >> "$protDat" 2>>"$protFeh"     #   => Sicherheitskopie, dann kopieren
    umben "$VerzZ/$UVz"
    Kopiere $*
  elif ((QGro<ZGro)) && ((QDat<ZDat)); then  #   [[ ( QGro -le ZGro ) && ( QDat -le ZDat ) ]] ;  then
    echo "Rückkopieren eindeutig"  >> "$protDat" 2>>"$protFeh"                           # => Sicherheitskopie der Quelle, dann rückkopieren
    umben "$VerzQ/$UVz"
    Rueckkopiere $*
  fi
 done
 z2=`date +%s`
 echo "        "`date "+Ende: %d.%m.%Y %H:%M:%S"`" ("$((z2-z1))" s)" >> "$protDat" 2>>"$protFeh"
else
 echo "$CifsV nicht gemountet!" >> "$protDat" 2>>"$protFeh"
fi
echo "" >> "$protDat"
echo "" >> "$protFeh" 
tail ""$protDat"" --lines=20
