#!/bin/sh
# fehlt: /home/schade/.wincredentials, //mnt/virtwin..., mysql daten auf die Reserveserver
# blau="\e[1;34m";
blau="\033[1;34m";
dblau="\033[0;34;1;47m";
rot="\033[1;31m";
# reset="\e[0m";
reset="\033[0m";
prog="";
obnmr=1;
ftb="/etc/fstab";
GITACC=libelle17;
AUFRUFDIR=$(pwd)
# meinpfad="$(cd "$(dirname "$0")"&&pwd)"
meingespfad="$(readlink -f "$0")"; # Name dieses Programms samt Pfad
[ "$meingespfad" ]||meingespfad="$(readlink -m "$0")"; # Name dieses Programms samt Pfad
meinpfad="$(dirname $meingespfad)"; # Pfad dieses Programms ohne Name
instvz="/root/neuserver"
wzp="$instvz/wurzelplatten";
Dw="/root/Downloads";
gruppe=$(cat $instvz/gruppe);
q0="/DATA/down /DATA/daten/down";
spf=/DATA/down; # Server-Pfad
tdpf="/DATA/turbomed" # Turbomed-Dokumentenpfad
musr=praxis;
obschreiben=0;

# $1 = Befehl, $2 = Farbe, $3=obdirekt (ohne Result, bei Befehlen z.B. wie "... && Aktv=1" oder "sh ...")
# in dem Befehl sollen zur Uebergabe erst die \ durch \\ ersetzt werden, dann die $ durch \$ und die " durch \", dann der Befehl von " eingerahmt
ausf() {
	[ "$verb" -o "$2" ]&&{ anzeige=$(echo "$2$1$reset\n"|sed 's/%/%%/'); printf "$anzeige";}; # escape für %, soll kein printf-specifier sein
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

ausfd() {
  ausf "$1" "$2" direkt;
} # ausfd

# Befehlszeilenparameter auswerten
commandline() {
	obneu=0; # 1=Fritzboxbenutzer und Passwort neu eingeben, s.u.
	obteil=0;# nur Teil des Scripts soll ausgeführt werden;
  obbs=0; # bildschirm aufrufen
  obhost=0; # host setzen
  obprompt=0; # prompt setzen
  obmt=0; # nur Laufwerke sollen gemountet werden
  obprog=0; # nur Programme sollen installiert werden
  obtm=0; # ob turbomed installiert werden soll
	obmysql=0; # nur mysql soll eingerichtet werden
  obsmb=0; # nur smbconf soll aufgerufen werden
  obmust=0; # ob von musterserver kopiert werden soll
  obfritz=0; # ob fritzbox eingehaengt werden soll
	mysqlneu=0; # mysql mit Neuübertragung der Daten
  obfb=0; # Firebird
  obtv=0; # Teamviewer
  gespar="$@"
  verb=0;
	while [ $# -gt 0 ]; do
    para=$(echo "$1"|sed 's;^[-/];;');
		case $para in
			neu|new) obneu=1;obschreiben=1;;
			v|-verbose) verb=1;;
			*) obteil=1;
				case $para in
          bs) obbs=1;;
          host) obhost=1;;
          prompt) obprompt=1;;
          mt) obmt=1;;
          prog) obprog=1;;
          turbomed) obtm=1;;
					maria|mariadb|mysql) obmysql=1;;
          smb) obsmb=1;;
          must) obmust=1;;
					mysqlneu) mysqlneu=1;;
          fritz) obfritz=1;;
          firebird) obfb=1;;
          teamviewer) obtv=1;;
				esac;;
		esac;
		[ "$verb" = 1 ]&&printf "Parameter: $blau-v$reset => gesprächig\n";
		shift;
	done;
	if [ "$verb" ]; then
		printf "obneu: $blau$obneu$reset\n";
		printf "obschreiben: $blau$obschreiben$reset\n";
		[ $obteil = 1 ]&& printf "obteil: ${blau}1$reset\n"
		[ "$obbs" = 1 ]&& printf "obbs: ${blau}1$reset\n"
		[ "$obhost" = 1 ]&& printf "obhost: ${blau}1$reset\n"
		[ "$obprompt" = 1 ]&& printf "obprompt: ${blau}1$reset\n"
		[ "$obmt" = 1 ]&& printf "obmt: ${blau}1$reset\n"
		[ "$obprog" = 1 ]&& printf "obprog: ${blau}1$reset\n"
		[ "$obmysql" = 1 ]&& printf "obmysql: ${blau}1$reset\n"
		[ "$obsmb" = 1 ]&& printf "obsmb: ${blau}1$reset\n"
		[ "$obmust" = 1 ]&& printf "obmust: ${blau}1$reset\n"
		[ "$obfritz" = 1 ]&& printf "obfritz: ${blau}1$reset\n"
		[ "$mysqlneu" = 1 ]&& printf "mysqlneu: ${blau}1$reset\n"
	fi;
} # commandline

variablen() {
 printf "${dblau}variablen$reset()\n";
 qverz=/root/neuserver
 [ -s "$instvz/vars" ]||{ echo $instvz/vars fehlt, rufe auf: sh $instvz/configure; sh configure;}
 while :; do
  sed 's/:://;/\$/d;s/=/="/;s/$/"/;s/""/"/g;s/="$/=""/' "$instvz/vars" >"$instvz/shvars"
  . "$instvz/shvars"
  if test "$("$instvz/configure" nuros)" != "$OSNR"; then "$instvz/configure";:;else break;fi;
 done;
 HOMEORIG="$(getent passwd $(logname 2>/dev/null||loginctl user-status|sed -n '1s/\(.*\) .*/\1/p'||whoami)|cut -d: -f6)"; # ~  # $HOME
 loscred="$HOME/.loscred"; # ~  # $HOME
 test -f "$loscred"&&. "$loscred";
 srv0=; # zur Sicherheit
} # variablen

speichern() {
	printf "${dblau}obschreiben$reset()obschreiben: $obschreiben, loscred: $loscred\n";
	if test $obschreiben -ne 0; then
	  printf "muser=$musr\n"  >"$loscred";
	  printf "mpwd=$mpwd\n"  >>"$loscred";
	  printf "mroot=$mroot\n" >>"$loscred";
	  printf "mrpwd=$mrpwd\n" >>"$loscred";
	  printf "arbgr=$arbgr\n" >>"$loscred";
	  printf "srv0=$srv0\n"   >>"$loscred";
	fi;
} # speichern


firebird() {
	printf "${dblau}firebird$reset()\n";
	unset Vorv;
	unset Aktv;
	# zypper se -i firebird >/dev/null 2>&1 && Vorv=1;
	# sleep 10;
	ausfd "$insse FirebirdSS >/dev/null 2>&1 && Aktv=1"; # zypper se -i FirebirdSS >/dev/null 2>&1 && Aktv=1;
	[ "$verb" ]&& echo Vorv: $Vorv;
	[ "$verb" ]&& echo Aktv: $Aktv;
	[ ! $Aktv ]&&{
		ausf "systemctl stop firebird 2>/dev/null && sleep 10";
		ausf "$upr firebird"; # zypper rm
	  ausf "[ -r /usr/lib/libstdc++.so.5 ]||eval $instp ./libstdc++33-32bit-3.3.3-41.1.3.x86_64.rpm"; # zypper in 
		ausf "pkill fbguard";
		ausf "pkill fbserver";
		ausf "eval $insg ./FirebirdSS-2.1.7.18553-0.i686.rpm";
  }
  initfb=/etc/init.d/firebird;
  [ ! -f "$initfb" ]&&{
		ausf "cp ./misc/firebird.init.d.suse $initfb";
		ausf "chown root.root $initfb";
		ausf "chmod 775 $initfb";
		ausf "rm -f /usr/sbin/rcfirebird";
		ausf "ln -s $initfb /usr/sbin/rcfirebird";
		ausf "systemctl daemon-reload";
		ausf "systemctl start firebird";
		ausf "$instp libreoffice-base libreoffice-base-drivers-firebird"; # zypper in 
	}
} # firebird

setzhost() {
  printf "${dblau}setzhost$reset()\n";
  # wenn Hostname z.B. linux-8zyu o.ä., dann korrigieren;
  case $(hostname) in
  *-*|linux|linux.*|localhost*) {
      hostnamectl;
      printf "${blau}gewünschter Servername, dann Enter:$reset "; read srvhier;
      hostnamectl set-hostname "$srvhier";
      export HOST="$srvhier";
      hostnamectl; 
  };
  esac;
} # setzhost

setzbenutzer() {
  printf "${dblau}setzbenutzer$reset(), gruppe: $gruppe\n";
  pruefgruppe $gruppe
  $SPR samba 2>/dev/null||$IPR samba
  systemctl start smb 2>/dev/null||systemctl start smbd 2>/dev/null;
  systemctl enable smb 2>/dev/null||systemctl enable smbd 2>/dev/null;
  systemctl start nmb 2>/dev/null||systemctl start nmbd 2>/dev/null;
  systemctl enable nmb 2>/dev/null||systemctl enable nmbd 2>/dev/null;
  while read -r zeile <&3; do
    user=${zeile%% \"*};
    comm=\"${zeile#* \"};
    pruefuser $user "$comm";
  done 3<"$instvz/benutzer";
} # setzbenutzer

setzpfad() {
	printf "${dblau}setzpfad$reset()\n";
	RB=/root/bin;
  echo "echo $PATH|grep \"$RB\""
  if ! echo $PATH|grep "$RB" >/dev/null; then
		EEN=/etc/environment;
		if grep -q "^PATH=" "$EEN" 2>/dev/null; then # wirkt auch bei Fehlen von $EEN
			if ! grep -q "$RB" "$EEN" 2>/dev/null; then
  			sed -i.bak '/^PATH=/{s/=["'\'']\+\(.*\)["'\'']\+/="\1:'$(echo $RB|sed "s/\//\\\\\//g")'"/}' "$EEN";
			fi;
		else
			echo PATH=\"$PATH:$RB\" >>"$EEN";
		fi;
		. "$EEN";
	fi;
} # setzpfad

setzprompt() {
	printf "${dblau}setzprompt$reset()\n";
  gesnr=" $(seq 0 1 50|tr '\n' ' ')";
  for fnr in $gesnr; do
    FB="\[$(printf '\033[48;5;253;38;5;0'$fnr'm')\]";
    FBH="\[$(printf '\033[48;5;255;38;5;0'$fnr'm')\]"
    PSh="${FB}Farbe $fnr: \u@\h(."$(hostname -I|cut -d' ' -f1|cut -d. -f4)"):${FBH}\w${RESET}>"
    [ $obbash -eq 1 ]&&{
      printf "${PSh@P}";
    }||{
      printf "$(echo $PSh|sed 's/\\u/'$(whoami)'/g;s:\\w:'$(pwd|sed "s:/root:~:")':;s:\\h:'$(hostname|sed "s:\..*::")':g;s:\\\[::g;s:\\\]::g;')";
    }
    printf "$reset\n";
  done;
  nr=;
  while true; do
    case $gesnr in *" "$nr" "*)break;;esac;
    printf "Bitte die gewünschte Nummer eingeben: ";read nr;
    obschreiben=1;
  done;
  echo nr: $nr;
  BBL=/etc/bash.bashrc.local;
  echo "FNr=$nr;" >$BBL;
  echo "FB=\"\\[\$(printf '\\e[48;5;253;38;5;0'\$FNr'm')\\]\"" >>$BBL;
  echo "FBH=\"\\[\$(printf '\\e[48;5;255;38;5;0'\$FNr'm')\\]\"" >>$BBL;
  echo "RESET=\"\\[\$(printf '\\e[00m')\\]\"" >>$BBL;
  echo "PS1=\"\${FB}\\u@\\h(.\"\$(hostname -I|cut -d' ' -f1|cut -d. -f4)\"):\${FBH}\\w\${RESET}>\"" >>$BBL;
  echo "export NCURSES_NO_UTF8_ACS=1" >>$BBL;
} # setzprompt

