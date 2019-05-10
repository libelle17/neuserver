#!/bin/sh
ichges="$(readlink -f "$0")";  # ~/neuserver/wegmailen.sh
ich=${ichges##*/};             # wegmailen.sh
confnm=./${ich%.*}.conf;       # wegmailen.conf
[ -f "$confnm" ]&&. "$confnm";
confdt="$(getent passwd $(logname 2>/dev/null||loginctl user-status|sed -n '1s/\(.*\) .*/\1/p'||whoami)|cut -d: -f6)/.config/$confnm"; 
[ -f "$confdt" ]&&. "$confdt"; # $HOME/.config/wegmailen.conf

mkdir -p "$ZMVZ";
for dt in "$ZMVZ"/*; do
 echo Datei: \"$dt\" Dateiende;
done;
