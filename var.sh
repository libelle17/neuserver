#!/bin/bash
blau="\e[1;34m";
reset="\e[0m";
credentials="libelle17:bach17raga"
FB="fritz.box:49000"

# > /dev/null 2>&1

controlURL=/upnp/control/x_voip
serviceType=urn:dslforum-org:service:X_VoIP:1
Action=X_AVM-DE_DialNumber
Pin=NewX_AVM-DE_PhoneNumber
Rufnummer=616380;

controlURL=/igdupnp/control/WANCommonIFC1
serviceType=urn:schemas-upnp-org:service:WANCommonInterfaceConfig:1
Action=GetCommonLinkProperties
Pin=

controlURL=/upnp/control/x_contact
serviceType=urn:dslforum-org:service:X_AVM-DE_OnTel:1
Action=GetCallList
Pin=

controlURL=/upnp/control/x_storage
serviceType=urn:dslforum-org:service:X_AVM-DE_Storage:1
Action=GetInfo
Pin=

controlURL=/upnp/control/x_filelinks
serviceType=urn:dslforum-org:service:X_AVM-DE_Filelinks:1
Action=GetFilelinkListPath
Pin=

XML='<?xml version="1.0" encoding="utf-8" ?>
<s:Envelope s:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/" xmlns:s="http://schemas.xmlsoap.org/soap/envelope/">
  <s:Body>\n  <u:'$Action' xmlns:u="'$serviceType'"'
[ -n "$Pin" ]&&XML=$XML'><'$Pin'>'${Rufnummer}'</'$Pin'></u:'$Action'>'||XML=$XML' />'
XML=$XML'\n </s:Body>\n</s:Envelope>'
	printf "$blau$XML$reset\n"
 
curl -4 -k --anyauth -u "${credentials}"                                   \
  "http://${FB}$controlURL"                                     \
  -H 'Content-Type: text/xml; charset="utf-8"'                           \
  -H 'SoapAction: '$serviceType'#'$Action \
  -d "$XML"
echo ""
#netcat -4 fritz.box 1012

