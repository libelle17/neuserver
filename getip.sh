#!/bin/bash
nmcli connection down "Wired connection 1"
ip neigh flush dev eno1
nmcli connection up "Wired connection 1"
