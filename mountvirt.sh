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
    para=$(echo "$1"|sed 's;^[-/]\+;;');
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
   for wirt in $auswahl; do
.   ${MUPR%/*}/virtnamen.sh
#   case $wirt in *0*) gpc=virtwin0; gast=Wind10;;
#                 *1*) gpc=virtwin;  gast=Win10;;
#                 *7*) gpc=virtwin7; gast=Wi10;;
#   esac;
#   case $(hostname) in $wirt*)tussh=;;*)tussh="ssh $wirt ";;esac;
     [ "$verb" ]&&echo iru: $iru, gpc: $gpc, wirt: $wirt, tussh: $tussh, gast: $gast
     if [ "$iru" = 1 ]; then
       grep -q /$gpc/ $ftb||{ 
         [ "$ergae" ]&&ergae=$ergae\\n;
         ergae=${ergae}"//$gpc/Turbomed /mnt/$gpc/turbomed cifs nofail,vers=3.11,credentials=$cre 0 2";
       };
     else
       mp=/mnt/$gpc/turbomed;
       [ "$verb" ]&&printf "Prüfe Verzeichnis: $blau$mp$reset\n";
       [ -d "$mp" ]||mkdir -p "$mp";
#      [ "$verb" ]&&echo mp: $mp, gpc: $gpc, tussh: $tussh, gast: $gast
#       ping -c1 -W1 -q $gpc >/dev/null 2>&1||{ 
       ausf "${tussh}pgrep -f \" $gast \" >/dev/null"; pret=$ret;
       ausf "${tussh}nmap -sn -T5 -host-timeout 250ms $gpc|grep -q \"Host is up\""; nret=$ret;
       [ $pret != 0 -o $nret != 0 ]&&{
         [ "$verb" ]&&echo tussh: $tussh, gast: $gast; 
         ausf "umount -l $mp";
         [ $nret != 0 ]&&{
           ausf "${tussh}VBoxManage controlvm \"$gast\" poweroff" $blau;
         }
         ausf "${tussh}VBoxManage startvm $gast --type headless" $blau;
         sleep 13;
# das Folgende ist zumindest nicht durchgehend nötig
#         ausf "ssh Administrator@$gpc netsh advfirewall firewall show rule name=Samba_aus_mountvird >NUL || netsh advfirewall firewall add rule name=\"Samba_aus_mountvirt\" dir=in action=allow protocol=tcp localport=445" $blau
       };
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
  for wirt in $gausw; do
     mountpoint -q $mp||{ ausf "mount $mp" $blau; }
  done;
fi;
