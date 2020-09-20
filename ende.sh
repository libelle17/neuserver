#!/bin/zsh
rtcwake -t $(date -d'today 13:15' +%s) -m off
# rtcwake -t $(($(date +%z|cut -b2-5|sed -e's/^0*//')*36+$(date -d'today 12:23' +%s))) -m disk
