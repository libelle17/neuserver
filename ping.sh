#!/bin/bash
while true; do
 Z=/var/ping.log
 ping -c 1 fritz.box >/dev/null 2>&1 && date +"%F %T" >> $Z || date +"%F %T nein" >> $Z
 sleep 1
done;

