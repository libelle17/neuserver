#!/usr/bin/awk -f
# awkfdatei.sh - ermittelt die jüngste Datei in "pfad" nach Muster
# "n1*n2" anhand des Datums im Dateinamen (per "find ... -printf '%f %p' |
# sort -rn", sortiert also nach dem Dateinamen selbst, nicht nach mtime -
# funktioniert nur, wenn das Datum im Namen sortierbar vorkommt, z.B.
# YYYYMMDD), die zusätzlich NICHT kleiner als 80% der größten dort
# vorhandenen Datei mit diesem Muster ist (Schutz davor, eine zwar neuere,
# aber unvollständig/abgebrochen geschriebene kleine Datei als "die
# jüngste" zurückzugeben). Aufruf: awk -v pfad="<Verzeichnis>" -v n1="<Präfix>"
# -v n2="<Suffix>" -f awkfdatei.sh (pfad/n1/n2 müssen als awk-Variablen
# übergeben werden, es gibt keine Kommandozeilenparameter im üblichen Sinn).
BEGIN {
  # Größte Datei ermitteln
  cmd="ls " pfad "/" n1 "*" n2 " -S | head -1";
  cmd | getline fname;
  close(cmd);
  cmd="stat --printf='%s' \"" fname "\"";
  cmd | getline groe;
  close(cmd);
  mingroe = groe * 0.8;
  ming = sprintf("%.0f", mingroe);

  # Alle Dateien >= 80% der größten, nach Datum im Dateinamen sortieren
  cmd="find " pfad " -maxdepth 1 -size +" ming "c -name '" n1 "*" n2 "' -printf '%f %p\\n' | sort -rn | head -1 | awk '{print $2}'";
  cmd | getline ergf;
  close(cmd);
  print ergf;
}
