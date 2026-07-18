# Update-HeidiSQLPassword.ps1
#
# Liest das neue MariaDB-Passwort fuer den Benutzer 'praxis' von stdin (eine Zeile,
# ohne Echo/Log) und schreibt es obfuskiert in alle lokalen HeidiSQL-Sessions dieses
# Windows-Benutzers, deren "User" auf 'praxis' steht. Wird per SSH aus
# setmariadbpwdfuerpraxis.sh (Server linux1) aufgerufen -- das Passwort landet dabei
# nie auf der Platte, nur im Speicher dieses Prozesses.
#
# Aufruf (vom Server aus):
#   printf '%s\n' "$NEUPWD" | ssh <konto>@<pc> powershell -NoProfile -ExecutionPolicy Bypass -File \\linux1\daten\down\Update-HeidiSQLPassword.ps1
#
# Format der HeidiSQL-Passwort-Obfuskierung (kein echtes Verschluesseln, seit Jahren
# stabil, s. HeidiSQL-Quelltext helpers.pas / encrypt()/decrypt()): pro Zeichen wird
# (Ord(Zeichen) + Salt) als 2-stelliges Hex angehaengt, am Ende steht die Salt-Ziffer
# (1-9) als Klartextziffer -- HeidiSQL erkennt daran beim Lesen "ANSI-Modus". Eine
# Endziffer '0' wuerde HeidiSQL als Unicode-Variante (4 Hex-Stellen/Zeichen) deuten,
# daher bleibt Salt immer 1-9 und Zeichen mit Ord > 246 werden abgelehnt (sonst
# wuerde Ord+Salt > 255 ergeben und dabei mehr als 2 Hex-Stellen liefern).

$ErrorActionPreference = 'Stop'

$neupwd = [Console]::In.ReadLine()
if ([string]::IsNullOrEmpty($neupwd)) {
	Write-Output "kein Passwort erhalten -- abgebrochen."
	exit 1
}
if ($neupwd.ToCharArray() | Where-Object { [int][char]$_ -gt 246 }) {
	Write-Output "Passwort enthaelt ein Zeichen ausserhalb des unterstuetzten Bereichs -- abgebrochen."
	exit 1
}

function ConvertTo-HeidiSQLPassword([string]$klartext) {
	$salt = Get-Random -Minimum 1 -Maximum 10
	$hex = -join ($klartext.ToCharArray() | ForEach-Object { '{0:X2}' -f ([int][char]$_ + $salt) })
	return "$hex$salt"
}

$verschluesselt = ConvertTo-HeidiSQLPassword $neupwd
$aktualisiert = 0

foreach ($basis in 'HKCU:\Software\HeidiSQL\Sessions', 'HKCU:\Software\HeidiSQL\Servers') {
	if (-not (Test-Path $basis)) { continue }
	Get-ChildItem $basis -Recurse | ForEach-Object {
		$benutzer = (Get-ItemProperty -Path $_.PSPath -Name User -ErrorAction SilentlyContinue).User
		if ($benutzer -eq 'praxis') {
			Set-ItemProperty -Path $_.PSPath -Name Password -Value $verschluesselt
			$aktualisiert++
		}
	}
}

Write-Output "$($env:USERNAME)@$($env:COMPUTERNAME): $aktualisiert HeidiSQL-Session(s) aktualisiert."
