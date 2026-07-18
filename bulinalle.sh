#!/bin/bash
# bulinalle.sh - ruft bulinux.sh (echter Lauf, -e) nacheinander für alle vier
# Linux-Zielrechner auf (linux0, linux3, linux7, linux8); siehe bulinux.sh für
# dessen Parameter/Verhalten im Detail. Aufruf ohne Parameter.
bulinux.sh -e linux0
bulinux.sh -e linux3
bulinux.sh -e linux7
bulinux.sh -e linux8
