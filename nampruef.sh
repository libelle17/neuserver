#!/bin/bash
# benennt den virtuellen Gast den Computers wirt ggf. um 
# gast=virtwin0;
# wirt=linux0;
user=sturm;
for wirt in linux0 linux1; do
  case $wirt in linux0) 
     gpc=virtwin0; 
     gast=Wind10;; 
    linux1) 
     gpc=virtwin; 
     gast=Win10;; 
  esac;
  echo wirt:  $wirt
  echo gpc :   $gpc
  echo gast: $gast
  vip=$(ssh $wirt VBoxManage guestproperty get $gast /VirtualBox/GuestInfo/Net/2/V4/IP 2>/dev/null|cut -d' ' -f2);
  echo vip:   $vip
  if test "$vip"; then 
    vhost=$(if nerg=$(nmblookup -A $vip); then echo $nerg|sed -n "s/.*"$vip"[[:space:]]*\([^[:space:]]*\).*/\L\1/p"; else ssh $user@$vip hostname|sed 's/\r$//'; fi); 
    echo vhost: $vhost
    if test "$vhost"/ != "$gpc"/; then 
      ssh $user@$vip "WMIC computersystem where caption=\"$vhost\" rename \"$gpc\""; ssh $user@$vip shutdown -t 1 -r; 
    fi; 
  fi;
done;
