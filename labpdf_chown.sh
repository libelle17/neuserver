#!/bin/bash
# labpdf_chown.sh - vmparse2 laeuft als root (kann nicht als sturm laufen,
# braucht intern sudo/root fuer DB-Start-Pruefung und /var/log/vmp.log) und
# legt dabei u.a. in /DATA/Patientendokumente/labpdf Dateien als root:root
# an statt sturm:praxis (Ursache im Detail ungeklaert, betraf zuletzt den
# 5:52-Uhr-Labor-Lauf). Deshalb hier stattdessen periodisch nachkorrigieren.
# /dok wird ausgeklammert (eigener, sehr grosser Baum, dort separat ueber
# das smbusers-Mapping abgedeckt).
find /DATA/Patientendokumente -maxdepth 2 -path '/DATA/Patientendokumente/dok' -prune -o -user root -exec chown sturm:praxis {} +
