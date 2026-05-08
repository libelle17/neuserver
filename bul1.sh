# bul1.sh – erweitert:
LINEINS=linux1;
buhost=$(hostname);
buhost=${buhost%%.*};
# Zielverzeichnis für /DATA-Kopien – rechnerabhängig:
case "$buhost" in
	linux7) DATAZIEL=DATA/DATA;;  # linux7: /DATA/DATA statt /DATA
	*)      DATAZIEL=DATA;;       # alle anderen (linux0 etc.): /DATA
esac;
