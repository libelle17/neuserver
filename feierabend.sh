#/bin/bash
# fährt die genannten PCs runter
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