mountlaufwerke() {
printf "${dblau}mountlaufwerke$reset()\n";
# Laufwerke einhängen
# in allen nicht auskommentierten Zeilen Leerzeichen durch einen Tab ersetzen
# fstb=$(sed -n '/^#/!{s/[[:space:]]\+/\t/g;p}' $ftb); # "^/$Dvz\>" ginge auch
ausf "sed -n '/^#/!{s/[[:space:]]\+/\t/g;p}' $ftb"; # "^/$Dvz\>" ginge auch
fstb=$resu;
# blkvar=$(lsblk -bisnPfo NAME,SIZE,FSTYPE,LABEL,UUID,MOUNTPOINT -x SIZE|grep -v 'raid_member\|FSTYPE="" LABEL=""\|FSTYPE="swap"');
ausf "lsblk -bisnPfo NAME,SIZE,FSTYPE,LABEL,UUID,MOUNTPOINT -x SIZE|grep -v 'raid_member\|FSTYPE=\"\" LABEL=\"\"\|FSTYPE=\"swap\"'";
blkvar=$resu;
# bisherige Labels DATA, DAT1 usw. und bisherige Mounpoints /DATA, /DAT1 usw. ausschließen 
# z.B. "2|1|3|A"
# bishDAT=$(echo "$blkvar"|awk '/=\"DAT/{printf substr($4,11,length($4)-11)"|";}/=\"\/DAT/{printf substr($6,17,length($6)-17)"|";}'|awk '{print substr($0,0,length($0)-1);}'); # "<- dieses Zeichen steht nur hier fuer die vi-Faerbung
# echo bishDAT: $bishDAT;
# bishwin=$(echo "$blkvar"|awk '/=\"win/{printf substr($4,11,length($4)-11)"|";}/=\"\/win/{printf substr($4,17,length($6)-17)"|";}'|awk '{print substr($0,0,length($0)-1);}');
for N in DAT win; do
  if [ $N = DAT ]; then par=6; else par=4; fi;
  ausf "echo \"\$blkvar\"|awk '/=\\\""$N"/{printf substr(\$4,11,length(\$4)-11)\"|\";}/=\\\"\\/"$N"/{printf substr(\$"$par",17,length(\$6)-17)\"|\";}'|awk '{print substr(\$0,0,length(\$0)-1);}'";
  if [ $N = DAT ]; then bishDAT=$resu; else bishwin=$resu; fi;
done;
# echo bishDAT: $bishDAT;
# echo bishwin: $bishwin;
istinfstab=0;
Dnamnr="A"; # 0=DATA, 1=DAT1, 2=DAT2 usw # linux name nr
wnamnr=1;
# Laufwerke mit bestimmten Typen und nicht-leerer UUID absteigend nach Größe
# ausf "lsblk -o NAME,SIZE,FSTYPE,LABEL,UUID,MOUNTPOINT -b -i -x SIZE -s -n -P -f|grep -v ':\|swap\|efi\|fat\|iso\|FSTYPE=\"\"\|FSTYPE=\".*_member\"\|UUID=\"\"\|MOUNTPOINT=\"/\"'|tac";
ausf "lsblk -o NAME,SIZE,FSTYPE,LABEL,UUID,MOUNTPOINT,TYPE -bidnspPx SIZE|tac";
fstabteil=$resu;
nochmal=1;
while test "$nochmal"; do # wenn eine Partition neu erstellt werden musste
  unset nochmal;
ausf "lsblk -o NAME,SIZE,FSTYPE,LABEL,UUID,MOUNTPOINT,TYPE,PARTTYPE,PTTYPE -bidnspPx SIZE|tac";
fstabteil=$resu;
# echo fstabteil: "$fstabteil";
[ "$verb" ]&&printf "fstab-Teil:\n$blau$fstabteil$reset\n";
[ "$fstabteil" ]||return;
ges=" ";
while read -r zeile; do
#	echo "Hier: " $zeile;
	dev=$(echo $zeile|cut -d\" -f2);
	fty=$(echo $zeile|cut -d\" -f6);
	lbl=$(echo $zeile|cut -d\" -f8);
	uid=$(echo $zeile|cut -d\" -f10);
	mtp=$(echo $zeile|cut -d\" -f12|sed 's/[[:space:]]//g');
	typ=$(echo $zeile|cut -d\" -f14);
	pty=$(echo $zeile|cut -d\" -f16);
	ptt=$(echo $zeile|cut -d\" -f18);
  case "$fty" in swap|iso|fat|".*_member") continue;; esac;
  case "$typ" in rom) continue;; esac;
  case "$mtp" in /|/boot/efi) continue;; esac;
  case "$lbl" in EFI) continue;; esac;
  [ "$uid" ]||continue;
  if test -z "$fty"; then
		[ "$pty" = 0xf ]&&continue; # Partitionstabelle
    case "$typ" in disk|part)
      if test "$ptt"/ != gpt/ -a "$ptt"/ != dos/; then
	      echo "Hier nochmal: " $zeile
	      ausf "mke2fs -t ext4 $dev"; 
	      nochmal=1;
	      continue;
      fi;
    esac;
  fi;
  printf "${blau}zeile$reset: $zeile\n";
  if [ "$uid" ]; then
  umbenenn=;
  if [ "$lbl" ]; then
    case $ges in 
      *" "$lbl" "*) 
        fertig=;
        for i in $(seq 1 1 500); do
          case $ges in *" "${lbl}_$i" "*);;*)fertig=1;ges="$ges${lbl}_$i ";;esac;
          [ "$fertig" ]&&break;
        done;
        printf "doppelter Name bei uid: $blau$uid$reset, mtp: $blau$mtp$reset, lbl: $blau$lbl$reset => $rot${lbl}_$i$reset\n";
        lbl=${lbl}_$i;
        umbenenn=1;;
    esac;
  else
			case "$fty" in 
				ext*|btrfs|reiserfs)
					while :;do	
						abbruch=0;
						# wenn der geplante Buchstabe noch nicht vergeben: Abbruch von while planen
						[ -z "$bishDAT" ]&&abbruch=1|| eval "case "$Dnamnr" in "$bishDAT"):;;*)false;;esac;"||abbruch=1;
						[ $abbruch -eq 1 ]&&break;
						[ "$Dnamnr" = "A" ]&&Dnamnr=1||Dnamnr=$(expr $Dnamnr + 1 );
					done;
					lbl="DAT"$Dnamnr;;
				ntfs*|exfat*|vfat)
					while :;do	
						abbruch=0;
						[ -z "$bishwin" -o "$bishwin"ß = "|ß" ]&&abbruch=1|| eval "case "$wnamnr" in "$bishwin"):;;*)false;;esac;"||abbruch=1;
						[ $abbruch -eq 1 ]&&break;
						wnamnr=$(expr $wnamnr + 1 );
					done;
					lbl="win"$wnamnr;;
			esac;
      printf "fehlender Name bei uid: $blau$uid$reset, mtp: $blau$mtp$reset, => lbl: $rot$lbl$reset\n";
      umbenenn=1;
  fi;
  [ "$lbl" ]&&ges="$ges$lbl ";
	if [ "$umbenenn" ]; then
		case "$fty" in ext*|btrfs|reiserfs|ntfs*|exfat*|vfat)
			case $fty in 
				ext*)
					printf "${rot}e2label $dev $lbl$reset\n";
          e2label $dev "$lbl" 2>/dev/null||e2label $(echo $dev|sed 's/-/\//') "$lbl";;
				btrfs)
					printf "${rot}btrfs filesystem label $dev $lbl$reset\n";
					btrfs filesystem label $dev "$lbl";;
				reiserfs)
					printf "${rot}reiserfstune -l $lbl $dev$reset\n";
					reiserfstune -l "$lbl" $dev;;
				ntfs*)
					printf "${rot} ntfslabel $dev $lbl$reset\n";
					ntfslabel $dev "$lbl";;
				exfat*)
					printf "${rot} exfatlabel $dev $lbl$reset\n";
					exfatlabel $dev "$lbl";;
				vfat)
					printf "${rot} mache vfat Label$reset\n";
					eingehaengt=0;
					mountpoint -q $dev&&{ eingehaengt=1; umount $dev;};
					env MTOOLS_SKIP_CHECK=1 mlabel -i $dev ::x;
					dosfslabel $dev "$lbl";
					test $eingehaengt -eq 1&&mount $dev;;
			esac;
    esac;
	fi;
	# printf "zeile: $blau$zeile$reset\n"
	# echo "mtp: \"$mtp\"";
  case $lbl in 
   DAT*|wrz*|win*)
	   [ "$mtp" ]||mtp="/"$(echo $lbl|sed 's/[[:space:]]//g');;
   *)
   	 [ "$mtp" ]||mtp="/mnt/"$(echo $lbl|sed 's/[[:space:]]//g');;
  esac;
	[ "$mtp" -a ! -d "$mtp" ]&&mkdir -p "$mtp";
	if test -z "$lbl"; then
		ident="UUID="$uid;
	else 
		ident="LABEL="$lbl;
	fi;
	idohnelz=$(printf "$ident"|sed 's/[[:space:]]/\\\\040/g');
	obinfstab "$idohnelz" "$uid" "$dev";
	printf "Mountpoint: $blau$mtp$reset istinfstab: $blau$istinfstab$reset\n";
	if test $istinfstab -eq 0; then
		eintr="\t $mtp\t $fty\t user,acl,user_xattr,exec,nofail,x-systemd.device-timeout=15\t 1\t 2";
		[ "$fty" = vfat ]&&eintr="\t $mtp\t $fty\t user,exec,nofail,x-systemd.device-timeout=15\t 1\t 2";
		if test "$fty" = ntfs; then
			eintr="\t $mtp\t ntfs-3g	 user,users,gid=users,fmask=133,dmask=022,locale=de_DE.UTF-8,nofail,x-systemd.device-timeout=15	 1	 2";
		fi;
		eintr=$idohnelz$eintr;
		printf "$eintr\n" >>$ftb;
		printf "\"$blau$eintr$reset\" in $blau$ftb$reset eingetragen.\n";
	fi;
 fi; # [ "$uid" ]
	# byt=$(echo $zeile|cut -d\" -f4);
	#   altbyt=$byt; byt=$(echo $z|cut -d' ' -f2); [ "$byt" -lt "$altbyt" ]&&gr=ja||gr=nein; echo "      byt: "$byt "$gr";
done << EOF
$fstabteil;
EOF
done; # nochmal
  mount -a;
  awk '/^[^#;]/ && !/ swap /{printf "%s ",$1;system("mountpoint "$2);}' $ftb;
} # mountlaufwerke

pruefgruppe() {
    [ "$1" ]&&{ grep -q "^$1:" /etc/group||groupadd $1;}||echo Aufruf pruefgruppe ohne Gruppe!
}

pruefuser() {
	printf "${dblau}pruefuser$reset($1)\n";
		id -u "$1" >/dev/null 2>&1 &&obu=0||obu=1;
		pdbedit -L|grep "^$1:" &&obs=0||obs=1;
		passw="";
		if test $obu -eq 1 -o $obs -eq 1; then {
			while test -z "$passw"; do
				printf "Bitte gewünschtes Passwort für Linux-Benutzer $blau$1$reset eingeben: "; read passw;
			done;
		} fi;
		if test $obu -eq 1; then {
			printf "erstelle Linux-Benutzer $blau$1$reset\n";
			useradd -p $(openssl passwd -1 $passw) -c"$2" -g "$gruppe" "$1"; # zuweisen:  passwd "$1"; # loeschen: userdel $1;
		} fi;
    groups $1|grep -q praxis||usermod -aG praxis $1
    pruefgruppe www
    groups $1|grep -q www||usermod -aG www $1
		if test $obs -eq 1; then {
				printf "erstelle Samba-Benutzer $blau$1$reset\n"; # loeschen: pdbedit -x -u $1;
				printf "$passw\n$passw"|smbpasswd -as $1; # pruefen: smbclient -L //localhost/ -U $1
		} fi;
}

