#!/bin/bash
# echo "Suche in $1 nach $2, mit enthaltenem """$3"""
find "$1" -xdev -type f -iname "$2" -print0 | /usr/bin/xargs -0 -r grep -il """$3""" --null | /usr/bin/xargs -0 -r ls -l --time-style=full-iso | sort -nk 6,7
