#!/bin/bash
# zugriff.sh - räumt Berechtigungen unter /DATA/Patientendokumente auf: setzt
# alle Einträge direkt darunter auf 777 (jeder darf lesen/schreiben/
# ausführen - großzügig, aber offenbar bewusst so gewählt für diesen
# Freigabe-Ordner), und korrigiert Eigentümer sturm:praxis für die
# AccuChek-Tagebücher (Diaries/pa*) sowie rekursiv für "Fotos neu". Aufruf
# ohne Parameter.
chmod 777 /DATA/Patientendokumente/*
chown sturm:praxis /DATA/Patientendokumente/Datenbanken/AccuChek/Diaries/pa*
chown sturm:praxis -R /DATA/Patientendokumente/Fotos\ neu
