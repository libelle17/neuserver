#!/bin/bash
#echo "Suche in $1 nach $2, mit enthaltenem """$3""""
vi +/"""$3""" `find "$1" -type f -mtime -5 -iname "$2" -print0 | xargs -0 -r grep -il """$3""" --null | xargs -0 -r ls -Q` -p