obinfstab() {
	printf "${dblau}obinfstab$reset($blau$1$reset, $blau$2$reset, $blau$3$reset)\n";
	istinfstab=0;
  sdev=${3##*/}; # nur der letzte Name
	while read -r zeile; do
		# echo "dort: $zeile;"
		vgl=$(printf "$zeile"|cut -f1|sed 's/ /\\\\040/g')
		# z.B.  LABEL=Seagate\040Expansion\040Drive
#		printf "vgl: $rot$vgl$reset vs: $rot$(echo $(echo $1)|sed 's/ //g')$reset\n";
		if test "$vgl" = "$(echo $(echo $1)|sed 's/ //g')"; then istinfstab=1; break; fi;
		if test "$vgl" = "$1"; then istinfstab=1; break; fi;
		if test "$vgl" = "UUID=$2";then istinfstab=1; break; fi;
		if test "$vgl" = "$3";then istinfstab=1; break; fi;
		for dbid in $(find /dev/disk/by-id -lname "*$sdev"); do
			if test "$vgl" = "$dbid";then istinfstab=1; break; fi;
		done;
		if test $istinfstab -eq 1; then break; fi;
	done << EOF
$fstb
EOF
#[ $istinfstab -eq 0 ]&&printf "(echo (echo 1..: $rot$(echo $(echo $1)|sed 's/ //g')$reset\n";
}

obprogda() {
 printf "${dblau}obprogda$reset(${blau}$1$reset)\n";
 prog="";
 for verz in /usr/local/bin /usr/bin /usr/local/sbin /usr/sbin /sbin /bin /usr/libexec /run; do
	 prog="$verz/$1";
	 if test -f "$prog"; then return 0; fi;
 done;
 prog=$(which "$1" 2>/dev/null);
 if test -f "$prog"; then return 0; fi;
 return 1;
}

setzinstprog() {
 printf "${dblau}setzinstprog$reset(), OSNR: $OSNR\n"
 case $OSNR in
	1|2|3)
		S=/etc/apt/sources.list;F='^[^#]*cdrom:';grep -qm1 $F $S && test 0$(sed -n '/^[^#]*ftp.*debian/{=;q}' $S) -gt 0$(sed -n '/'$F'/{=;q}' $S) && 
					ping -qc 1 www.debian.org >/dev/null 2>&1 && sed -i.bak '/'$F'/{H;d};${p;x}' $S;:;
		psuch="dpkg -s "; # dpkg -l wuerde zwar genauer anzeigen, aber errorlevel nicht abhängig vom Installtationszustand
		instp="apt-get install";
		instyp="apt-get -y --force-yes --reinstall install ";
		insg="apt-get --allow-unauthenticated -y install ";
		insse="apt search installed ";
		upr="apt-get -f install;apt-get purge ";
		upru="apt-get -f install;apt-get --auto-remove purge ";
		udpr="apt-get -f install;dpkg -r --force-depends ";
		uypr="apt-get -f install;apt-get -y --auto-remove purge ";
		upd="apt update;apt upgrade;";
		compil="install build-essential linux-headers-`uname -r`";
		dev="dev";;
	4|5|6|7)
		psuch="rpm -q ";
		dev="devel";
		udpr="rpm -e --nodeps ";
		case $OSNR in
			4)
				instp="zypper -n --gpg-auto-import-keys in ";	
				instyp=$instp" -y -f ";
				insg="zypper --no-gpg-checks in -y ";
				insse="zypper se -i ";
				upr="zypper -n rm ";
				upru="zypper -n rm -u ";
				uypr=$upru" -y ";
				upd="zypper patch";
				repos="zypper lr | grep 'g++\\|devel_gcc'>/dev/null 2>&1 ||zypper ar http://download.opensuse.org/repositories/devel:";
				repos="${repos}/gcc/`cat /etc/*-release |grep ^NAME= | cut -d'\"' -f2 | sed 's/ /_/'`";
				repos="${repos}_`cat /etc/*-release | grep ^VERSION_ID= | cut -d'\"' -f2`/devel:gcc.repo;";
				compil="gcc gcc-c++ gcc6-c++";;
			5)
				instp="dnf install ";
				instyp="dnf -y install ";
				insg="dnf --nogpgcheck install ";
				upr="dnf remove ";
				upru="dnf autoremove ";
				uypr="dnf -y remove ";
				upd="dnf update";;
			6)
				instp="yum install ";
				instyp="yum -y install ";
				insg="yum --nogpgcheck install ";
				upr="yum remove ";
				upru="yum autoremove ";
				uypr="yum -y remove ";
				upd="yum update";;
			7)
				instp="urpmi --auto ";
				instyp=$instp"--force ";
				insg="urpmi bumblebee-nonfree-release ";
				upr="urpme ";
				upru="urpme ";
				uypr=$upru"--auto --force ";
				upd="urpmi.update -a";;
		esac;
		compil="make automake gcc-c++ kernel-devel";;
	8)
		psuch="pacman -Qi";
		instp="pacman -S ";
		instyp=$instp"--noconfirm ";
		upr="pacman -R ";
		upru="pacman -R -s ";
		uypr=$upru"--noconfirm "; 
		udpr="pacman -R -d -d ";
		upd="pacman -Syu";
		compil="gcc linux-headers-`uname -r`";;
 esac;
} # setzinstprog

ersetzeprog() {
	printf "${blau}ersetzeprog($reset$1): -> "
	sprog="";
	eprog=$1;
	while true; do
	case $OSNR in
	1|2|3) # mint, ubuntu, debian
		if [ "$1" = mariadb ]; then eprog="mariadb-server"; break; fi;
		if [ "$1" = hylafax ]; then eprog="hylafax-server"; break; fi;
		if [ "$1" = "hylafax+" ]; then eprog="hylafax+-server"; break; fi;
		if [ "$1" = "hylafax hylafax-client" ]; then eprog="hylafax-server hylafax-client"; break; fi;
		if [ "$1" = "hylafax+ hylafax+-client" ]; then eprog="hylafax+-server hylafax+-client"; break; fi;
		if [ "$1" = "kernel-source" ]; then eprog="linux-source-$(uname -r|cut -d. -f1,2)"; break; fi;
		if [ "$1" = tiff ]; then eprog="libtiff-tools"; break; fi;
		if [ "$1" = "libxslt-tools" ]; then eprog="xsltproc"; break; fi;
		if [ "$1" = imagemagick ]; then eprog="imagemagick imagemagick-doc"; break; fi;
		if [ "$1" = "libreoffice-base" ]; then eprog="libreoffice-common libreoffice-base"; break; fi;
		if [ "$1" = "libcapi20-2" ]; then eprog="libcapi20-dev"; break; fi;
		if [ "$1" = "tesseract-ocr-traineddata-english" ]; then eprog="tesseract-ocr-eng"; break; fi;
		if [ "$1" = "tesseract-ocr-traineddata-german" ]; then eprog="tesseract-ocr-deu"; break; fi;
		if [ "$1" = "tesseract-ocr-traineddata-orientation_and_script_detection" ]; then eprog="tesseract-ocr-osd"; break; fi;
		if [ "$1" = "poppler-tools" ]; then eprog="poppler-utils"; break; fi;
		if [ "$1" = "boost-devel" ]; then eprog="libboost-dev libboost-system-dev libboost-filesystem-dev"; break; fi;
		if [ "$1" = "openssh" ]; then eprog="openssh-server openssh-client"; break; fi;
		eprog=$(echo "$eprog"|sed 's/-devel/-dev/g');
		;;
	5|6) # fedora, fedoraalt
		if [ "$1" = mariadb ]; then eprog="mariadb-server"; break; fi;
		if [ "$1" = "kernel-source" ]; then eprog="kernel-devel-$(uname -r)"; break; fi;
		if [ "$1" = "libwbclient0" ]; then eprog="libwbclient"; break; fi;
		if [ "$1" = tiff ]; then eprog="libtiff-tools"; break; fi;
		if [ "$1" = libtiff5 ]; then eprog="libtiff"; break; fi;
		if [ "$1" = "libcapi20-2" ]; then eprog="isdn4k-utils"; break; fi;
		if [ "$1" = "libcapi20-3" ]; then eprog=""; break; fi;
		if [ "$1" = "capiutils" ]; then eprog=""; break; fi;
		if [ "$1" = imagemagick ]; then eprog="ImageMagick ImageMagick-doc"; break; fi;
		if [ "$1" = "libxslt-tools" ]; then eprog="libxslt"; break; fi;
		if [ "$1" = "libreoffice-base" ]; then eprog="libreoffice-filters libreoffice-langpack-de"; break; fi;
		if [ "$1" = "tesseract-ocr" ]; then eprog="tesseract"; break; fi;
		if [ "$1" = "tesseract-ocr-traineddata-english" ]; then eprog=""; break; fi;
		if [ "$1" = "tesseract-ocr-traineddata-german" ]; then eprog="tesseract-langpack-deu tesseract-langpack-deu_frak"; break; fi;
		if [ "$1" = "tesseract-ocr-traineddata-orientation_and_script_detection" ]; then eprog=""; break; fi;
		if [ "$1" = "poppler-tools" ]; then eprog="poppler-utils"; break; fi;
		if [ "$1" = "openssh" ]; then eprog="openssh openssh-server openssh-clients"; break; fi;
		;;
	4) # suse
		if [ "$1" = "redhat-rpm-config" ]; then eprog=""; break; fi;
		if [ "$1" = "kernel-source" ]; then eprog="kernel-devel"; break; fi;
		if [ "$1" = "libffi-devel" ]; then eprog="libffi$(gcc --version|head -n1|sed "s/.*) \(.\).\(.\).*/\1\2/")-devel"; break; fi;
		;;
	8) # manjaro
		if [ "$1" = "libwbclient0" ]; then eprog="libwbclient"; break; fi;
		;;
 esac;
 break;
 done;
 [ -z "$eprog" ]&&eprog="$1";
 [ -z "$sprog" ]&&sprog="$eprog";
 printf " $sprog\n";
} # ersetzeprog

doinst() {
	printf "${blau}doinst($reset$1)\n"
	ersetzeprog "$1";
  echo Fertig mit ersetzeprog
	[ "$2" ]&&obprogda "$2"&&return 0;
  echo Fertig mit obprogda
#	printf "eprog: $blau$eprog$reset sprog: $blau$sprog$reset\n";
	for prog in "$1"; do
    printf "$psuch $prog: "
		$psuch "$prog" >/dev/null 2>&1&&{ echo gefunden; return 0; }
		printf "installiere $blau$prog$reset\n";
		if [ $OSNR -eq 4 -a $obnmr -eq 1 ]; then
			obnmr=0;
			zypper mr -k --all;
		fi;
		$instp "$prog";
	done;
	printf "Fertig mit ${blau}doinst($reset$1)\n"
} # doinst

# aufgerufen in richtmariadb ein
instmaria() {
  # anderes Datenverzeichnis auf gehostetem Laufwerk: erst in my.cnf datadir=... eintragen, ohne dass es es schon gibt, dann einmal systemctl start mysql aufrufen, dann wieder schließen, die Daten dorthin kopieren
	printf "${blau}instmaria$reset()\n"
	case $OSNR in
		1|2|3)
			apt-get -y install apt-transport-https;
			apt-get update && DEBIAN_FRONTEND=noninteractive apt-get --reinstall install -y mariadb-server;;
		*)
			doinst mariadb;
			if [ $OSNR -eq 8 ]; then
				mysql_install_db --user="$mysqlben" --basedir=/usr/ --ldata=/var/lib/mysql;
			fi;;
	esac;
  for datei in /etc/mysql/mariadb.conf.d/50-server.cnf /etc/my.cnf; do
    [ -f "$datei" ]&& sed -i.bak 's/^\(bind-address.*\)/# \1/;/^sql_mode=/a innodb_strict_mode=OFF' "$datei";
  done;
  systemctl restart mysql;
}

pruefmroot() {
	printf "${dblau}pruefmroot$reset()\n";
	while true; do
		[ "$mroot" ]&&break;
		printf "Mariadb: Admin: ";[ $obbash -eq 1 ]&&read -rei root mroot||read mroot;
		obschreiben=1;
	done;
	while true; do
		[ "$mrpwd" ]&&break;
		printf "Mariadb:$1 Passwort für '$mroot': ";read mrpwd;
		printf "Mariadb: erneut$2 Passwort für '$mroot': ";read mrpwd2;
		[ "$mrpwd/" = "$mrpwd2/" ]|| unset mrpwd;
		obschreiben=1;
		# hier könnten noch Einträge wie "plugin-load-add=cracklib_password_check.so" in "/etc/my.cnf.d/cracklib_password_check.cnf" 
		# auskommentiert werden und der Service neu gestartet werden
	done;
	printf "${dblau}Ende pruefmroot$reset()\n";
} # pruefmroot

fragmusr() {
  while true; do
    [ "$musr" ]&&break;
    #			echo $0 $SHELL $(ps -p $$ | awk '$1 != "PID" {print $(NF)}') $(ps -p $$) $(ls -l $(which sh));
    printf "Mariadb Standardbenutzer: ";[ $obbash -eq 1 ]&&read -rei "$gruppe" musr||read musr;
    obschreiben=1;
  done;
}

fragmpwd() {
  while true; do
    [ "$mpwd" ]&&break;
    printf "Mariadb: neues Passwort für '$musr': ";read mpwd;
    printf "Mariadb: erneut das Passwort für '$musr': ";read mpwd2;
    [ "$mpwd/" = "$mpwd2/" ]|| unset mpwd;
    obschreiben=1;
  done;
}

