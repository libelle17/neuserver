#!/bin/bash
pruefe () {
datei=/root/heutefeiertag
touch $datei;
today=$(date --date="0 days ago " +"%-d-%-m-%Y");
if echo "$today"|grep -q ^24-12; then return 0; fi;
if echo "$today"|grep -q ^31-12; then return 0; fi;
# if echo "$today"|grep -q ^06-01; then return 0; fi;
# if echo "$today"|grep -q ^01-11; then return 0; fi;
json_return=$(curl -s https://www.kayaposoft.com/enrico/json/v2.0/?action=isPublicHoliday\&date=$today\&country=ger\&region=by )
if echo "$json_return"|grep -q true; then return 0; fi;
rm -f $datei;
return 1;
}

pruefe;
