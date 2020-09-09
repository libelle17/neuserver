#!/bin/zsh
if ps -Alf | grep pdfumw.sh | grep -v grep | grep -v $0 >/dev/null; then
else
  /root/bin/pdfumw.sh $@
fi
