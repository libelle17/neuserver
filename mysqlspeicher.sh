#!/bin/bash
# mysqlspeicher.sh - protokolliert stuendlich den Speicherbedarf von mariadb (cron, Ausgabe nach /var/log/mysqlspeicher.log)
# Anlass: am 12.10.26 hat der OOM-Killer mysqld mit 40 GB RSS beendet (innodb_buffer_pool_size nur 8 GB); mit diesem
# Protokoll soll sich zeigen, ob und wann mysqld waechst (stetig, oder sprunghaft bei bestimmten Laeufen).
# Spalten: Zeitpunkt, RSS von mysqld, MEMORY_USED laut MariaDB, verbundene/maximal genutzte Verbindungen,
# Laufzeit des Servers, verfuegbarer Speicher des Rechners, Zahl der ssh-agent-Prozesse (Leck bis 12.10.26)
P=$(pgrep -o -x mariadbd || pgrep -o -x mysqld)
rss_mb=0
[ -n "$P" ] && rss_mb=$(( $(ps -o rss= -p "$P" | tr -d ' ') / 1024 ))
werte=$(mariadb -N -B -e "SELECT
 ROUND(MAX(IF(VARIABLE_NAME='MEMORY_USED',VARIABLE_VALUE,0))/1048576),
 MAX(IF(VARIABLE_NAME='THREADS_CONNECTED',VARIABLE_VALUE,0)),
 MAX(IF(VARIABLE_NAME='MAX_USED_CONNECTIONS',VARIABLE_VALUE,0)),
 ROUND(MAX(IF(VARIABLE_NAME='UPTIME',VARIABLE_VALUE,0))/3600,1)
 FROM information_schema.GLOBAL_STATUS
 WHERE VARIABLE_NAME IN ('MEMORY_USED','THREADS_CONNECTED','MAX_USED_CONNECTIONS','UPTIME')" 2>/dev/null | tr '\t' ' ')
set -- ${werte:-- - - -}
verf_gb=$(free -g | awk 'NR==2{print $7}')
printf "%s mysqld_rss_MB=%s memory_used_MB=%s verbindungen=%s max_verbindungen=%s laufzeit_h=%s verfuegbar_GB=%s ssh_agenten=%s\n" \
  "$(date '+%d.%m.%y %H:%M')" "$rss_mb" "$1" "$2" "$3" "$4" "$verf_gb" "$(pgrep -c -x ssh-agent)"
