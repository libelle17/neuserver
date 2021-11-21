#!/bin/zsh
prot=${0%%sh}prot;                                  # Datei mit dem Stand des letzten Aufrufs = Name dieses Programms mit ".prot" statt ggf ".sh" hinten
[ -f "$prot" ]&&zp=$(stat $prot -c %y|sed 's/\..*//'); # wenn diese Datei da, dann deren Änderungszeitpunkt ohne Sekundenbruchteile in $zp merken
for iru in 1 2; do                                  # 1. Runde zum Prüfen und Melden, 2. zum Protokollieren
  for lw in / /DATA; do                             # zu untersuchende Laufwerke
    pc=$(df --output=pcent $lw|sed -n '/^Use/!{/^Verw/!{s/%//p}}'); # Prozentzahl der Belegung, bei englischer oder deutscher shell
    case $iru in
    1)
    [ -f "$prot" ]&&pca=$(sed -n '/\'$lw' /{s/[^ ]* *//;p}' $prot)||pca=100; # bei wiederholtem Aufruf letzte Prozentzahl in $pca speichern
    for gre in 70 75 80 85 90 95; do                                         # Liste der Grenzen, bei deren je 1. Überschreitung gewarnt wird
      if test $pc -gt $gre -a $pca -le $gre; then                            # wenn also Grenze überschritten und zuvor noch nicht 
        echo $lw zu $pc % befüllt, nach $pca % um $zp!
        printf "Liebe Praxis,\nAuf Ihrem Rechner $(hostname) wurde soeben neu festgestellt, dass das Laufwerk $lw zu $pc %% befüllt ist, nach $pca %% um $zp.\nBitte verständigen Sie den Systemadministrator!\nMit besten Grüßen, Ihr Linuxrechner"|mail -s "Achtung, Warnung von $(hostname) zu Laufwerk $lw wegen Befüllung zu $pc %!" diabetologie@dachau-mail.de
        break;                                                               # je Laufwerk nur für eine Grenze warnen
      fi;
    done;;
    2)
      echo "$lw $pc">>$prot;;                                                # aktuelle Prozentzahl speichern
    esac;
  done;                                                                          # nach der 1. Runde
  [ $iru = 1 ]&&for iiru in 4 3 2 1 ""; do                                       # nach der 1. Runde: Liste der alten Protokolle
    [ -f "$prot$iiru" ]&&mv $prot$iiru $prot$(expr 0$iiru + 1);                  # daraus jede Datei eins höher benennen
  done;
done;
