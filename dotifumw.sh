#!/bin/zsh
if ps -Alf | grep tifumw.sh | grep -v grep | grep -v $0 >/dev/null; then
else
  /root/bin/tifumw.sh $@
fi
