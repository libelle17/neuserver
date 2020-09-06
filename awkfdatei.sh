#!/usr/bin/awk -f
# ermittle jüngste Datei in pfad nach Muster n1*n2, die nicht kleiner als 80% der größten dort mit diesem Muster ist
BEGIN {
#  pfad="/DATA/sql"
#  n1="quelle--"
#  n2=".sql"
  cmd="ls "pfad"/"n1"*"n2" -S";
  cmd|getline fname;
  cmd="find "pfad" -path "fname" -printf '%s\n'"
  cmd|getline groe;
  mingroe=groe*0.8
  ming=sprintf("%.0f",mingroe)
  cmd="find "pfad" -maxdepth 1 -size +"ming"c -name "n1"'*'"n2" -printf \"%T@ %p\\n\"|sort -rn|cut -d' ' -f2"
  cmd|getline ergf;
  print ergf;
}
