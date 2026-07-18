#!/bin/zsh
# dozupdf.sh - startet zupdf.sh nur, wenn nicht schon eine Instanz davon
# läuft (gleiches Muster wie dopdfumw.sh/dotifumw.sh). Aufruf: dozupdf.sh
# [Parameter für zupdf.sh], per $@ durchgereicht.
if ps -Alf | grep zupdf.sh | grep -v grep | grep -v $0 >/dev/null; then
else
  /root/bin/zupdf.sh $@
fi
