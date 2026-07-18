#!/bin/bash
# machtha.sh - ruft die gespeicherte Prozedur fuellThaP(0) in der Datenbank
# "quelle" auf (Name legt eine Befüllung/Auswertung rund um "Tha" nahe, Details
# stecken in der Prozedur selbst, nicht in diesem Aufrufskript). Aufruf ohne
# Parameter.
mariadb --defaults-extra-file=~/.mariadbpwd quelle -e"CALL fuellThaP(0);"
