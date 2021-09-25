# for wirt in "$auswahl"; do
 case $wirt in *0*) gpc=virtwin0; gast=Wind10;;
               *1*) gpc=virtwin;  gast=Win10;;
               *7*) gpc=virtwin7; gast=Wi10;;
 esac;
 case $(hostname) in $wirt*)tussh="sh -c";;*)tussh="ssh $wirt";;esac;
