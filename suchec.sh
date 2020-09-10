#!/bin/bash
#echo "Suche in $1 nach *.h, *.c, *.hpp oder *.cpp, mit enthaltenem """$2""""
vi +/"""$2""" `find "$1" -xdev -type f \( -iname "*.h" -o -iname "*.c" -o -iname "*.hpp" -o -iname "*.cpp" \) -print0 | /usr/bin/xargs -0 -r grep -il """$2""" --null | /usr/bin/xargs -0 -r ls` -p
