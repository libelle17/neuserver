# virtnamen.sh - keine eigenständig ausführbare Datei, sondern zum Sourcen
# aus anderen Skripten (z.B. buwin10.sh, vdurch.sh), NACHDEM dort $wirt
# (Hostname des Trägerrechners, z.B. linux0/1/3/7/8) gesetzt wurde. Leitet
# daraus $gpc (Name des VirtualBox-Wirts-Rechners, z.B. "virtwin0"), $gast
# (Name der virtuellen Maschine, hier immer "Win10") und $tush (Befehl zum
# Ausführen auf dem Wirt: lokal per "sh -c" auf $LINEINS, sonst per ssh) ab.
# Bleibt $wirt unbekannt (z.B. linux3, das keinen virtuellen Server hat),
# bleiben $gpc/$gast leer.
# for wirt in "$auswahl"; do
 case $wirt in *0*) gpc=virtwin0; gast=Win10;;
               *1*) gpc=virtwin;  gast=Win10;;
               *3*) gpc=virtwin3;  gast=Win10;;
               *7*) gpc=virtwin7; gast=Win10;;
               *8*) gpc=virtwin8; gast=Win10;;
 esac;
 case $wirt in $LINEINS)tush="sh -c ";;*)tush="ssh $wirt ";;esac