richtmariadbein() {
	printf "${blau}richtmariadbein$reset()\n"
	# Mariadb
	case $OSNR in
		1|2|3)
			db_systemctl_name="mysql";;
		4|5|6|7)
			db_systemctl_name="mariadb";;
	esac;
	for iru in 1 2; do
		systemctl is-enabled $db_systemctl_name >/dev/null 2>&1 ||systemctl enable $db_systemctl_name;
		systemctl start $db_systemctl_name >/dev/null 2>&1;
		minstalliert=1; # 1 = installiert, alle Kriterien sind erfüllt
		mysqld=".*/\(mysqld\|mariadbd\)";
		mysqlben="mysql";
		mysqlbef="mysql";
    wosuch=; for wo in /usr/sbin /usr/bin /usr/libexec; do [ -d $wo ]&&wosuch=$wosuch" "$wo; done;
		! find $wosuch -executable -size +1M -regex "$mysqld" 2>/dev/null|grep -q .&&minstalliert=0;
	[ "$verb" ]&& echo 1 minstalliert: $minstalliert;
		[ $minstalliert -eq 1 ]&& obprogda $mysqlbef || minstalliert=0;
	[ "$verb" ]&& echo 2 minstalliert: $minstalliert;
		[ $minstalliert -eq 1 ]&& grep -q "^$mysqlben" /etc/passwd || minstalliert=0;
	[ "$verb" ]&& echo 3 minstalliert: $minstalliert;
		[ $minstalliert -eq 1 ]&& $mysqlbef -V >/dev/null|| minstalliert=0;
	[ "$verb" ]&& echo 4 minstalliert: $minstalliert;
		[ $minstalliert -eq 1 ]&&break;
	[ "$verb" ]&& echo 5 minstalliert: $minstalliert;
		instmaria;
	done;
	if [ $minstalliert -eq 1 ]; then
		datadir=$(sed 's/#.*$//g' $($mysqlbef --help|sed -n '/Default options/{n;p}') 2>/dev/null|grep datadir|cut -d= -f2|sed 's/^[[:space:]]*//'|tail -n1);
		if [ -z "$datadir" ]; then
			mycnfpfad="$(find /etc /etc/mysql $MYSQL_HOME -name my.cnf -printf '%p\n' -quit 2>/dev/null)";
			[ -z "$mycnfpfad" ]&&mycnfpfad="$(find $HOME -name .my.cnf -printf '%p\\n' -quit)";
			if [ "$mycnfpfad" ]; then
				for aktdir in $(sed 's/#.*$//g' "$mycnfpfad"| grep '!includedir' | sed 's/^[ \t]//g' | cut -d' ' -f2-);do
					mycnfpfad="$mycnfpfad $(find $aktdir -not -type d)";
				done;
			fi;
			for aktzz in $mycnfpfad; do
				datadir=$(sed 's/#.*$//g' "$aktzz"|grep datadir|cut -d= -f2|sed 's/^[[:space:]]*//'|tail -n1);
				[ "$datadir" ]&&break;
			done;
		fi;
    backup /etc/my.cnf;
		cp -an my.cnf /etc/;
    # datadir aus der lokalen Datei zurückübertragen
    [ -f /etc/mycnf_0 ]&&{
      dad=$(sed -n '/^[[:space:]]*datadir[[:space:]]*=/p' /etc/my.cnf_0 2>/dev/null);
      [ $dad ]&&sed -i "s}^[[:space:]]*datadir[[:space:]]*=.*}$dad}" /etc/my.cnf;
    }
		[ -z "$datadir" ]&&datadir="/var/lib/mysql";
		[ -e "$datadir" -a ! -d "$datadir" ]&&rm -f "$datadir";
		if ! [ -d $datadir ]; then
			echo rufe mysql_install_db auf
			$(find /usr/local /usr/bin /usr/sbin -name mysql_install_db 2>/dev/null);
			systemctl start mysql;
		fi;
		while mysql -e'\q' 2>/dev/null; do
			pruefmroot " neues" " das neue";
      # 4.9.20: fuer den mysql-Import von quelle ist auch der Benutzer mysql noetig
      ausf "mysql -u\"$mroot\" -hlocalhost -e\"GRANT ALL ON *.* TO '$mroot'@'localhost' IDENTIFIED BY '$mrpwd' WITH GRANT OPTION\"" "${blau}";
      ausf "mysql -u\"$mroot\" -hlocalhost -p\"$mrpwd\" -e\"GRANT ALL ON *.* TO '$mroot'@'%' IDENTIFIED BY '$mrpwd' WITH GRANT OPTION\"" "${blau}";
      ausf "mysql -u\"$mroot\" -hlocalhost -p\"$mrpwd\" -e\"SET NAMES 'utf8' COLLATE 'utf8_unicode_ci'\"" "${blau}";
      ausf "mysql -u\"$mroot\" -hlocalhost -p\"$mrpwd\" -e\"GRANT ALL ON *.* TO 'mysql'@'localhost' IDENTIFIED BY '$mrpwd' WITH GRANT OPTION\"" "${blau}";
      ausf "mysql -u\"$mroot\" -hlocalhost -p\"$mrpwd\" -e\"GRANT ALL ON *.* TO 'mysql'@'%' IDENTIFIED BY '$mrpwd' WITH GRANT OPTION\"" "${blau}";
    done;
    test "$mpwd"||echo Bitte gleich Passwort für mysql-Benutzer "$musr" eingeben:
    mysql -u"$musr" -p"$mpwd" -e'\q' 2>/dev/null;
    erg=$?;
    if test "$erg" -ne "0"; then
    # erg: 1= andere Zahl von Eintraegen, 0 = 2 Eintraege
     test "$mrpwd"||echo Bitte gleich Passwort für mysql-Benutzer "$mroot" eingeben:
     erg=$(mysql -u$mroot -p$mrpwd -e"select count(0)!=2 from mysql.user where user='$musr' and host in ('%','localhost')"|tail -n1|head -n1);
    fi;
    test "$mpwd"||echo Bitte gleich Passwort für mysql-Benutzer "$musr" eingeben:
    mysql -u"$musr" -p"$mpwd" -e'\q' 2>/dev/null;
    erg=$?;
    if test "$erg" -ne "0"; then
      fragmusr;
      fragmpwd;
      test "$mpwd"||echo Bitte gleich Passwort für mysql-Benutzer "$musr" eingeben:
      mysql -u"$musr" -p"$mpwd" -e'\q' 2>/dev/null;
      erg=$?;
      if test "$erg" -ne "0"; then
      # erg: 1= andere Zahl von Eintraegen, 0 = 2 Eintraege
       test "$mrpwd"||echo Bitte gleich Passwort für mysql-Benutzer "$mroot" eingeben:
       erg=$(mysql -u$mroot -p$mrpwd -e"select count(0)=2 from mysql.user where user='$musr' and host in ('%','localhost')"|tail -n1|head -n1);
      fi;
      if test "$erg" -ne "0"; then
        echo Benutzer "$musr"  war schon eingerichtet;
      else
          pruefmroot;
          test "$mrpwd"||echo Bitte gleich Passwort für mysql-Benutzer "$mroot" eingeben:
          ausf "mysql -u\"$mroot\" -hlocalhost -p\"$mrpwd\" -e\"GRANT ALL ON *.* TO '$musr'@'localhost' IDENTIFIED BY '$mpwd' WITH GRANT OPTION\"" "${blau}";
          ausf "mysql -u\"$mroot\" -hlocalhost -p\"$mrpwd\" -e\"GRANT ALL ON *.* TO '$musr'@'%' IDENTIFIED BY '$mpwd' WITH GRANT OPTION\"" "${blau}";
      fi;
      echo datadir: $datadir;
      echo Jetzt konfigurieren;
    fi;
	fi;   # if [ $minstalliert -eq 1 ]; then
	[ "$verb" ]&& echo minstalliert: $minstalliert;
} # richtmariadbein

proginst() {
	printf "${dblau}proginst$reset()\n"
  [ "$psuch" ]||{ echo psuch nicht zugewiesen, OSNR: $OSNR, breche ab; exit; }
	# fehlende Programme installieren
  # postfix, ist wohl schon datei
	doinst htop;
	doinst nmap;
	doinst vsftpd;
	doinst openssh;
	doinst zsh;
	doinst curl;
	doinst cifs-utils;
  doinst convmv; # fuer Turbomed
  doinst ntp; # fuer stutzeDBBack.sh
#  doinst libvmime1; # fuer stutzeDBBack.sh
#  doinst libvmime-devel; # fuer stutzeDBBack.sh
  doinst cmake;
  doinst libgsasl;
  doinst gtk3-devel;
  doinst dash;
  doinst git;
  doinst lsb-release;
  doinst docker;
  doinst gparted;
  doinst liblept5; # fuer ocrmypdf; pillow?
  doinst dash;
  doinst lsb-release;
  doinst p7zip;
  doinst p7zip-full;
  doinst apache2;
  doinst apache2-mod_php7;
  doinst php7-mysql;
  doinst postgresql;
  doinst postgresql-contrib;
  doinst postgresql-server;
  doinst phpPgAdmin;
  doinst gnutls-devel; # fuer vmime
  doinst libgsasl-devel; # fuer vmime
  doinst doxygen; # fuer alle moegelichen cmake
  doinst getmail;
  doinst virtualbox virtualbox-host-source virtualbox-guest-tools; 
  doinst e2fsprogs-devel; # wg. fehler et/com_err.h missing
  zypper lr home_mnhauke_ISDN >/dev/null 2>&1||{
   zypper addrepo https://download.opensuse.org/repositories/home:mnhauke:ISDN/openSUSE_Leap_15.2/home:mnhauke:ISDN.repo
   zypper refresh;
  }
  doinst i4l-base;
  doinst libcapi20-2;
  doinst libcapi20-3;
  doinst capi4linux-devel;

# fuer fbfax:
# zypper addrepo https://download.opensuse.org/repositories/openSUSE:Leap:15.2/standard/openSUSE:Leap:15.2.repo
# zypper in /DATA/down/i4l-base-2011.8.29-lp152.8.37.x86_64.rpm
# zypper in /DATA/down/ppp-userpass-2011.8.29-lp152.8.37.x86_64.rpm
# zypper in /DATA/down/libcapi20-2-2011.8.29-lp152.8.37.x86_64.rpm
# zypper in /DATA/down/capi4linux-2011.8.29-lp152.8.37.x86_64.rpm
# zypper in /DATA/down/capi4linux-devel-2011.8.29-lp152.8.37.x86_64.rpm 
  # einmal ging das erst nach zypper up und Neustart des Computers
  # Datei -> Einstellungen -> Zusatzpakete -> Extensionpack auswählen
  # dann VirtualBox aufrufen, Add, die z.B. Wind10.vdi-Datei auswählen; File -> Host Network Manager, Create
  D=/etc/sysconfig/apache2;DN=${D}_neu;[ -f $D ]&&{
       sed 's:APACHE_CONF_INCLUDE_FILES="":APACHE_CONF_INCLUDE_FILES="/etc/apache2/httpd.conf.local":' $D >$DN;
       for dt in php7 version; do
         grep "^APACHE_MODULES=\".* $dt" $DN||sed -i 's:^\(APACHE_MODULES=\"[^"]*\):\1 '$dt':' $DN;
       done;
       cmp -s $D $DN &&{
         rm $DN;
       :;}||{
         mv $D ${D}.bak;
         mv $DN $D;
       }
  }
  chown wwwrun:www -R /srv/www/htdocs;
  a2enmod php7;
  systemctl enable apache2;
  systemctl restart apache2;
  case $OSNR in
   4) # suse
#    zypper lr|grep home_Alexander_Pozdnyakov >/dev/null||zypper ar https://download.opensuse.org/repositories/home:Alexander_Pozdnyakov/openSUSE_Leap_$(lsb-release -r|cut -f2)/home:Alexander_Pozdnyakov.repo;; # auskommentiert 5.2.22
  esac;
  doinst tesseract-ocr 
  doinst tesseract-ocr-traineddata-german
  # putty auch fuer root erlauben:
	D=/etc/ssh/sshd_config;
	W=PermitRootLogin;
	if ! grep "^$W[[:space:]]*Yes$" $D; then
		if grep "^$W" $D; then
			sed -i "/^$W/c$W Yes" $D;
		elif grep "^#$W" $D; then
			sed -i "/^#$W/a$W Yes" $D;
		fi;
	fi;
  D=/etc/profile.local;S=NCURSES_NO_UTF8_ACS;W=1;[ -f "$D" ]&&grep "$S" "$D"||echo "$S"="$W" >>"$D";
  D=/etc/profile.local;S=TERM;W=xterm-utf8;[ -f "$D" ]&&grep "$S" "$D"||echo "# $S"="$W # geht auch" >>"$D";
# dazu noch /.bashrc 
# export LESS_TERMCAP_mb=$'\e[0;31m'     # begin bold => rot
# export LESS_TERMCAP_md=$'\e[1;34m'     # begin blink -> blau
# export LESS_TERMCAP_so=$'\e[01;44;37m' # begin reverse video
# export LESS_TERMCAP_us=$'\e[0;36m'    # begin underline -> tuerkis
# export LESS_TERMCAP_me=$'\e[0m'        # reset bold/blink
# export LESS_TERMCAP_se=$'\e[0m'        # reset reverse video
# export LESS_TERMCAP_ue=$'\e[0m'        # reset underline
# export GROFF_NO_SGR=1                  # for konsole and gnome-terminal
# TERM=xterm-256color
# NCURSES_NO_UTF8_ACS=1;

# dazu noch /etc/bash.bashrc.local:
# GRUEN="\[$(tput setaf 2)\]"
# ROT="\[$(printf '\e[1;31m')\]"
# RESET="\[$(tput sgr0)\]"
# PS1="${GRUEN}\u@\h: \w${RESET}>"

