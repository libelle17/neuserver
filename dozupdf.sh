#!/bin/bash
if ps -Alf | grep zupdf.sh | grep -v grep | grep -v $0 >/dev/null; then
else
  /root/bin/zupdf.sh $@
fi
