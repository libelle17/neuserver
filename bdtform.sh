!#/bin/bash
# gibt Formulare aus einer Turbomed-BDT-Datei aus:
# 1) merkt sich Datum und Uhrzeit
# 2) falls eine relevante Zeile kommt (je nach Umfang z.B. 6295, 6296, 6297, oder auch noch 6298, 6299), wird sie ausgegeben, je nachdem farbig, bei 6295 auch mit angehängtem Datum und Uhrzeit
# (in den BDT-Dateien ist das NeueZeile-Zeichen \r\n, nach N in sed nur \n)
umf=567;
[ "$2" ]&&umf="$2";
sed '/^...6200/{s/^.\{7\}//;h};/^...6201/{s/^.\{7\}//;H};/^...629['$umf']/!d;s/^...\(....\)/\1 /;=;/^6295/{G;s/\r\n/ /g;}' "$1" |sed 'N;s/\n/ /;s/\(.*6295.*\)/\o033[1;34m\1\o033[0m/;s/\(.*Elektronischer.*\)/\o033[1;31m\1\o033[0m/'
