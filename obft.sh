#!/bin/bash
today=$(date --date="0 days ago " +"%-d-%-m-%Y");
if echo "$today"|grep -q ^24-12; then exit 0; fi;
if echo "$today"|grep -q ^30-12; then exit 0; fi;
if echo "$today"|grep -q ^31-12; then exit 0; fi;
json_return=$(curl -s http://www.kayaposoft.com/enrico/json/v1.0/?action=isPublicHoliday\&date=$today\&country=ger )
if echo "$json_return"|grep -q true; then exit 0; fi;
exit 1;
