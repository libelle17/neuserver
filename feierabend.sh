#/bin/bash
# feierabend.sh - fährt die genannten Windows-PCs der Praxis herunter
# (Feierabend = Arbeitsende): pingt jeden PC an und schickt bei Erreichbarkeit
# per SSH (administrator@<pc>) ein "shutdown /t 1 /s". PCs, die gerade aus
# sind, werden stillschweigend übersprungen (Ping schlägt fehl, kein SSH-
# Versuch). Aufruf ohne Parameter. Ähnliches Skript für kürzere Pausen:
# frühstückspause.sh (fast identische PC-Liste).
for pc in \
  anmmo \
  anmoo \
  anmww \
  bzw2 \
  fuss \
  labor3 \
  res1 \
  res3 \
  sono1 \
  sr6 \
  srn2 \
  szo1 \
  szon1 \
  szoo1 \
  szow1 \
  szs1 \
; do
 ping -c1 -W2 $pc && ssh administrator@$pc shutdown /t 1 /s; 
done;
