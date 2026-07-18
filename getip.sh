#!/bin/bash
# getip.sh - erzwingt eine neue IP-Adresse/ARP-Auflösung auf der kabelgebun-
# denen Verbindung "Wired connection 1" (Interface eno1): Verbindung trennen,
# ARP/Nachbarschafts-Cache für eno1 leeren, Verbindung neu aufbauen (löst
# i.d.R. eine neue DHCP-Anfrage aus). Aufruf ohne Parameter.
nmcli connection down "Wired connection 1"
ip neigh flush dev eno1
nmcli connection up "Wired connection 1"
