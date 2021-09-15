#!/bin/bash
# benennt den virtuellen Gast den Computers wirt ggf. um 
# gast=virtwin0;
# wirt=linux0;
user=sturm;
for wirt in linux0 linux1; do
  case wirt in linux0) gast=virtwin0;; linux1) gast=virtwin;; esac;
  vip=$(ssh $wirt VBoxManage guestproperty get Win10 /VirtualBox/GuestInfo/Net/2/V4/IP 2>/dev/null|cut -d' ' -f2);
  if test "$vip"; then 
    vhost=$(if nerg=$(nmblookup -A $vip); then echo $nerg|sed -n "s/.*"$vip"[[:space:]]*\([^[:space:]]*\).*/\L\1/p"; else ssh $user@$vip hostname|sed 's/\r$//'; fi); 
    if test "$vhost"/ != "$gast"/; then 
      ssh $user@$vip "WMIC computersystem where caption=\"$vhost\" rename \"$gast\""; ssh $user@$vip shutdown -t 1 -r; 
    fi; 
  fi;
done;
