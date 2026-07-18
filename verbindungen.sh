#!/bin/bash
# verbindungen.sh - trennt auf dem virtuellen Windows-Rechner "virtwin" (per
# SSH als Administrator) alle offenen SMB/Netzwerk-Sitzungen ("net session"),
# deren Client-IP das Muster ".2. " enthält (grobe Filterung auf ein
# bestimmtes IP-Subnetz/Adressoktett). Aufruf ohne Parameter. Für IPv6-
# Clients (die hier nicht erfasst werden) müsste man laut Kommentar
# stattdessen mit PowerShell get-smbsession/close-smbsession -force
# -sessionid arbeiten.
for A in $(ssh administrator@virtwin net sess|grep "\.2. "|cut -d" " -f1); do ssh administrator@virtwin net sess $A /delete /y; done
