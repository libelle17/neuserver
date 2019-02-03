#!/bin/bash
su
echo "gewünschter Servername, dann Ender:"
read $SERVER
hostnamectl set-hostname '$SERVER' 

