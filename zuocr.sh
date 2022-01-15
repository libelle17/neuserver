#!/bin/bash
# find /DATA/Patientendokumente -mindepth 1 -maxdepth 1 -iname "*.pdf"
Ort=/DATA/Patientendokumente
[ "$1"/ != / ]&&[ -d "$1" ]&&Ort="$1";
Tiefe=1;
[ "$2"/ != / ]&&Tiefe="$2";
find "$Ort" -maxdepth "$Tiefe" -type f -iname "*.pdf" -print0|xargs -0 grep -iL ocrmypdf --null|while IFS= read -r -d '' file; do 
  echo "$file"; 
#  filen=$(echo "$file"|sed 's/ä/ae/g;s/ö/oe/g;s/ü/ue/g;s/ß/ss/g;s/Ä/Ae/g;s/Ö/Oe/g;s/Ü/Ue/g');
#  filen=$(echo "$file"|sed 's/ae/ä/g;s/oe/ö/g;s/ue/ü/g;s/ss/ß/g;s/Ae/Ä/g;s/Oe/Ö/g;s/Ue/Ü/g');
#  [ "$file" != "$filen" ]&&mv "$file" "$filen";
  filen="${file}ocr";
  ocrmypdf -rcs -l deu "$file" "$filen";
  [ -f "$filen" ]&&{ touch -r "$file" "$filen"&& mv "$filen" "$file";};
done;
