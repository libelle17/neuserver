#!/bin/bash
#echo "Suche in $1 nach $2, mit enthaltenem """$3""""
vi +/"""$2""" `find $(echo $PATH|tr ':' ' ') -type f -iname "$1" -print0 | /usr/bin/xargs -0 -r grep -il """$2""" --null | /usr/bin/xargs -0 -r ls` -p
