#!/bin/zsh
D=jpgumw.sh; 
ps h -C $D >/dev/null||eval $D "$@";
