#!/bin/bash
# benennt den virtuellen Gast den Computers wirt ggf. um 
# gast=virtwin0;
# wirt=linux0;
user=sturm;
[ "$1/" = "/v/" -o "$1/" = "-v/" -o "$1/" = "--verbose/" ]&&verb=v;
blau="\033[1;34m";
dblau="\033[0;34;1;47m";
rot="\033[1;31m";
reset="\033[0m";

for wirt in linux0 linux1 linux7; do
 case $wirt in *0*) gpc=virtwin0; gast=Wind10;;
               *1*) gpc=virtwin;  gast=Win10;;
               *7*) gpc=virtwin7; gast=Wi10;;
 esac;
 case $(hostname) in $wirt*)tussh=;;*)tussh="ssh $wirt";;esac;
  printf "Wirt:  $blau$wirt$reset, gast: $blau$gast$reset, Soll-Gast-PC : $blau$gpc$reset";
  [ "$verb" ]&& printf "\n";
  # VBoxGuestAdditions im Gastsystem auf CD mounten und dort die exe aufrufen
  # der ssh-public-key soll dort manuell an autorized_keys angehaengt werden
  MaxNr=$($tussh VBoxManage guestproperty get $gast /VirtualBox/GuestInfo/Net/Count|cut -d' ' -f2);
  [ "$verb" ]&&printf " MaxNr: $blau$MaxNr$reset\n";
  for Nr in 0 1 2 3; do
    vip=$($tussh VBoxManage guestproperty get $gast /VirtualBox/GuestInfo/Net/$Nr/V4/IP 2>/dev/null|cut -d' ' -f2);
    [ "$verb" ]&&printf " vip:   $blau$vip$reset";
    case $vip in 192.*)
      [ "$verb" ]&&printf " (vielleicht passend)";
      vhost=$(ping -c1 -W1 -q "$vip" >/dev/null&&if nerg=$(nmblookup -A $vip); then 
                echo $nerg|sed -n "s/.*"$vip"[[:space:]]*\([^[:space:]]*\).*/\L\1/p"; else ssh $user@$vip hostname|sed 's/\r$//'; 
              fi); 
      [ -z "$verb" -a "$vhost" ]&&printf ", vip: $blau$vip$reset";
      [ "$verb" -o "$vhost" ]&&printf ", Adapter Nr: $blau$Nr$reset, vhost aus nmblookup: $blau$vhost$reset\n"
      if test "$vhost" -a "$vhost"/ != "$gpc"/; then 
        printf "$rot benenne $vhost in $gpc um!$reset\n";
        ssh $user@$vip "WMIC computersystem where caption=\"$vhost\" rename \"$gpc\""; ssh $user@$vip shutdown -t 1 -r; 
      fi; 
      [ "$vhost" ]&&break;;
     *)
       [ "$verb" ]&& printf "\n";
    esac;
    [ "$Nr"/ = "$MaxNr"/ ]&&break;
  done;
done;
