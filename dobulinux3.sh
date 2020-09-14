#!/bin/zsh
# z.B. linux3.site, mit Absicht kein Buchstabe angehaengt, falls HOST nicht gesetzt
if [ ${HOST%%.*} != linux1 ]; then
 /root/bin/bulinux3.sh
 /root/bin/ende.sh
fi; 
echo done
