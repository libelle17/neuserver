#!/bin/bash
# permissselten.sh - "selten" laufender Rechte-Reparaturbefehl: der aktive
# Teil liest den "datadir"-Pfad aus /etc/my.cnf aus und setzt dessen
# Eigentümer rekursiv auf mysql:mysql (z.B. nach einem Restore, bei dem die
# Dateien mit falschem Eigentümer zurückkopiert wurden). Alles danach
# (chown/chmod für /DATA, /DAT1, /gerade, /ungera, /obsl?uft) ist wegen des
# unbedingten "exit;" TOTER CODE und läuft nie automatisch mit - offenbar ein
# Vorrat weiterer, nur bei Bedarf manuell durch Entfernen des exit zu
# aktivierender Rechte-Korrekturen. Aufruf ohne Parameter.
datadir=$(sed -n '/^[[:space:]]*datadir[[:space:]]*=/{s;.*=[[:space:]]*\(.*\);\1;p}' /etc/my.cnf);[ "$datadir" ]&&{ echo $datadir; chown mysql:mysql -R "$datadir";echo fertig;};
exit;
chown schade:praxis -R /DATA
chmod 770 -R /DATA
chown schade:praxis -R /DAT1
chmod 770 -R /DAT1
# chown schade:praxis -R /DATAalt
# chmod 770 -R /DATAalt
# chown schade:praxis -R /DATalt
# chmod 770 -R /DATalt
chown schade:praxis -R /gerade
chmod 770 -R /gerade
chown schade:praxis -R /ungera
chmod 770 -R /ungera
chown schade:praxis -R /obsl?uft
chmod 770 -R /obsl?uft
