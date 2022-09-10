# for wirt in "$auswahl"; do
 case $wirt in *0*) gpc=virtwin0; gast=Win10;;
               *1*) gpc=virtwin;  gast=Win10;;
               *3*) gpc=;         gast=;;
               *7*) gpc=virtwin7; gast=Win10;;
               *8*) gpc=virtwin8; gast=Win10;;
 esac;
 gpc=/$gpc; # 10.9.22
 case $wirt in $LINEINS)tush="sh -c ";;*)tush="ssh $wirt ";;esac
