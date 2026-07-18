#!/bin/bash
# berecht.sh - setzt Zugriffsrechte für einzelne, besonders sensible/wichtige
# Dateien unter /DATA/eigene Dateien fest: 550 (nur Eigentümer+Gruppe lesen/
# ausführen, kein Schreiben - schützt vor versehentlichem Überschreiben) für
# die Pumpeneinstellungen, BE-Berechnungen und Office.mdb, sowie rekursiv für
# DM/Eig* zunächst 550 und danach nochmal 774 (Eigentümer+Gruppe voll,
# andere nur lesen) - die letzte chmod-Zeile gewinnt also für DM/Eig*.
# Aufruf ohne Parameter.
chmod 550 /DATA/eigene\ Dateien/Webseite\ Praxis\ 1/Pumpeneinstellung*.xls
chmod 550 /DATA/eigene\ Dateien/DM/BE-Berechnung*
chmod 550 /DATA/eigene\ Dateien/Office.mdb
chmod 550 -R /DATA/eigene\ Dateien/DM/Eig*
chmod 774 /DATA/eigene\ Dateien/DM/Eig*
