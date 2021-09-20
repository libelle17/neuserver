#!/bin/bash
Q=/opt/turbomed/Formulare/Patientenmenue
Q=/opt/turbomed
Q=/mnt/virtwin/turbomed/Formulare/Patientenmenue
Q=/mnt/virtwin/turbomed
find $Q -exec sh -c 'q="{}";z=$(echo "{}"|sed '\''s/\xc4/\xc3\x84/g;s/\xfc/\xc3\xbc/g;s/\xdc/\xc3\x9c/g;s/\xe4/\xc3\xa4/g;s/\xdf/\xc3\x9f/g;s/\xf6/\xc3\xb6/g;s/\xc3\x83\xc2\x84/\xc3\x84/g;s/\xc3\x83\xc2\xa4/\xc3\xa4/g;s/\xc3\x83\xc2\xb6/\xc3\xb6/g;s/\xc3\x83\xc2\x96/\xc3\x96/g;s/\xc3\x83\xc2\xbc/\xc3\xbc/g;s/\xc3\x83\xc2\x9c/\xc3\x9c/g;s/\xc3\x83\xc2\x9f/\xc3\x9f/g;'\'');[ "$q" != "$z" ]&&{ echo bennene um: "$q"=>"$z"; mv -u "$q" "$z" 2>/dev/null;[ -f "$q" ]&&{ echo loesche quelle \"$q\"; rm "$q";};[ -d "$q" ]&&{ echo loesche quelle \"$q\"; rmdir "$q";};}' \;
# find $Q -exec sed 's/\xc4/\xc3\x84/g;s/\xfc/\xc3\xbc/g;s/\xdc/\xc3\x9c/g;s/\xe4/\xc3\xa4/g;s/\xdf/\xc3\x9f/g;s/\xf6/\xc3\xb6/g'

