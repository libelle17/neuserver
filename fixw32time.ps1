# fixw32time.ps1 - Windows-Zeitgeber (w32time) auf zuverlaessigen
# Automatikbetrieb umstellen.
#
# Hintergrund: Auf Workgroup-PCs (keine AD-Domaene) steht w32time
# standardmaessig auf Demand-Start ohne brauchbaren Trigger - er laeuft
# dann fast nie und die Uhr driftet frei auf der CMOS-Uhr. Manche PCs
# hatten zusaetzlich den Konfigurationstyp "NoSync", der jede Abfrage
# eines Zeitservers von vornherein unterbindet, unabhaengig vom
# Dienststatus.
#
# Als Administrator ausfuehren.

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Error "Bitte als Administrator ausfuehren."
    exit 1
}

$type = (w32tm /query /configuration | Select-String "^Type:")
if ($type -match "NoSync") {
    w32tm /config /manualpeerlist:"time.windows.com,0x9 time.nist.gov,0x9" /syncfromflags:manual /reliable:yes /update
}

sc.exe config w32time start= delayed-auto | Out-Null
Restart-Service w32time
Start-Sleep -Seconds 2
w32tm /resync /rediscover
Start-Sleep -Seconds 2

w32tm /query /status
