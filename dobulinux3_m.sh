#!/bin/zsh
# _m heisst mittags
# z.B. linux3.site, mit Absicht kein Buchstabe angehaengt, falls HOST nicht gesetzt
if [ ${HOST%%.*} != linux1 ]; then
 bulinux3.sh
 ende_m.sh
fi; 
echo done