# fehlt: /etc/environment festlegen

  D=/var/log/journal;[ -d $D ]||mkdir -p $D;
	case $OSNR in
	1|2|3) # mint, ubuntu, debian
		sshd=ssh;;
	4|5|6|7) # opensuse, fedora, mageia
		sshd=sshd;;
	esac;
	systemctl enable $sshd;
	systemctl restart $sshd;
	doinst git;
  VORVZ=$(pwd);
  [ -s /usr/local/include/vmime/vmime.hpp ]||{
    D=vmime;
    cd $HOME;
    git clone http://github.com/libelle17/$D;
    cd $HOME/$D;
    mkdir -p build;
    cd build;
    cmake ..;
    make;
    make install;
  }
  for D in autofax vmime anrliste dicom fbfax impgl labimp termine vmparse2; do
    cd $HOME;
    [ -s "$HOME/$D/kons.cpp" -o -d "$HOME/$D/cmake" ]||{ 
      [ -d "$HOME/$D" ]&&{
        find "$HOME/$D" -ls
        printf "Soll das Verzeichnis $HOME/$D zum Neuholung von git gelöscht werden (jyJYnN)? ";read obloe;
        case $obloe in 
         [jyJY]*) rm -rf "$HOME/$D";;
        esac;
      }
      echo hole $D; git clone http://github.com/libelle17/$D;
    };
    cd $HOME/$D;
    if [ -d cmake ]; then
     [ -d build ]||mkdir build;
     cd build;
     [ -f Makefile ]||cmake ..;
     make;
     make install;
    else
      [ -f vars ]||sh configure;
      [ -s $D ]||make;
      [ -s /usr/bin/$D ]||make install;
    fi;
    git remote set-url origin  git+ssh://git@github.com/libelle17/$D.git
  done;
  cd $VORVZ;
} # proginst

postfix() {
# in /etc/postfix/master.cf eintragen oder unkommentieren:
#  tlsmgr unix - - n 1000? 1 tlsmgr
# in /etc/postfix/main.cf eintragen oder unkommentieren:
#  inet_protocols = all
#  relayhost = [smtp.gmail.com]:587
#  smtp_sasl_auth_enable = yes
#  smtp_sasl_password_maps = hash:/etc/postfix/sasl_passwd
#  smtp_use_tls = yes
#  smtp_tls_security_level = may
#  smtp_tls_CAfile = /etc/ssl/ca-bundle.pem
#  smtp_tls_CApath = /etc/postfix/ssl/cacerts
#  smtp_tls_session_cache_database = btree:/var/lib/postfix/smtp_tls_session_cache
#  relay_domains = $mydestination hash:/etc/postfix/relay # ohne Komma
#  # always_bcc = mailarchive@localhost
# in sasl_passwd ergänzen:
#  [smtp.gmail.com]:587 meine.mail@gmail.com:meinpasswort
# systemctl restart postfix
# mail schicken mit: echo "Inhalt"|mail -s "Titel" an.wen@provider.com
 echo postfix muss noch geschrieben werden;
}

bildschirm() {
	printf "${dblau}bildschirm$reset()\n"
	for SITZ in gnome.desktop cinnamon.settings-daemon; do
			gsettings set org.$SITZ.peripherals.keyboard repeat-interval 40 2>/dev/null;
			gsettings set org.$SITZ.peripherals.keyboard delay 300 2>/dev/null;
	done;
	if false; then
    if test "$(id -u)" -ne 0 -o true; then
  #		github;
      if test "$DESKTOP_SESSION" = "gnome" -o "$DESKTOP_SESSION" = "gnome-classic"; then
        gsettings set org.gnome.desktop.peripherals.keyboard repeat-interval 40;
        gsettings set org.gnome.desktop.peripherals.keyboard delay 300;
      fi;
      if [ "$DESKTOP_SESSION" = cinnamon ]; then
        gsettings set org.cinnamon.settings-daemon.peripherals.keyboard repeat-interval 40;
        gsettings set org.cinnamon.settings-daemon.peripherals.keyboard delay 300;
      fi;
    fi;
	fi;
  case "$WINDOWMANAGER" in /usr/bin/startkde|/usr/bin/startplasma-x11)
      DNam=kcminputrc;
      D=~/.config/$DNam;
      [ -f $D ]||D=/etc/xdg/$DNam;
      RD="RepeatDelay=";
      rd=210;
      RR="RepeatRate=";
      rr=27;
      if ! grep -q "$RD$rd" "$D" || ! grep -q "$RR$rr" "$D"; then
        echo editiere $D;
        ue="\[Keyboard\]";sed -i "/^"$ue"/q;\$a"$ue"" "$D"
        ue="$RD";sed -i "/^"$ue"/q;\$a"$ue"" "$D"
        ue="$RR";sed -i "/^"$ue"/q;\$a"$ue"" "$D"
        sed -i "s/^\($RD\).*/\1$rd/;s/^\($RR\).*/\1$rr/" "$D";
        #  { export DISPLAY=:0;xauth add $DISPLAY . hexkey;};
        if test "$DISPLAY"; then 
          echo DISPLAY: $DISPLAY
          echo xset r rate $rd $rr;
          xset r rate $rd $rr;
          echo "Fertig mit xset"
        fi;
      fi;;
  esac;
} # bildschirm

sambaconf() {
	printf "${dblau}sambaconf$reset()\n"
	etcsamba="/etc/samba";[ -d "$etcsamba" ]||mkdir -p $etcsamba;
	smbconf="smb.conf";
	zusmbconf="$etcsamba/$smbconf";
	muster="/usr/share/samba/$smbconf";
	smbvars="$instvz/awksmb.inc";
	workgr=$(sed -n '/WORKGROUP/{s/[^"]*"[^"]*"[^"]*"\([^"]*\)".*/\1/p}' "$smbvars");
	[ "$arbgr" ]||{ printf "Arbeitsgruppe des Sambaservers: ";[ $obbash -eq 1 ]&&read -rei "$workgr" arbgr||read arbgr;};
	[ "$arbgr/" = "$workgr/" ]||sed -i '/WORKGROUP/{s/\([^"]*"[^"]*"[^"]*"\)[^"]*\(.*\)/\1'$arbgr'\2/}' $smbvars;
	[ ! -f "$zusmbconf" -a -f "$muster" ]&&{ echo cp -ai "$muster" "$zusmbconf";cp -ai "$muster" "$zusmbconf";};
	S2="$instvz/awksmbap.inc"; # Samba-Abschnitte, wird dann ein Include für awksmb.sh (s.u)
  awk -v z=0 '
    function drucke(s1,s2,avail) {
      printf " A[%i]=\"[%s]\"; P[%i]=\"%s\"; avail[%i]=%i;\n",z,s1,z,s2,z,avail;
      z=z+1;
    }
    BEGIN {
      printf "# diese Datei wird durch los.sh vor Gebrauch ueberschrieben.\n";
      printf "BEGIN {\n";
      drucke("turbomed","/opt/turbomed",1);
      drucke("php","/srv/www/htdocs",1);
      drucke("obslaeuft","/obslaeuft",1);
    }
    $3~"^ext|^ntfs|^btrfs$|^reiserfs$|^vfat$|^exfat|^cifs$" &&$2!="/" &&/^[^#]/ {
       n=$2;
       if (n~"efi") {
         sub(".*/","",n);
       } else {
         gsub("/mnt/","",n);
         gsub("/","",n);
         if (n=="DATA") n="daten";
       }
       if (f[n]==0){
         drucke(n,$2,0);
         f[n]=1;
       }
     }
     END{
      printf "};\n";
     }
   ' $ftb >$S2;
	AWKPATH="$instvz";awk -f awksmb.sh "$zusmbconf" >"$instvz/$smbconf";
	firewall samba;

	if ! diff -q "$instvz/$smbconf" "$zusmbconf" ||[ $zustarten = 1 ]; then  
		backup "$etcsamba/smb" "$zusmbconf"
		cp -a "$instvz/$smbconf" "$zusmbconf";
		for serv in smbd smb nmbd nmb; do
			systemctl list-units --full -all 2>/dev/null|grep "\<$serv.service"&& systemctl restart $serv 2>/dev/null;
		done;
	fi;
} # sambaconf

firewall() {
	printf "${dblau}firewall$reset() $1\n";
	while [ $# -gt 0 ]; do
		para="$1";
	  p1="";p2="";p3="";p4="";p5="";p6="";p7="";	
		case $para in
			samba) p1=Samba; p2=samba_export_all_ro; p3=samba_export_all_rw; p4=samba; p5="samba-server"; p6="samba-client"; p7=samba;;
			http) p1="80/tcp"; p2=httpd_can_network_connect; p3=httpd_can_network_connect_db;p4=http;p5=http;;
			https) p1="443/tcp"; p2=httpd_can_connect_ftp; p3=httpd_can_sendmail;p4=https;p5=https;;
			dhcp) p1="67,68/udp"; p2=dhcpc_exec_iptables; p3=dhcpd_use_ldap;p4=dhcp;p5=dhcp;;
			dhcpv6) p1="-"; p2="-"; p3="-";p4=dhcpv6;p5=dhcpv6;;
			dhcpv6c) p1="-"; p2="-"; p3="-";p4=dhcpv6-client;p5=dhcpv6-client;;
			postgresql) p1=5432;p2=postgresql_selinux_unconfined_dbadm;p3=selinuxuser_postgresql_connect_enabled;p4=postgresql;p5=postgresql;;
			ssh) p1=22/tcp;p2=ssh_use_tcpd;p3=ssh_keysign;p4=ssh;p5=sshd;;
			smtp) p1=25/tcp;p2="-";p3="-";p4=smtp;p5=smtp;;
			imap) p1=143/tcp;p2="-";p3="-";p4=imap;p5=imap;;
			imaps) p1=993/tcp;p2="-";p3="-";p4=imaps;;
			pop3) p1=110/tcp;p2="-";p3="-";p4=pop3;p5=pop3;;
			pop3s) p1=995/tcp;p2="-";p3="-";p4=pop3s;;
			vsftp) p1="20,21,990,40000:50000/tcp";p2="-";p3="-";p4="20/tcp,21/tcp,10090-10100/tcp";p5=vsftp;;
			mysql) p1=3306;p2=mysql_connect_any;p3=allow_user_mysql_connect;p4=mysql;p5=mysql;;
			rsync) p1=rsync;p2="-";p3="-";p4=rsyncd;p5="rsync-server";;
			turbomed) p1="6001/tcp";p2="-";p3="-";p4="6001/tcp";p5="6001/tcp";;
			firebird) p1="3050/tcp";p2="-";p3="-";p4="3050/tcp";p5="3050/tcp";;# soll nach speedguide.net Vulnerabilität haben
			# vpn: 1701
			*) printf "firewall: Unbekannter Parameter $blau$para$reset\n";;
		esac
		tufirewall $p1 $p2 $p3 $p4 $p5 $p6 $p7;
		shift;
	done;
}

