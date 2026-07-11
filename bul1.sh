# bul1.sh – erweitert:
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
