#!/usr/bin/awk -f
# ermittle jüngste Datei in pfad nach Muster n1*n2 anhand Datum im Dateinamen,
# die nicht kleiner als 80% der größten dort mit diesem Muster ist
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
