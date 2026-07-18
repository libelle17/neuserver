#!/bin/bash
# maria.sh - kurzer Aufrufwrapper für den mariadb-Client mit den in
# ~/.mariadbpwd hinterlegten Zugangsdaten (siehe setmariadbpwdfuerpraxis.sh).
# Aufruf: maria.sh [beliebige mariadb-Parameter], z.B. "maria.sh quelle -e
# 'SELECT 1'" oder einfach "maria.sh quelle" für eine interaktive Sitzung -
# alle Argumente werden unverändert an mariadb durchgereicht ("$@").
mariadb --defaults-extra-file=~/.mariadbpwd "$@"
