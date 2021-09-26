# for wirt in "$auswahl"; do
 case $wirt in *0*) gpc=virtwin0; gast=Wind10;;
               *1*) gpc=virtwin;  gast=Win10;;
               *7*) gpc=virtwin7; gast=Wi10;;
 esac;
 case $buhost in $LINEINS)tush="sh -c";;*)tush="ssh $LINEINS";;esac