# $1 = ufw allow .., $2 $3 = setsebol -P ..=1, $4 = firewall-cmd --permanent --add-service=.., $5 $6 $7 = /etc/sysconfig/SuSEfirewall2
tufirewall() {
	printf "${dblau}tufirewall$reset($1 $2 $3 $4 $5 $6 $7 $8 $9 ${10})\n";
	zustarten=0;
	# 1) ufw
	if [ "$1" != "-" ]; then
		if which ufw >/dev/null 2>&1; then
			if [ -z "$ufwret" ]; then
				ausf "systemctl list-units --full -all 2>/dev/null|grep ufw.service";
				ufwstatus="$resu";
				echo ufwstatus: $ufwstatus;
				ufwret="$ret";
				echo ufwret: $ufwret;
			else 
				[ "$verb" ]&& echo ufwret vorhanden: $ufwret;
			fi;
			if [ $ufwret -eq 0 ]; then
				if ! ufw status|grep "^$1[[:space:]]*ALLOW" >/dev/null; then
					ausf "ufw show added|grep \"allow $1\$\" >/dev/null 2>&1 ||{ printf \"${blau}ufw allow $1$reset\n\"; ufw allow \"$1\";}";
					if $(echo $ufwstatus|grep -q " active "); then
						systemctl restart ufw;
						zustarten=1;
					fi;
				else
					printf "$1 in ufw schon erlaubt\n";
				fi;
			fi;
		else
			[ "$verb" ]&& echo kein ufw;
		fi;
	else
		[ "$verb" ]&& echo kein ungleich -;
	fi;
	# 2) sebool
	if which setsebool >/dev/null 2>&1 && getsebool >/dev/null 2>&1; then
		for ro in $2 $3; do
			if [ "$ro" != "-" ]; then
				rostatus=$(getsebool -a|grep $ro|sed 's/^[^>]*>[[:space:]]*\([^[:space:]]*\).*/\1/');
				[ -z "$rostatus" -o "$rostatus" = "off" ]&&{ setsebool -P $ro=1; zustarten=1;}
			fi;
		done;
	fi;
	# fehlt evtl: noch: semanage fcontext –at samba_share_t "/finance(/.*)?"
	# und: restorecon /finance

	# 3) firewalld
	if [ "$4" != "-" ]; then
		if which firewall-cmd >/dev/null 2>&1; then
			ausf "systemctl 2>/dev/null|grep firewalld.service";
			fwstatus="$resu";
			[ $verb ]&& echo firewalld.service gefunden.
			[ $verb ]&& echo Parameter 4: "$4", ret: "$ret";
		#		echo $fwstatus;
			if [ $ret -eq 0 ]; then
				ausf "firewall-cmd --list-services 2>/dev/null";
				services="$resu";
				if [ $ret = 0 ]; then
						case "$4" in [0-9]*/*) was=port;; *) was=service;; esac;
						if [ $was = service ]; then
							ausf "echo \"$services\"|grep -qE \"(^|\s)$4(\s|$)\"";
							if [ ! $ret = 0 ]; then
								ausf "firewall-cmd --get-services|grep -E \"(^|\s)$4(\s|$)\"";
								if [ $ret = 0 ]; then
#									printf "${blau}firewall-cmd --permanent --add-$was=$4$reset\n";
									ausf "firewall-cmd --permanent --add-$was=$4" "${blau}";
									reload=1;
								fi;
							fi;
						else
							ausf "firewall-cmd --list-ports 2>/dev/null";
							ports="$resu";
							for p in $(echo $4|tr ',' ' '); do
								ausf "echo \"$ports\"|grep -qE \"(^|\s)$p(\s|$)\"";
								if [ ! $ret = 0 ]; then
									ausf "firewall-cmd --permanent --add-$was=$p" "${blau}";
									reload=1;
								fi;
							done;
						fi;
						zustarten=1;
						[ "$reload" ]&&{ ausf "firewall-cmd --reload"; unset reload; };
				fi;
			fi;
		fi;
	fi;
	# 4) SuSEFirewall2
	ausf "systemctl list-units --full -all|grep SuSEfirewall2.service";
	susestatus="$resu";
	[ $verb ]&& echo susestatus: $susestatus, ret: $ret;
	if [ $ret -eq 0 ]; then
	 # das folgende abgewandelt aus kons.cpp
   susefw="/etc/sysconfig/SuSEfirewall2";
	 if [ -f "$susefw" ]; then
		 for endg in EXT INT DMZ; do
			 for prart in "$5" "$6" "$7"; do
				 if [ "$prart" ]; then
				   prartu=$(echo "$prart"|sed 's/\//\\\//g');
					 # echo grep "^FW_CONFIGURATIONS_$endg=\".*$prart" $susefw;
					 nichtfrei=$(grep "^FW_CONFIGURATIONS_$endg=\".*$prart[ "\""]" $susefw);
					 # echo $nichtfrei $endg $prart $prartu;
					 if [ -z "$nichtfrei" ]; then
						 # echo bearbeite $nichtfrei $endg $prart $prartu;
						 sed -i.bak$i "s/\(^FW_CONFIGURATIONS_$endg=\".*\)\(\".*$\)/\1 $prartu\2/g" $susefw;
					 fi;
				 fi;
			 done;
		 done;
		 if $(echo $susestatus|grep -q " active "); then
			systemctl restart SuSEfirewall2;
			zustarten=1;
		 fi;
	 fi
	fi
} # tufirewall

fritzbox() {
	printf "${dblau}fritzbox$reset()\n";
	ip4=$(ping -4c1 fritz.box 2>&1);
  erg4=$?;
  ip6=$(ping -6c1 fritz.box 2>&1);
  erg6=$?;
	if [ $erg4 -eq 0 -o $erg6 -eq 0 ]; then
	 [ $erg6 -eq 0 ]&&{ ipv6=$(echo $ip6|sed 's/^[^(]*([^(]*(\([^)]*\).*$/\1/'); ipv=$ipv6;} # z.B. fd00::a96:d7ff:fe49:19ca, umgeben von zwei Klammern
	 [ $erg4 -eq 0 ]&&{ ipv4=$(echo $ip4|sed 's/^[^(]*(\([^)]*\)).*/\1/'); ipv=$ipv4;} # z.B. 192.168.178.1
	 echo ipv: $ipv
	 desc=$(curl $ipv:49000/tr64desc.xml 2>/dev/null);
	 fbname=$(echo "$desc"|sed -n '/friendlyName/{s/^[^>]*>\([^<]*\).*/\1/;p;q}');
	 echo fbname: $fbname
#	 fbuuid=$(echo "$desc"|sed -n '/UDN/{s/^[^>]*>\([^<]*\).*/\1/;s/:/=/;p;q}'|tr '[:lower:]' '[:upper:]'); # geht scheinbar nicht
	 fbnameklein=$(echo $fbname|tr '[:upper:]' '[:lower:]');
	 mkdir -p /mnt/$fbnameklein;
	 credfile="/root/.fbcredentials"; # ~  # $HOME
	 grep -q "^//$ipv4\|^//$ipv6" $ftb||{
		 if [ ! -f "$credfile" ]; then
			 printf "Bitte Fritzboxbenutzer eingeben: ";read fbuser;
			 printf "Bitte Passwort für $blau$fbuser$reset eingeben: ";read fbpwd;
			 printf "username=$fbuser\npassword=$fbpwd" >$credfile;
		 fi;
		 umount /mnt/$fbnameklein;
		 mount //$ipv/$fbname /mnt/$fbnameklein -t cifs -o nofail,vers=1.0,credentials=$credfile >/dev/null 2>&1 &&{
			 umount /mnt/$fbnameklein;
			 echo "//$ipv/$fbname /mnt/$fbnameklein cifs nofail,vers=1.0,credentials=$credfile 0 2" >>$ftb;
		 :;}||{
			 mount //$ipv/$fbname /mnt/$fbnameklein -t cifs -o nofail,credentials=$credfile >/dev/null 2>&1 &&{
				 umount /mnt/$fbnameklein;
				 echo "//$ipv/$fbname /mnt/$fbnameklein cifs nofail,credentials=$credfile 0 0" >>$ftb; 
			 }
		 }
	 }
#	 echo "$desc";
   printf "Fritzbox gefunden, Name: $blau$fbname$reset, ipv4: $blau$ipv4$reset, ipv6: $blau$ipv6$reset\n";
#	 printf "Bitte Fritzboxbenutzer eingeben: ";read fbuser;
#	 printf "Bitte Passwort für $blau$fbuser$reset eingeben: ";read fbpwd;
	fi;
} # fritzbox

machidpub() {
	 idpub="$HOME/.ssh/id_rsa.pub";
	 while [ ! -f "$idpub" ]; do
	  printf "Es fehlt noch: $blau$idpub$reset\n";
	  ssh-keygen -t rsa; # return, return, return
	 done;
} # machidpub

musterserver() {
 printf "${dblau}musterserver$reset()\n";
 [ "$srv0" ]||{ printf "Bitte ggf. Server angeben, von dem kopiert werden soll: ";read srv0;};
 if [ "$srv0" ]; then
	 machidpub;
	 KS=$HOME/.ssh/authorized_keys;
	 test -f "$KS"||touch "$KS";
	 <"$idpub" xargs -i ssh $(whoami)@$srv0 'umask 077;F='$KS';grep -q "{}" $F||echo "{}" >>$F'; # unter der Annahme des gleichnamigen Benutzers
	 ssh $(whoami)@$srv0 "HOME=\"$(getent passwd $(whoami)|cut -d: -f6)\";idpub=\"$HOME/.ssh/id_rsa.pub\"; cat \"$idpub\";"|xargs -i sh -c "umask 077;F=$KS;grep -q \"{}\" \$F||echo \"{}\" >>\$F";
 else
   printf "Soll von einem Verzeichnis mit /root kopiert werden (jyJYnN)? ";read obpl;
   case $obpl in 
    [jyJY]*) 
     altwrz=;
     [ -s "$wzp" ]&&{ 
       ls -l $wzp; 
     printf "Datei $blau$wzp$reset gefunden. Soll diese als Quelle der Verzeichnisse mit /root verwendet werden (jyJYnN)? ";read altwrz;
     };
     case $altwrz in 
      [jyJY]*) ;;
      *)
       mount --all 2>/dev/null;
       bef="find / -maxdepth 5 -type d -name 'root' -printf '%p\\n'";
#       bef="find / -xdev -maxdepth 5 -type d -name '*root*' -printf '%p\\n'";
       printf "Suche Verzeichnisse mit ${blau}$(echo \"$bef\"|sed 's/%/%%/g;s/\\/\\\\/g')$reset (kann länger dauern)...\n";
       eval "$bef" >"$wzp";
       ;;
     esac;
     if [ -s "$wzp" ]; then
       awk '{print NR" "$0}' $wzp >menuwrz;
       FILE=$(dialog --title "gefundene Verzeichnisse mit /root" --menu "Wähle eine" 0 0 0 --file menuwrz 3>&2 2>&1 1>&3);#show dialog and store output
       muwrz="$(awk '/^'$FILE' /{print $2}' menuwrz)"; # oder: muwrz=$(sed -n '/^'$FILE' /{s/^.* //;p}' menuwrz);
       printf "Als Vorlageverzeichnis wird verwendet: $blau$muwrz$reset\n";
       printf "Ist das richtig? (jyJYnN) "; read best;
       case $best in [jyJY]*);; *) muwrz=;; esac;
     else
       echo "Keine Verzeichnisse gefunden";
     fi;
     W=;
     ;;
   esac;
 fi;
 if [ "$srv0" ]; then
   muwrz="$srv0:$HOME";
 fi;
 if [ "$muwrz" ]; then
	 ausf "rsync -avu $muwrz/.vim $HOME/";
	 ausf "rsync -avu $muwrz/bin/.vimrc $HOME/bin/";
	 ausf "rsync -avu --include='*/' --include='*.sh' --exclude='*' $muwrz/bin $HOME/";
   gesD=;
   for D in anrliste autofax dicom fbfax impgl labimp termine; do
     gesD="$gesD $D.conf";
   done;
   ausf "rsync -lptgoDvu $muwrz/.config/ $HOME/.config/ --include \"$gesD\" --exclude \"*\"";
   vsh=/var/spool/hylafax;
   [ -f $vsh/sendq/seqf -o -f $vsh/recvq/seqf ]||{
     echo $vsh fehlt, hole es von $muwrz;
     [ -d $vsh ]&&ausf "mv -i $vsh ${vsh}_$(date +\"%Y%m%d%H%M%S\")";
     ausf "rsync -avu $muwrz/..$vsh/ $vsh";
   }
   vsh=/var/spool/capisuite;
   find "$vsh/autofaxarch/" -type f 2>/dev/null|grep . >/dev/null||{
     echo $vsh fehlt, hole es von $muwrz;
     [ -d $vsh ]&&ausf "mv -i $vsh ${vsh}_$(date +\"%Y%m%d%H%M%S\")";
     ausf "rsync -avu $muwrz/..$vsh/ $vsh";
   }
   vsh=/var/spool/fbfax;
   find "$vsh/arch/" -type f 2>/dev/null|grep . >/dev/null||{
     echo $vsh fehlt, hole es von $muwrz;
     [ -d $vsh ]&&ausf "mv -i $vsh ${vsh}_$(date +\"%Y%m%d%H%M%S\")";
     ausf "rsync -avu $muwrz/..$vsh/ $vsh";
   }
   vsh=/srv/www/htdocs;
   [ -f "$vsh/plz/=.Neuer_Patient" ]||{
     echo $vsh fehlt, hole es von $muwrz;
     find $vsh -type f 2>/dev/null|grep . >/dev/null&&ausf "mv -i $vsh ${vsh}_$(date +\"%Y%m%d%H%M%S\")";
     ausf "rsync -avu $muwrz/..$vsh/ $vsh/.. --exclude \"*Papierkorb*\"";
     chown wwwrun:www -R /srv/www/htdocs;
     systemctl restart apache2;
   }
#	 ausf "rsync -avu  $srv0:/root/bin /root/";
 fi;
} # musterserver

