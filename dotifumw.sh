#!/bin/zsh
# dotifumw.sh - startet tifumw.sh nur, wenn nicht schon eine Instanz davon
# läuft (gleiches Muster wie dopdfumw.sh/dozupdf.sh). Aufruf: dotifumw.sh
# [Parameter für tifumw.sh], per $@ durchgereicht.
if ps -Alf | grep tifumw.sh | grep -v grep | grep -v $0 >/dev/null; then
else
  /root/bin/tifumw.sh $@
fi
