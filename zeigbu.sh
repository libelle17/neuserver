#!/bin/bash
# zeigbu.sh - zeigt laufende Backup-Prozesse (Namen wie bumo.sh, bunacht.sh,
# bulinux.sh usw., Muster "bu" gefolgt von einem Zeichen außer g/s, damit
# bugem.sh/bustate.sh - die nur gesourcte Helferskripte sind, keine eigenen
# Prozesse - nicht mit auftauchen) sowie sich selbst herausgefiltert.
# Aufruf ohne Parameter.
ps -Alf|egrep 'bu[^gs]'|grep -v "grep\|zeigbu"
