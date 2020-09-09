#!/bin/zsh
if [ $(ls -l /usr/bin/termine | cut -b 4) = '-' ]; then
  date +Berechtigung_eingeschraenkt_seit_%F_%H:%M:%S >> /var/log/bertest.log 2>&1
fi
