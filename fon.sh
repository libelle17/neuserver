#!/bin/bash
# fon.sh - schaltet auf dem virtuellen Windows-Rechner "virtwin" (per SSH als
# Administrator) die Windows-Firewall für das Profil "public" wieder EIN.
# Aufruf ohne Parameter. Gegenstück: foff.sh (schaltet aus).
ssh administrator@virtwin "netsh advfirewall set public state on"
