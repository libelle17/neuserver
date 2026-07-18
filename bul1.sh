# bul1.sh - keine eigenständig ausführbare Datei, sondern zum Sourcen (". bul1.sh")
# aus den bu*.sh-Backup-Skripten (z.B. bumo.sh, bunacht.sh, bulinux.sh) direkt
# nach deren MUPR-Ermittlung. Legt die für Push/Pull-Entscheidung und
# Notfallbetrieb-Erkennung nötigen Variablen fest: $LINEINS (Name des
# Haupt-/Quellrechners), $buhost (eigener Hostname ohne Domain), $EIGENHOST/
# $EIGENNR (echte Identität auch während geliehener Identität im
# Notfallbetrieb, s.u.) und $DATAZIEL (rechnerabhängiger Name des lokalen
# /DATA-Ziels beim Zielrechner-Pull).
LINEINS=linux1;
buhost=$(hostname);
buhost=${buhost%%.*};
# Notfallbetrieb-Erkennung (Marker von uebernahme.sh, entfernt von
# ruecknahme.sh, s. dort): EIGENHOST ist die eigene, urspruengliche
# Identitaet dieses Rechners - im Normalbetrieb identisch zu $buhost,
# waehrend einer geliehenen Identitaet (z.B. linux0 als linux1) aber die
# tatsaechliche eigene (z.B. linux0). Damit koennen ziele-Listen (bunacht.sh,
# bumo.sh) sich selbst herausfiltern, statt waehrend des Notfallbetriebs auf
# die eigene, gerade verlassene Identitaet zu sichern.
if [ -r /etc/notfallbetrieb ]; then
  EIGENHOST=$(cat /etc/notfallbetrieb);
else
  EIGENHOST=$buhost;
fi;
EIGENNR=${EIGENHOST#linux};
# Zielverzeichnis für /DATA-Kopien – rechnerabhängig:
case "$buhost" in
	linux7) DATAZIEL=DATA/DATA;;  # linux7: /DATA/DATA statt /DATA
	*)      DATAZIEL=DATA;;       # alle anderen (linux0 etc.): /DATA
esac;
