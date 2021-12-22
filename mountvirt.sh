#!/bin/bash
ftb="/etc/fstab";
cre="/home/schade/.wincredentials"
# zur Funktionsfaehigkeit auf den Reservesystemen: scp -p linux1:/home/schade/.wincredentials /home/schade/
blau="\033[1;34m";
dblau="\033[0;34;1;47m";
rot="\033[1;31m";
reset="\033[0m";
MUPR=$(readlink -f $0); # Mutterprogramm

# Befehlszeilenparameter auswerten
commandline() {
  verb=;
  oballe=;
	while [ $# -gt 0 ]; do
    para=${1#[-/]};
		case $para in
      a) oballe=a;;
      v) verb=v;;
		esac;
		[ "$verb" = 1 ]&&printf "Parameter: $blau-v$reset => gesprächig\n";
		shift;
	done;
	if [ "$verb" ]; then
		printf "oballe: $blau$oballe$reset\n";
	fi;
} # commandline

# $1 = Befehl, $2 = Farbe, $3=obdirekt (ohne Result, bei Befehlen z.B. wie "... && Aktv=1" oder "sh ...")
# in dem Befehl sollen zur Uebergabe erst die \ durch \\ ersetzt werden, dann die $ durch \$ und die " durch \", dann der Befehl von " eingerahmt
ausf() {
	[ "$verb" -o "$2" ]&&{ anzeige=$(echo "$2$1$reset\n"|sed 's/%/%%/'); printf "$dblau$anzeige$reset";}; # escape für %, soll kein printf-specifier sein
	if test "$3"; then 
    eval "$1"; 
  else 
    resu=$(eval "$1"); 
  fi;
  ret=$?;
  [ "$verb" ]&&{
    printf "ret: $blau$ret$reset"
    [ "$3" ]||printf ", resu: \"$blau$resu$reset\"";
    printf "\n";
  }
} # ausf

commandline "$@"; # alle Befehlszeilenparameter übergeben
if ! test -f "$cre"; then 
  echo Datei $cre nicht gefunden, breche ab!!;
else
  ergae=;
  [ "$HOST" ]||HOST=$(hostname);
  gausw="linux0 linux1 linux7";
  [ "$oballe" ]&&auswahl=$gausw||auswahl=${HOST%%.*};
  for iru in 1 2; do
   for wirt in $gausw; do
.   ${MUPR%/*}/virtnamen.sh # legt aus $wirt fest: $gpc, $gast, $tush
#   case $wirt in *0*) gpc=virtwin0; gast=Wind10;;
#                 *1*) gpc=virtwin;  gast=Win10;;
#                 *7*) gpc=virtwin7; gast=Wi10;;
#   esac;
# case $wirt in $LINEINS)tush="sh -c";;*)tush="ssh $wirt";;esac
     [ "$verb" ]&&echo iru: $iru, gpc: $gpc, wirt: $wirt, tush: $tush, gast: $gast
     cifs=/mnt/$gpc/turbomed;
     if [ "$iru" = 1 ]; then
       grep -q /$gpc/ $ftb||{ 
         [ "$ergae" ]&&ergae=$ergae\\n;
         ergae=${ergae}"//$gpc/Turbomed $cifs cifs nofail,vers=3.11,credentials=$cre,iocharset=utf8,file_mode=0777,dir_mode=0777,rw 1 2";
       };
     else
       if [ "$oballe" -o $wirt = "${HOST%%.*}" ]; then
          printf "$rot vor pgrep und nmap$reset\n"
#         ping -c1 -W100 -q $gpc &> /dev/null
#         ping -c1 -W1 -q $gpc >/dev/null 2>&1||{ 
         ausf "${tush}pgrep -f \" $gast \" >/dev/null"; pret=$ret;
         ausf "${tush}nmap -sn -T5 -host-timeout 250ms $gpc|grep -q \"Host is up\""; nret=$ret;
         [ $pret != 0 -o $nret != 0 ]&&{
           [ "$verb" ]&&echo tush: $tush, gast: $gast; 
           ausf "umount -l $cifs";
# Kommentar 22.11.21 vorläufig:
#           [ $nret != 0 ]&&{ ausf "${tush}VBoxManage controlvm \"$gast\" poweroff" $blau;}
           ausf "${tush}VBoxManage startvm $gast --type headless" $blau;
           sleep 13;
#          das Folgende ist zumindest nicht durchgehend nötig
#          ausf "ssh Administrator@$gpc netsh advfirewall firewall show rule name=Samba_aus_mountvird >NUL || netsh advfirewall firewall add rule name=\"Samba_aus_mountvirt\" dir=in action=allow protocol=tcp localport=445" $blau
         };
       fi;
       [ "$verb" ]&&printf "Prüfe Verzeichnis: $blau$cifs$reset\n";
       [ -d "$cifs" ]||mkdir -p "$cifs";
#       mountpoint -q $cifs||{ ausf "mount $cifs 2>/dev/null" $blau; }
       for vers in 3.11 3.11 3.02 3.02 3.0 3.0 2.1 2.1 2.0 2.0 1.0 1.0; do
         if ! mountpoint -q $cifs; then
           ausf "mount $cifs -t cifs -o nofail,vers=$vers,credentials=$cre,iocharset=utf8,file_mode=0777,dir_mode=0777,rw >/dev/null 2>&1" $blau
         else
    #       printf " ${blau}$cifs$reset gemountet!\n"
           break;
         fi;
       done;
       if [ $ret/ != 0/ ]; then
         echo mounten fehlgeschlagen. Jetzt müsste evtl. was getan werden mit: tush: $tush, evtl. auch Namens- und IP-Zuweisung an der Fritzbox
       fi;
     fi;
    done; # wirt in $auswahl
    if test "$iru" = 1 -a "$ergae"; then
      if grep -q "^LABEL" $ftb; then
#        [ "$verb" ]&&echo ergae: $ergae;
        ausf "sed -i.bak -e \"/^LABEL=/{i $ergae\" -e \":a;n;ba}\" $ftb" $blau;
      else
        ausf "sed -i.bak \"$ a $ergae\" $ftb" $blau;
      fi
    fi;
  done; # iru in 1 2
fi;
