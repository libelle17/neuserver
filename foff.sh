#!/bin/bash
# foff.sh - schaltet auf dem virtuellen Windows-Rechner "virtwin" (per SSH
# als Administrator) die Windows-Firewall für das Profil "public" AUS.
# Aufruf ohne Parameter. Gegenstück: fon.sh (schaltet wieder ein).
ssh administrator@virtwin "netsh advfirewall set public state off"