#holt Datei $1 entweder aus "/DATA/down /DATA/daten/down" ($q0) oder $srv0 oder $2 auf /root/Downloads (=$Dw); $3 = potentieller hol-Name
hol3() {
	printf "${dblau}hol3($1$reset,$dblau$2$reset,$dblau$3)$reset()\n";
	[ "$3" ]&&hname=$3||hname=$1;
	if ! [ -f "$Dw/$1" ]; then
    pfadda=0;
    for hpf in $q0; do if test -d $hpf; then pfadda=1; break; fi; done;
    if [ "$pfadda" = "0" ]; then for hpf in $q0; do mkdir -p $hpf; break; done; fi;  # dann das erste dort genannte Verzeichnis erstellen 
    echo q0: $q0;
    ausf "find $q0 -maxdepth 1 -name $1 2>/dev/null" "${blau}";
    datei=$resu;
		if test "$datei"; then
      datei=$(readlink -e $datei);
			hpf=${datei%/*};
			ausf "cp -ai \"$hpf/$1\" \"$Dw/\"" "${blau}";
    fi;
    [ -f "$Dw/$1" ]||ausf "ssh \"$srv0\" \"ls \\\"$spf/$1\\\" >/dev/null 2>&1\"&& scp -p \"$srv0:$spf/$1\" \"$Dw/\"&&{ [ -d \"$hpf\" ]&&cp -ai \"$Dw/$1\" \"$hpf/\";};" "${blau}"
    [ -f "$Dw/$1" ]||{
      ausf "wget \"$2/$hname\" -O\"$Dw/$1\";" "${blau}"
      [ -f "$Dw/$1" -a -d "$hpf" ]&&cp -ai "$Dw/$1" "$hpf/";
      [ "$srv0" -a -f "$Dw/$1" ]&&scp -p "$Dw/$1" "$srv0:$spf/";
    }
	fi;
} # hol3

tvversion() {
	 tversion=$(teamviewer --version 2>/dev/null|awk '/^.*Team/{print substr($4,1,index($4,".")-1)}');
	 [ "$tversion" ]||tversion=0;
	 printf "Installierte Teamviewer-Version: $blau$tversion$reset\n";
}
# teamviewer15: in /usr/share/applications/org.kde.kdeconnect_open.desktop : -MimeType=*/*; +MimeType=application/octet-stream;

teamviewer15() {
 if [ $(teamviewer --version 2>/dev/null|awk '/^.*Team/{print substr($4,1,index($4,".")-1)}') \< 15 ]; then
   sudo rpm --import  https://download.teamviewer.com/download/linux/signature/TeamViewer2017.asc;
   wget https://download.teamviewer.com/download/linux/teamviewer-suse.x86_64.rpm;
   sudo sudo zypper install teamviewer-suse.x86_64.rpm; 
 fi;
} # teamviewer15()

teamviewer10() {
	printf "${dblau}teamviewer$reset()\n";
	[ ! -d "$Dw" ]&&mkdir -p "$Dw";
	while true; do
	 tvversion;
	 pgrep -if "/opt/teamviewer.*tvguislave" >/dev/null&&[ "$tversion" = 10 ]&&return;
	 case $tversion in
		 0)
				case $OSNR in
				1|2|3) # mint, ubuntu, debian
					trpm=teamviewer_10.0.95021_i386.deb;
					hname=teamviewer_i386.deb;
					npng=libpng12-0_1.2.54-1ubuntu1.1_i386.deb;
					hol3 "$npng" "http://security.ubuntu.com/ubuntu/pool/main/libp/libpng";
					if ! dpkg -s libpng12-0:i386 >/dev/null 2>&1; then
						dpkg -i "$Dw/$npng";
					fi;
					;;
				4|5|6|7) # opensuse, fedora, mageia
					trpm=teamviewer_10.0.95021.i686.rpm; # der 6er stimmmt hier
					hname=teamviewer.i686.rpm;
					;;
				esac;
				hol3 "$trpm" "https://download.teamviewer.com/download/version_10x" "$hname";
			 if [ -f "$Dw/$trpm" ]; then
				case $OSNR in
				1|2|3) # mint, ubuntu, debian
					printf "${blau}apt install $Dw/$trpm$reset\n";
					apt install $Dw/$trpm;
					apt-mark hold teamviewer:i386;
					# bei Ubuntu funktionierte nur (ohne automatisches Upgrade der Teamviewer-Version):
					tvversion;
					if [ "$tversion" != 10 ]; then
					 apt remove teamviewer teamviewer:i386;
					 apt install libjpeg62:i386 libxtst6:i386;
					 dpkg -i $Dw/$trpm;# ./Downloads/teamviewer_10.0.95021_i386.deb;
					fi;
					;;
				4) # opensuse
#					 printf "${blau}zypper --no-gpg-checks in -l $Dw/$trpm$reset\n";
					 printf "${blau}zypper --gpg-auto-import-keys in -l $Dw/$trpm$reset\n";
					 zypper --gpg-auto-import-keys in -G -l $Dw/$trpm;
					;;
				5) # fedora,
					 printf "${blau}dnf --nogpgcheck install $Dw/$trpm$reset\n";
					 dnf --nogpgcheck install $Dw/$trpm;
					 ;;
				6) # fedoraalt
					 printf "${blau}yum --nogpgcheck install $Dw/$trpm$reset\n";
					 yum --nogpgcheck install $Dw/$trpm;
					 ;;
			  7) # mageia
					;;
				esac;
			 fi;
			 ;;
		 10) break;;
		 *) 
				case $OSNR in
				1|2|3) # mint, ubuntu, debian
					printf "${blau}apt remove teamviewer teamviewer:i386$reset\n";
					apt remove teamviewer teamviewer:i386;
					;;
				4)
					 printf "${blau}zypper rm teamviewer teamviewer:i386$reset\n";
					 zypper rm teamviewer teamviewer:i386; 
					;;
				5|6|7) # opensuse, fedora, mageia
					;;
				esac;
			 continue;;
	 esac;
	done;
# 2) libfreetype
	zvz=/opt/teamviewer/tv_bin/wine/lib;
	zd=$zvz/libfreetype.so.6;
	case $OSNR in
		1|2|3)
					npng=libfreetype6_2.6.1-0.1ubuntu2.3_i386.deb;
					hol3 "$npng" "http://security.ubuntu.com/ubuntu/pool/main/f/freetype";
					zdatei=/opt/teamviewer/tv_bin/wine/lib/libfreetype.so.6.12.1;
					if ! [ -f "$zdatei" ]; then
						cd "$Dw";
            echo ar -xv "$npng";
            ar -xv "$npng";
						tar -xvf data.tar.xz;
						cp -ai $(find usr -type f -name "libfreetype*") /opt/teamviewer/tv_bin/wine/lib/;
						cp -ai $(find usr -type l -name "libfreetype*") /opt/teamviewer/tv_bin/wine/lib/;
						cd -;
						# cp ./libfreetype6_2.6.1-0.1ubuntu2.3_i386/usr/lib/i386-linux-gnu/* /opt/teamviewer/tv_bin/wine/lib;
					fi;
					;;
		4) # opensuse
			while :; do
				[ -f "$zd" ]&&break;
				qd=$Dw/usr/lib/libfreetype.so.6.12.3;
				hol3 "$qd";
				while ! [ -f "$qd" ]; do
					qqd=libfreetype6-32bit-2.6.3-5.3.1.x86_64.rpm;
					# geht auch für Fedora
					hol3 "$qqd" "https://download.opensuse.org/update/leap/$(lsb-release -r|cut -f2)/oss/x86_64";
					cd "$Dw";
					rpm2cpio "$qqd"|cpio -idmv
					cd -;
				done;
				echo cp -ai "$qd" "$zd";
				cp -ai "$qd" "$zd";
			done;;
	esac;
# 3) lxcb
	case $OSNR in
	1|2|3) # mint, ubuntu, debian
		;;
	4) # opensuse
		lxcb=libxcb1-32bit-1.11.1-9.1.x86_64;
		if ! rpm -q "$lxcb" >/dev/null; then
		 echo $? bei rpm -q "$lxcb";
     hol3 "$lxcb.rpm" "http://download.opensuse.org/repositories/openSUSE:/Leap:/$(lsb-release -r|cut -f2):/Update/standard/x86_64";
		 rpm -i --force "$Dw/$lxcb.rpm";
		 zypper addlock "$lxcb";
		fi;
		;;
	5|6|7) # fedora, mageia
		;;
	esac;
	cd - >/dev/null;
	tvconf=/opt/teamviewer/config/global.conf;
	tvh="$instvz/tvglobal.conf";
	systemctl stop teamviewerd
	# einige Felder befüllen (außer Passwörtern und der Gruppenzugehörigkeit), sortieren nach dem Feld hinter dem Typbezeichner, Zeile 1 und 2 umstellen und 2 Leerzeilen einfügen
	AWKPATH="$instvz";cd $instvz;awk -f awktv.sh "$tvconf"|sed '/^\s*$/d;'|sort -dt] -k2|sed '1{x;d};2{p;x;p;s/.*//;p}' >"$tvh";cd -;
#	sed -i '/^\s*$/d' "$tvh";
	systemctl start teamviewerd;
	echo nach systemctl start teamviewerd;
	if ! diff "$tvconf" "$tvh" >/dev/null; then
		backup "$tvconf"
		cp -a "$tvh" "$tvconf";
	fi;
} # teamviewer10()

github() {
	printf "${dblau}github()$reset()\n";
	machidpub;
	# echo Stelle 2: $GITACC $idpub
	if { key=$(sed 's/.* \(.*\) .*/\1/;s/\//\\\//g;' $idpub);curl https://github.com/$GITACC.keys 2>/dev/null|sed -n '/'$key'/q1';}; then
		echo curl -u "$GITACC" --data '{"title":"'"$(whoami)"'@'"$(hostname)"'","key":"'"$(cat $idpub)"'"}' https://api.github.com/user/keys;
		curl -u "$GITACC" --data '{"title":"'"$(whoami)"'@'"$(hostname)"'","key":"'"$(cat $idpub)"'"}' https://api.github.com/user/keys;
	fi;
#	curl -u "$GITACC:$passwd" ...
	git remote set-url origin git@github.com:$GITACC/$DPROG.git;
# git clone ssh://git@github.com/$GITACC/$DPROG.git 
} # github

backup() {
	printf "${dblau}backup$reset($1,$2)\n";
		for i in $(seq 100 -1 0); do
			if [ -s ${1}_$i ]; then
				mv ${1}_$i ${1}_$(echo $i|awk '{print $0+1}') 2>/dev/null;
			fi;
		done;
		[ "$2" ]&&ursp="$2"||ursp="$1";
		[ -s "$ursp" ]&& mv "$ursp" "${ursp}_0";
} # backup

cron() {
	printf "${dblau}cron$reset()\n";
	chier=$instvz/cronhier;
	csrv=$instvz/crons$srv0;
	backup "$chier"
	crontab -l >"$chier";
	if [ "$srv0" ]; then
		backup "$csrv"
		crontab -l >$csrv;
		echo csrv: $csrv;
		ssh $(whoami)@$srv0 "crontab -l" >"$csrv";
	fi;
  [ "$srvhier" ]||srvhier=$(uname -n);
  crh=$instvz/cronshier; # cron-Datei des Quellservers mit korrigierten Namen
  if false; then # 14.9.: die crontab soll serveruebergreifend identisch sein und dazu hostname aufrufen
   sed 's/\<'$srvhier'\>/'${srvhier}'ur/g;s/\<'$srv0'\>/'$srvhier'/g' $csrv>$crh;
  else
   cp -a $csrv $crh:
  fi;
  # hier die Scripte aus crontab eintragen, die auf gegegenwärtigem Server gespeichert sind
  ca=$instvz/cronbefehle;
  rm -f $ca;
  touch $ca;
  # nehme $csrv, entferne Kommentarzeilen, entferne Steuerungsangaben, Teile an Leerzeichen auf, entferne Ausdrücke mit Sonderzeichen, Leerzeilen, abschliessende ';', stelle jede Zeile in eine Variable $zeile, falls diese lesebar (nicht: ausfuehrbar) und kein Verzeichnis ist und nicht schon in $ca vorkommt und '#!' am Beginn der ersten Zeile aufweist, dann fuege es an $ca an
  sed -nr '/^#/d;s/^([^ ]+ +){5}|^@[^ ]+ //;s/ /\n/g;p' $csrv|sed -r '/^-|[][>$|<:*"`'\''=&\\,}{]|^$/d;s/;$//'| 
  while read zeile;do 
    if test -r $zeile -a ! -d $zeile; then
      if ! grep -Fxq $zeile $ca; then 
        sed -n '/^#!/!q1;q0' $zeile&&echo $zeile>>$ca;
      fi;
    fi;
  done;
  # in den in $ca stehenden Dateien Namen austauschen
  while read z; do 
    if grep -qe "\(\<$srv0\>\|\<$srvhier\>\)" $z; then
      sed -i.bak 's/\<'$srvhier'\>/'${srvhier}'ur/g;s/\<'$srv0'\>/'$srvhier'/g' $z;
      printf "In $blau$z$reset $blau$srvhier$reset durch $blau${srvhier}ur$reset und $blau$srv0$reset durch $blau$srvhier$reset ersetzt\n";
    else
      [ "$verb" ]&& printf "${blau}$z$reset enthält kein ${blau}${srvhier}$reset oder ${blau}${srv0}$reset, wird belassen\n";
    fi;
  done <$ca;
  crontab <$crh;
} # cron

