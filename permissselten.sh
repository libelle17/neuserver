#!/bin/bash
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
