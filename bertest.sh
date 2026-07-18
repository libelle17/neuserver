#!/bin/zsh
# bertest.sh - Überwachungs-Skript: prüft, ob dem Ausführungsrecht-Bit des
# Eigentümers ("x" an Position 4 der "ls -l"-Ausgabe) von /usr/bin/termine
# entzogen wurde (Zeichen ist dann "-" statt "x"). Falls ja, wird das mit
# Zeitstempel in /var/log/bertest.log protokolliert - dient offenbar dazu,
# eine unerwartete Rechteänderung (z.B. durch ein fehlerhaftes chmod-Skript)
# nachträglich erkennen zu können. Aufruf ohne Parameter, typischerweise per
# Cron in regelmäßigen Abständen.
if [ $(ls -l /usr/bin/termine | cut -b 4) = '-' ]; then
  date +Berechtigung_eingeschraenkt_seit_%F_%H:%M:%S >> /var/log/bertest.log 2>&1
fi
