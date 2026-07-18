#!/bin/bash
# sp.sh - setzt Eigentümer (sturm:praxis) und Zugriffsrechte (770, d.h. nur
# Eigentümer+Gruppe dürfen lesen/schreiben/ausführen, andere gar nichts)
# rekursiv für das AccuChek-Datenbankverzeichnis unter Patientendokumente neu.
# Aufruf ohne Parameter.
Vz=/DATA/Patientendokumente/Datenbanken/AccuChek
chown sturm:praxis -R $Vz
chmod 770 -R $Vz
