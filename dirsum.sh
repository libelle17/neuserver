# dirsum.sh - listet Dateien/Verzeichnisse wie "ls -AGl" (verstecke Dateien,
# ohne Gruppen-Spalte) und hängt am Ende eine Gesamtsumme der Dateigrößen
# (Spalte 4) an, deutsch formatiert mit Tausenderpunkten (%'d, LC_ALL=de_DE).
# Aufruf: dirsum.sh [ls-Optionen/Pfade], per "$@" durchgereicht.
hdir () {
  ls -AGl "${@}" | LC_ALL="de_DE" awk '{ total += $4; print }; END { printf("insgesamt: %'"'"'d Bytes\n", total) }'
}

hdir "$@"
