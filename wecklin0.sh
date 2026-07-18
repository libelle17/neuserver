#!/bin/bash
# wecklin0.sh - weckt gezielt nur linux0 (feste MAC-Adresse der Netzwerkkarte
# dieses Rechners) über weckalle.sh, ohne dessen übrige Geräteliste
# abzufragen. Aufruf ohne Parameter; siehe weckalle.sh -h für Details zu den
# von dort geerbten Möglichkeiten (hier ungenutzt).
weckalle.sh fc:34:97:11:89:ad
