# incopy.sh - keine eigenständig ausführbare Datei, sondern gemeinsame
# Bibliothek zum Sourcen (". incopy.sh") aus den copy*.sh-Skripten
# (copyseag.sh, copytoshz.sh, copyverb.sh, copywd.sh), NACHDEM dort $PNAME
# (Anzeigename/Log-Name des externen Laufwerks) und $Z (Mountpunkt des
# Zielverzeichnisses, z.B. /amnt/toshz) gesetzt wurden. Definiert:
#   tukopier <Quelle> <Ziel> [bis zu 11 Exclude-Muster]
#     rsync -avu --delete von <Quelle>/ nach <Ziel>, nur wenn $Z gemountet
#     ist (sonst Abbruch der ganzen Shell per exit!); protokolliert Ende in
#     $logf.
#   tukopierol <...>  wie tukopier, aber mit --iconv=utf8,latin1 (für
#     Ziel-Dateisysteme mit Latin-1-Namenskodierung, z.B. ältere NTFS-Mounts)
#   datakopier <Unterpfad-unter-/DATA> [weitere Exclude-Muster]
#     bequemer Wrapper um tukopier für Pfade unterhalb von /DATA, schließt
#     dabei immer Papierkorb/ausgelagert/DBBackloe/TMBackloe/sqlloe/
#     TMExportloe mit aus.
# Beim Sourcen wird zusätzlich geprüft, ob $Z schon gemountet ist, und falls
# nicht, aber als Blockgerät bekannt (lsblk), automatisch gemountet.
logf=/var/log/$PNAME.log
#Z=/mnt/seag
Q=""
blau="\e[1;34m";
dblau="\e[0;34;1;47m";
rot="\e[1;31m";
reset="\e[0m";

tukopier() {
  printf "${blau}$0:tukopier()${reset} 1: ${blau}$1${reset} 2: ${blau}$2${reset}\n"
  mountpoint -q "$Z"||{ echo "$Z" nicht gemountet;exit;}&&{ mkdir -p "$2";ionice -c3 nice -n19 rsync -avu $par --delete "$1/" "$2" --exclude "$3" --exclude "$4" --exclude "$5" --exclude "$6" --exclude "$7" --exclude "$8" --exclude "$9" --exclude "$10" --exclude "$11" --exclude "$12" --exclude "$13";};
  echo `date +"%d.%m.%Y %X"` "Fertig mit: " "$1" >>"$logf";
}

tukopierol() {
  printf "${blau}$0:tukopierol()${reset} 1: ${blau}$1${reset} 2: ${blau}$2${reset}\n";
  par="--iconv=utf8,latin1";
  tukopier "$@";
  par=;
}

datakopier() {
  printf "${blau}$0:datakopier()${reset} 1: ${blau}$1${reset} 2: ${blau}$2${reset}\n"
  QP="/DATA";mountpoint -q "$QP"&&tukopier "$QP/$1" "$Z/DATA/$1" "Papierkorb" "ausgelagert" "DBBackloe" "TMBackloe" "sqlloe" "TMExportloe" "$2" "$3" "$4" "$5" "$6"
}

# mountpoint -q "$Z" && umount $Z
# mountpoint -q "$Z" || mount `fdisk -l 2>/dev/null | grep '  2048' | grep NTFS | cut -f1 -d' '` $Z -t ntfs-3g -O users,gid=users,fmask=133,dmask=022,locale=de_DE.UTF-8,nofail
# mountpoint -q "$Z" || mount $Z
printf "Pruefe $Z\r";mountpoint -q "$Z"||{ lsblk -oMOUNTPOINT|grep -q ^${Z}$&&{ printf "Mounte $Z ...\r"; mount "$Z";};};
echo `date +"%d.%m.%Y %X"` "Fange an" >"$logf"
