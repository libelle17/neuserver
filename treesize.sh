#!/bin/sh
du "$1" -x -k --max-depth=1 | sort -nr | awk '
    BEGIN {
	split("KB,MB,GB,TB", Units, ",");
    }
    {
       u = 1;
       while ($1 >= 1024) {
         $1 = $1 / 1024;
         u += 1;
       }
       $1 = sprintf("%.lf %s", $1, Units[u]);
       print $0;
    }
   '
