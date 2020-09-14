#!/bin/bash
protrsync="/var/log/rsync.log"
echo `date +'%Y-%m-%d %H:%M:%S'` "Beginn rsync_nachsamba aus $0 \""$@"\"" >> "$protrsync"
ionice -c 3 rsync -avu --iconv=iso885915,utf8 "$@"
echo `date +'%Y-%m-%d %H:%M:%S'` "Ende rsync_nachsamba aus $0 \""$@"\"" >> "$protrsync"
