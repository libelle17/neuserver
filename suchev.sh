#!/bin/bash
#echo "Suche in $1 nach $2, mit enthaltenem """$3""""
vi +/"""$3""" `find "$1" -type f -iname "$2" -print0 | /usr/bin/xargs -0 -r grep -il """$3""" --null | /usr/bin/xargs -0 -r ls` -p
