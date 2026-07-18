#!/bin/bash
# tr64.sh - fragt per TR-064-Login (Challenge/Response mit MD5, Zugangsdaten
# aus ~/.fbcredentials) die Fritzbox-Systemmeldungen (syslog.lua, Tab "aus")
# ab und gibt sie tabulatorgetrennt aus (Spalten aus dem Lua-Array-Format
# der Fritzbox-Antwort herausgeparst). Der "if false"-Zweig ist eine
# ältere, nicht mehr verwendete Login-Variante (login.lua statt
# login_sid.lua) und bleibt inaktiv. Aufruf ohne Parameter.
_BOXURL="http://fritz.box"
. ~/.fbcredentials
_USERNAME="$username";
_PASSWORD="$password";

if false; then
_REQUESTPAGE="/fon_num/foncalls_list.lua"
_OUTPUTFILE="output.html"
_CHALLENGE=$(curl -s ${_BOXURL}/login.lua | grep "^g_challenge" | awk -F '"' '{ print $2 }')
_MD5=$(echo -n ${_CHALLENGE}"-"${_PASSWORD} | iconv -f ISO8859-1 -t UTF-16LE | md5sum -b | awk '{print substr($0,1,32)}')
_RESPONSE="${_CHALLENGE}-${_MD5}"
_SID=$(curl -i -s -k -d 'response='${_RESPONSE} -d 'page=' -d "username=${_USERNAME}" "${_BOXURL}/login.lua" | grep "Location:" | grep -Poi 'sid=[a-f\d]+' | cut -d '=' -f2)
curl -s "${_BOXURL}${_REQUESTPAGE}" -d "sid=${_SID}" >$_OUTPUTFILE
else
_CHALLENGE=$(curl -s "${_BOXURL}/login_sid.lua?username=${_USERNAME}" | grep -Po '(?<=<Challenge>).*(?=</Challenge>)')
_MD5=$(echo -n ${_CHALLENGE}"-"${_PASSWORD} | iconv -f ISO8859-1 -t UTF-16LE | md5sum -b | awk '{print substr($0,1,32)}')
_RESPONSE="${_CHALLENGE}-${_MD5}"
_SID=$(curl -i -s -k -d "response=${_RESPONSE}&username=${_USERNAME}" "${_BOXURL}" | grep -Po -m 1 '(?<=sid=)[a-f\d]+')
echo $_SID >output.html
fi
PAGE_SYSLOG=$(curl -s "${_BOXURL}/system/syslog.lua" -d 'tab=aus' -d 'sid='${_SID})
_RAW_LOGS=$(echo "$_PAGE_SYSLOG" | tail -n $(expr $(echo "$_PAGE_SYSLOG" | wc -l) - $(echo "$_PAGE_SYSLOG" | grep -n '<code>' | grep -oP '^\d+')) | head -n -5)
_SYSLOG=$(echo "$_RAW_LOGS" | awk 'match($0, /\[1\] = \"(.*)\"\,/, arr){line = arr[1]};match($0, /\[2\] = \"(.*)\"\,/, arr){line = line"\t"arr[1]};match($0, /\[3\] = \"(.*)\"\,/, arr){print line"\t"arr[1];line = ""};')
echo "$_SYSLOG"
