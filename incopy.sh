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
printf "Pruefe $Z\r";mountpoint -q "$Z"||{ printf "Mounte $Z ...\r"; mount "$Z";};
echo `date +"%d.%m.%Y %X"` "Fange an" >"$logf"
