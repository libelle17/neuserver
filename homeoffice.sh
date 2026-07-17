#!/bin/bash
# homeoffice.sh - wie gutenacht.sh, aber laesst anmh und anmww an
# (z.B. fuer Fernzugriff/Homeoffice ueber Nacht).

ziele="anmmo anmmw anmoo bzw2 fuss labor3 sono1 sr25 sr6 szo1 szon1 szoo1 szow1 szs1"

for pc in $ziele; do
  if ! ping -c1 -W1 "$pc" >/dev/null 2>&1; then
    echo "$pc: nicht anpingbar, ausgelassen"
    continue
  fi
  ok=
  for user in sturm administrator; do
    if ssh -o ConnectTimeout=5 -o BatchMode=yes "$user@$pc" "shutdown /t 0 /s /f" >/dev/null 2>&1; then
      echo "$pc: heruntergefahren (als $user)"
      ok=1
      break
    fi
  done
  [ -z "$ok" ] && echo "$pc: anpingbar, aber SSH (sturm/administrator) fehlgeschlagen"
done
