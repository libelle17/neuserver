#!/bin/zsh
# dopdfumw.sh - startet pdfumw.sh nur, wenn nicht schon eine Instanz davon
# läuft (Prüfung per ps/grep statt "pgrep -c -f" wie in anderen do*umw.sh-
# Varianten; "grep -v $0" filtert den eigenen Skriptnamen aus der Trefferliste
# heraus, falls er zufällig als Substring vorkäme). Aufruf: dopdfumw.sh
# [Parameter für pdfumw.sh], per $@ durchgereicht.
if ps -Alf | grep pdfumw.sh | grep -v grep | grep -v $0 >/dev/null; then
else
  /root/bin/pdfumw.sh $@
fi
