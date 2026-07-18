#!/bin/bash
# rett.sh - "Rettungs"-Sicherung wichtiger Systemdateien/-verzeichnisse
# (nicht der Patientendaten selbst) nach /DATA/rett, für den Fall eines
# Systemausfalls: /etc/{samba,hosts,vsftpd*.conf,my.cnf,fstab,capisuite,
# sysconfig/isdn,openvpn}, /usr/lib64/capisuite, /opt/turbomed (ohne
# Papierkorb, mit --delete), diverse /root-Dateien (.vimrc, Credentials,
# bin, crontabakt), sowie /mnt und /amnt (nur oberste Ebene, -x = bleibt im
# Dateisystem) und /obsl*/ungera. Ein testweiser Komplettabgleich nach
# /DAT3 ist über "if [ 0 -eq 1 ]" fest deaktiviert. Läuft nur, wenn /DATA
# gemountet ist; setzt am Ende Eigentümer/Rechte für /DATA/rett zurück.
# Aufruf ohne Parameter. ACHTUNG: die Bedingung "test [[ $HOST == "linux4" ]]"
# oben ist fehlerhaft (kein echtes [[...]], sondern [[/==/]] als einzelne,
# an "test" übergebene Wörter) - "test" bricht dabei immer mit "Zu viele
# Argumente" ab (getestet, unabhängig vom Wert von $HOST), der Exitcode ist
# dadurch immer ungleich 0. Das Mounten von /hDATA und /DATA in diesem
# if-Zweig wird deshalb NIE ausgeführt, unabhängig vom Hostnamen - die
# beiden mount-Zeilen sind praktisch toter Code.
if test [[ $HOST == "linux4" ]]; then
 mount /hDATA
 mount /DATA
fi
if $(mountpoint -q /DATA); then 
  mkdir /DATA/rett 2>/dev/null
  mkdir /DATA/rett/etc 2>/dev/null
  ionice -c3 nice -n19 rsync -avu /etc/samba /etc/hosts /etc/vsftpd*.conf /etc/my.cnf /etc/fstab /etc/capisuite /DATA/rett/etc/ # keine Anführungszeichen um den Stern!
  ionice -c3 nice -n19 rsync -avu /etc/sysconfig/isdn /DATA/rett/etc/sysconfig
  mkdir /DATA/rett/usr 2>/dev/null
  ionice -c3 nice -n19 rsync -avu /usr/lib64/capisuite /DATA/rett/usr/lib64
  ionice -c3 nice -n19 rsync -avu /etc/openvpn /DATA/rett/etc 
  ionice -c3 nice -n19 rsync -avu --delete --exclude "Papierkorb" /opt/turbomed/ /DATA/rett/turbomed/
  ionice -c3 nice -n19 rsync -avu /root/.vimrc /root/.fbcredentials /root/.getmail /root/.mysqlpwd /root/.7zpassw /root/bin /root/crontabakt /DATA/rett/root/
  ionice -c3 nice -n19 rsync -avu -x /mnt/ /DATA/rett/mnt
  ionice -c3 nice -n19 rsync -avu -x /amnt/ /DATA/rett/amnt
  ionice -c3 nice -n19 rsync -avu /obsl* /DATA/rett/
  #ionice -c3 nice -n19 rsync -avu /gerade /DATA/rett/
  ionice -c3 nice -n19 rsync -avu /ungera /DATA/rett/
  if [ 0 -eq 1 ]; then
   mountpoint -q /DAT3 && ionice -c3 nice -n19 rsync -avu --delete /DATA/ /DAT3
  fi
  chown schade:praxis -R /DATA/rett
  chmod 774 -R /DATA/rett
fi