tu_turbomed() {
	printf "${dblau}tu_turbomed$reset($1 $2)\n";
	echo Installations-Verzeichnis: $outDir;
	mkdir -p $POET_LICENSE_PATH;
	ausf "cp $license $POET_LICENSE_PATH" "${blau}";
	case $OSNR in 1|2|3)endg=".deb";; 4|5|6|7)endg=".rpm";;esac;
	for D in $archive/*$endg; do $psuch $(basename $D $endg) >/dev/null||$insg $D; done;
  cd ${TMsetup%/*};
  [ $verb = 0 ]||echo Setupverzeichnis: ${TMsetup%/*}
  sh TM_setup $1
  ret=$?
  echo $ret;
  [ $ret != 0 -a "$2" ]&&sh TM_setup $2;
  cd -;
  convmv /opt/turbomed/* -r -f iso8859-15 -t utf-8 --notest;
	systemctl daemon-reload;
	for runde in $(seq 1 20);do 
    systemctl show poetd|grep running&&break;
    echo Starten von poetd, Runde: $runde; 
    pkill -9 ptserver;
    systemctl stop poetd;
    systemctl start poetd; 
  done;
  if [ "$muwrz" -a -s "$muwrz/../opt/turbomed/PraxisDB/objects.dat" ]; then
    for S in PraxisDB StammDB DruckDB Dictionary; do
      ausfd "rsync -avu $muwrz/../opt/turbomed/$S /opt/turbomed/";
    done;
    ausfd "rsync -avu $muwrz/../DATA/turbomed /DATA/";
  else
    [ "$srv0" ]||{ printf "Bitte ggf. Server angeben, von dem die Turbomed-Datenbanken kopiert werden sollen: ";read srv0;};
    [ "$srv0" ]&&{ 
      for S in PraxisDB StammDB DruckDB Dictionary; do
        ausfd "rsync -avu $srv0:/opt/turbomed/$S /opt/turbomed/";
      done;
      ausfd "rsync -avu $srv0:/DATA/turbomed /DATA/";
    }
  fi;
  chmod -R 770 /opt/turbomed
  chmod 550 /opt/turbomed
  # Loeschen: sh TM_setup -rm, zypper se FastObj, dann zypper rm -y ... fuer alle Namen; ggf. rm -rf /opt/Fast*, ggf. rm /etc/init.d/poetd
} # tu_turbomed

turbomed() {
	printf "${dblau}turbomed$reset()\n";
	# /DATA/down/CGM_TURBOMED_Version_19.2.1.4087_LINUX.zip
	tmsuch="CGM_TURBOMED*LINUX.zip";
	datei=$(find $q0 -name "$tmsuch" -printf "%f\1%p\n" 2>/dev/null|sort|tail -n1|cut -d $(printf '\001') -f2-);
  [ $verb = 1 ]&&echo "Datei: $datei"
	if test -z "$datei"; then echo keine Datei \"$tmsuch\" in \"$q0\" gefunden; return; fi;
	# 19.1.1.3969
  stamm=$(basename "$datei");
  echo Stamm: $stamm;
#	version=$(echo $datei|cut -d_ -f4|cut -d. -f1-2);
	version=$(echo $stamm|cut -d_ -f4|cut -d_ -f4);
	printf "Turbomed-Version: $blau$version$reset\n";
#	outDir="${datei%/*}/TM${version}L";
	outDir="${datei%/*}/TMWin"; # Name wird benötigt für setup
  echo datei: $datei
  echo outDir: $outDir
	[ -d  "$outDir" ]||ionice -c3 nice -n19 7z x $datei -o"$outDir";
#  outDir2=$outDir/linux;
  outDir2=$(find $outDir -type d -name linux);
  echo outDir2: $outDir2
#  [ -d "$outDir2" ]||mv $outDir/* $outDir2;
	instVers=$(find "$outDir2" -name "*OpenSSL*"|sort -r|cut -d- -f4|head -n1);
  TMsetup=$(find $outDir2 -name TM_setup -print -quit)
  echo TMsetup: $TMsetup
  archive=$(find $outDir2 -type d -name archive -print -quit)
  echo archive: $archive
  license=$(find $outDir2 -name license -print -quit)
  echo license: $license

#		POET_LICENSE_PATH="/opt/FastObjects_t7_12.0/runtime/lib";
#		POET_LICENSE_PATH="/opt/$(find $outDir2 -name "*OpenSSL*" -printf "%f\n"|cut -d- -f-2)/runtime/lib";
	POET_LICENSE_PATH=$(grep "POET_LICENSE_PATH=" $TMsetup|cut -d= -f2|sed 's/\"\(.*\)\"/\1/g');
  echo POET_LICENSE_PATH: $POET_LICENSE_PATH
#	if systemctl list-units --all|grep poetd >/dev/null; then
  if [ -s /etc/init.d/poetd ]; then
#		echo "export LD_LIBRARY_PATH=$POET_LICENSE_PATH;$LD_LIBRARY_PATH/../bin/ptsu -help|grep Version|rev|sed 's/^[[:space:]]//'|cut -d' ' -f1|rev;"
		laufVers=$(export LD_LIBRARY_PATH=$POET_LICENSE_PATH;"$LD_LIBRARY_PATH"/../bin/ptsu -help|grep Version|rev|sed 's/^\s*//'|cut -d' ' -f1|rev);
  	echo laufVers: "$laufVers"
	  echo instVers: "$instVers";
#   12.0.2.208
    [ "$laufVers" = "$instVers" ]||{ printf "Turbomed mit $laufVers ggü. $instVers zu alt.\n";tu_turbomed "-uw";};
	else
		printf "Installiere Turbomed neu\n";
		tu_turbomed "-iw" "-uw" # -tw
	fi;
} # turbomed

dbinhalt() {
  VZ=/DATA/sql;
	printf "${dblau}dbinhalt$reset()\n";
  pruefmroot;
  echo obschreiben: $obschreiben, loscred: $loscred;
  # alle Rümpfe, jeden einmal
  for db in $(find $VZ -maxdepth 1 -name "*--*.sql" -not -name "mysql--*" -not -name "information_schema--*" -not -name "performance_schema--*" -printf "%f\n"|sed 's/^\(.*\)--.*/\1/'|sort -u); do
    [ "$verb" ]&&printf "Untersuche $blau$db$reset: ";
    test "$mrpwd"||echo Bitte gleich Passwort für mysql-Benutzer "$mroot" eingeben:
    dbda=$(! mysql -u"$mroot" -p"$mrpwd" -hlocalhost -e"use \"$db\"" >/dev/null 2>&1;printf $?);
    # wenn "immer" oder Datenbank nicht existiert, dann
    if test "$1"/ = immer/ -o $dbda = 0; then
      echo dbnichtda;
#      printf "$blau$db$reset"; if test "$1"/ = immer/; then printf " wird neu gespeichert!\n"; else printf " fehlt als Datenbank!"; fi;
#      Q=$(ls "$VZ/"$db--*.sql -S|head -n1);     # die als jüngste benannte Datei ...
      Q=$(awk -v pfad="$VZ" -v n1="$db--" -v n2=".sql" -f awkfdatei.sh);
      Zt=$(echo $Q|sed 's:.*--\([^/]*\)\..*$:\1:;s/[-.]//g'); # Zeit rausziehen
      Sz=$(stat "$Q" --printf="%s\\n");
      pd=$instvz/sqlprot.txt;
      [ -f $pd ]||echo "Letzte Datenbankeintragungen:" >$pd;
      test "$mrpwd"||echo Bitte gleich Passwort für mysql-Benutzer "$mroot" eingeben:
      mysql -u"$mroot" -p"$mrpwd" -hlocalhost -e"SET session innodb_strict_mode=Off";
      # überprüfen, ob ind $pd schon die gleiche oder eine jüngere Datei eingetragen wurde
      awk '/'$db'=/{\
        gef=1;\
        split($0,teil,"=");\
        zei=teil[2]>'$Zt'?">":teil[2]<'$Zt'?"<":"=";\
        printf "'$blau'"teil[2]"'$reset'"zei"'$blau$Zt$reset' =>";\
        if (zei==">"||zei=="="){\
          print "ueberspringe '$blau$db$reset'";\
          fertig=1;\
          exit\
        }\
       }\
       END{\
        if(fertig)exit 1;\
        if(!gef)printf "'$blau$db$reset' nicht gefunden, ";\
        printf "verarbeite '$blau$db$reset':"\
       }' $pd
      if [ $? = 0 -o $dbda = 0 ]; then
        # ... die auch eine Datenbank enthält
#        ausf "grep '^CREATE DATABASE' \"$Q\""; if test "$resu"; then
        if test "$(grep '^CREATE DATABASE' "$Q")"; then
         LC_NUMERIC=de_DE printf " Stelle sie von \"$blau$Q$reset\" her (Größe: $blau%'.f$reset)!\n" $Sz
         sed -i.bak 's/ROW_FORMAT=FIXED//g' "$Q";
         ausf "mysql -u\"\$mroot\" -p\"\$mrpwd\" -hlocalhost <\"\$Q\""
         [ $ret = 0 ]&&{
           ausf "sed -i '/^\\($db=\\).*/{s//\\1$Zt/;:a;n;ba;q};\$a$db=$Zt' $pd"
  # oder:        sed -i '/^\('$db'=\).*/{s//\1'$Zt'/;:a;n;ba;q};$a'$db'='$Zt'' $pd
         } 
        else
         printf " Datei \"$Q\" enthaelt aber keine Datenbank!\n";
        fi;
      fi;
    fi;
  done;
	printf "${dblau}Ende dbinhalt$reset()\n";
} # dbinhalt

# Start
# hier geht's los
printf "${dblau}$0$reset()${blau} Copyright Gerald Schade$reset\n"
commandline "$@"; # alle Befehlszeilenparameter übergeben
echo a|read -e 2>/dev/null; obbash=$(awk 'BEGIN{print ! '$?'}');
test "$(id -u)" -eq 0||{ printf "Wechsle zu ${blau}root$reset, bitte ggf. ${blau}dessen$reset Passwort eingeben für Befehl ${blau}su -c $meingespfad \"$gespar\"$reset: ";su -c "$meingespfad $gespar";exit;};
echo Starte mit los.sh...
[ $obteil = 0 -o $obbs = 1 ]&&bildschirm;
variablen;
 [ $obteil = 0 -o $obhost = 1 ]&&setzhost;
 [ $obteil = 0 -o $obsmb ]&&setzbenutzer;
 [ $obteil = 0 ]&&setzpfad;
 [ $obteil = 0 -o $obprompt = 1 ]&&setzprompt;
 [ $obteil = 0 -o $obfritz = 1 ]&&fritzbox;
 [ $obteil = 0 -o $obmt = 1 ]&&mountlaufwerke;
	setzinstprog;
 [ $obteil = 0 -o $obprog = 1 ]&&proginst;
 [ $obteil = 0 -o $obmysql = 1 -o $mysqlneu = 1 ]&&richtmariadbein;
 [ $obteil = 0 -o $obsmb = 1 ]&&sambaconf;
 [ $obteil = 0 -o $obmust = 1 ]&&musterserver;
 [ $obteil = 0 ]&&firewall http https dhcp dhcpv6 dhcpv6c postgresql ssh smtp imap imaps pop3 pop3s vsftp mysql rsync turbomed; # firebird für GelbeListe normalerweise nicht übers Netz nötig
 [ $obteil = 0 -o $obtv = 1 ]&&teamviewer15;
 [ $obteil = 0 ]&&cron;
 [ $obteil = 0 -o $obtm = 1 ]&&turbomed;
# if test "$1" == mysqlneu; then dbinhalt immer; else dbinhalt; fi;
 [ $obteil = 0 -o $obmysql = 1 -o $mysqlneu = 1 ]&&{ [ $mysqlneu = 1 ]&&{ dbinhalt immer;:; }||{ [ $obmysql = 1 ]&&dbinhalt; } }
 [ $obteil = 0 ]&&speichern;
 [                $obfb = 1 ]&&firebird;
printf "${dblau}Ende von $0$reset\n";

if false; then
	eintr="@reboot mount /$Dvz";
	tmp=vorcrontab;
	if ! crontab -l|sed '^[^#]' >/dev/null 2>&1; then {
		echo "$eintr" >$tmp; crontab <$tmp;
		printf "\"$blau$eintr$reset\" in crontab eingetragen.\n";
	} else {
	crontab -l|grep -q "^$eintr" ||{ crontab -l|sed "/^[^#]/i$eintr" >$tmp;crontab <$tmp;printf "\"$blau$eintr$reset\" in crontab ergänzt.\n";};
} fi;
fi;
