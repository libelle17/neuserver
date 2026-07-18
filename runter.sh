#/bin/bash
# runter.sh - inhaltlich identisch zu frühstückspause.sh (fährt dieselbe
# Liste von Windows-PCs der Praxis per Ping+SSH-shutdown herunter, s.
# dort), nur unter einem allgemeineren Namen ("herunterfahren" statt an
# eine bestimmte Pause gebunden). Aufruf ohne Parameter.
for pc in \
  anmmo \
  anmmw \
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
