<#
.SYNOPSIS
    Sucht auf USB-Sticks nach definierten Unterverzeichnissen und synchronisiert
    diese mit einer lokalen Platte (Volume "DATneu"), wenn alle Schutzdateien identisch sind.
#>

# Protokoll mitschreiben (Task Scheduler zeigt nur, ob powershell.exe selbst
# abgestuerzt ist, nicht was das Skript intern entschieden hat). Log-Rotation von
# Hand, da Windows kein eingebautes logrotate kennt: ab 5 MB wird die alte Datei
# mit Zeitstempel archiviert, Archive aelter als 30 Tage werden geloescht.
$LogDatei = Join-Path $PSScriptRoot "morueck-log.txt"
$LogMaxBytes = 5MB
$LogAufbewahrenTage = 30
if ((Test-Path $LogDatei) -and (Get-Item $LogDatei).Length -gt $LogMaxBytes) {
    $ArchivName = $LogDatei -replace '\.txt$', ("-{0}.txt" -f (Get-Date -Format "yyyyMMddHHmmss"))
    Rename-Item -Path $LogDatei -NewName (Split-Path $ArchivName -Leaf)
}
Get-ChildItem -Path $PSScriptRoot -Filter "morueck-log-*.txt" -ErrorAction SilentlyContinue |
    Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-$LogAufbewahrenTage) } |
    Remove-Item -Force -ErrorAction SilentlyContinue
Start-Transcript -Path $LogDatei -Append

# Zielverzeichnisse, die gesucht werden sollen
$SuchVerzeichnisse = @("datenbanken", "dok", "indamed", "eingelesen")

# Namen der Schutzdateien (muessen alle uebereinstimmen, bevor kopiert wird)
$SchutzdateiListe = @("Schutzdatei_bitte_belassen.doc","Auch_eine_Schutzdatei_bitte_belassen.jpg","zusätzliche_Schutzdatei_bitte_belassen.pdf")

# Name der Marker-Datei (zeigt letzten erfolgreichen Kopiervorgang an)
$MarkerDatei = "gesichert"

# Volume-Name der lokalen Zielplatte
$ZielVolumeName = "DATneu"

# Name des Quellverzeichnisses fuer die 7z-Sicherung und festes Zielverzeichnis dafuer
$Mo7zVerzeichnis = "mo7z"
$Mo7zZiel        = "m:\mozip\"

# --- Hilfsfunktion: Laufwerksbuchstabe anhand Volume-Name ermitteln ---
function Get-LaufwerkNachVolume {
    param([string]$VolumeName)
    $laufwerk = Get-WmiObject Win32_LogicalDisk | Where-Object {
        $_.VolumeName -eq $VolumeName
    }
    if ($laufwerk) {
        return $laufwerk.DeviceID  # z.B. "M:"
    }
    return $null
}

# --- Hilfsfunktion: USB-Laufwerke ermitteln ---
function Get-USB-Laufwerke-Alt {
    # DriveType 2 = Wechseldatenträger
    $usbLaufwerke = Get-WmiObject Win32_LogicalDisk | Where-Object {
        $_.DriveType -eq 2
    }
    return $usbLaufwerke | Select-Object -ExpandProperty DeviceID
}

function Get-USB-Laufwerke-2 {
    $usbLaufwerke = @()

    # Alle physischen Datenträger mit USB-Interface ermitteln
    $usbDisks = Get-WmiObject Win32_DiskDrive # | Where-Object {        $_.InterfaceType -eq "USB"    }

    foreach ($disk in $usbDisks) {
		write-host $disk
        # Zugehörige Partitionen finden
        $partitionen = Get-WmiObject -Query "ASSOCIATORS OF {Win32_DiskDrive.DeviceID='$($disk.DeviceID -replace '\\','\\')'}
            WHERE AssocClass=Win32_DiskDriveToDiskPartition"
        write-host ( $partitionen -eq $null )
        foreach ($partition in $partitionen) {
            # Zugehörige logische Laufwerke (Buchstaben) finden
            $logischeLaufwerke = Get-WmiObject -Query "ASSOCIATORS OF {Win32_DiskPartition.DeviceID='$($partition.DeviceID)'}
                WHERE AssocClass=Win32_LogicalDiskToPartition"

            foreach ($laufwerk in $logischeLaufwerke) {
                $usbLaufwerke += $laufwerk.DeviceID
            }
        }
    }

    return $usbLaufwerke
}

function Get-USB-Laufwerke {
    $usbLaufwerke = @()

    # Alle physischen Datenträger mit USB-Bus ermitteln
    $usbDisks = Get-Disk | Where-Object { $_.BusType -eq "USB" }

    foreach ($disk in $usbDisks) {
        # Partitionen und zugehörige Laufwerksbuchstaben ermitteln
        $buchstaben = $disk | Get-Partition | 
                      Where-Object { $_.DriveLetter } |
                      Select-Object -ExpandProperty DriveLetter

        foreach ($buchstabe in $buchstaben) {
            $usbLaufwerke += "${buchstabe}:"
        }
    }

    return $usbLaufwerke
}

# --- Hilfsfunktion: Zwei Dateien inhaltlich vergleichen ---
function Vergleiche-DateiInhalt {
    param(
        [string]$Pfad1,
        [string]$Pfad2
    )
    $hash1 = Get-FileHash -Path $Pfad1 -Algorithm SHA256
    $hash2 = Get-FileHash -Path $Pfad2 -Algorithm SHA256
    return ($hash1.Hash -eq $hash2.Hash)
}

# --- Hilfsfunktion: Schutzdatei auf Größe, Datum und Inhalt prüfen ---
function Pruefe-Schutzdatei {
    param(
        [string]$QuellPfad,
        [string]$ZielPfad
    )
    Write-Host "  Prüfe Schutzdatei..."

    if (-not (Test-Path $QuellPfad)) {
        Write-Warning "  Schutzdatei nicht gefunden (Quelle): $QuellPfad"
        return $false
    }
    if (-not (Test-Path $ZielPfad)) {
        Write-Warning "  Schutzdatei nicht gefunden (Ziel): $ZielPfad"
        return $false
    }

    $quelle = Get-Item $QuellPfad
    $ziel   = Get-Item $ZielPfad

    # Größe vergleichen
    if ($quelle.Length -ne $ziel.Length) {
        Write-Host "  Schutzdatei: Größe unterschiedlich ($($quelle.Length) vs $($ziel.Length) Bytes)" -ForegroundColor Yellow
        return $false
    }

    # Letztes Änderungsdatum vergleichen (auf Sekunden genau)
    $quelleDatum = $quelle.LastWriteTime.ToString("yyyy-MM-dd HH:mm:ss")
    $zielDatum   = $ziel.LastWriteTime.ToString("yyyy-MM-dd HH:mm:ss")
    if ($quelleDatum -ne $zielDatum) {
        Write-Host "  Schutzdatei: Änderungsdatum unterschiedlich ($quelleDatum vs $zielDatum)" -ForegroundColor Yellow
        return $false
    }

    # Inhalt (Hash) vergleichen
    if (-not (Vergleiche-DateiInhalt -Pfad1 $QuellPfad -Pfad2 $ZielPfad)) {
        Write-Host "  Schutzdatei: Inhalt unterschiedlich (Hash-Vergleich)" -ForegroundColor Yellow
        return $false
    }
    write-host "Schutzdateien $Quellpfad und $zielpfad identisch, darf kopieren ... " -ForegroundColor Green
    return $true
}

# --- Hilfsfunktion: ALLE Dateien aus $SchutzdateiListe zwischen zwei Verzeichnissen
#     pruefen; liefert erst $true, wenn jede einzelne uebereinstimmt (Fail-Fast) ---
function Pruefe-Schutzdateien {
    param(
        [string]$QuellVerz,
        [string]$ZielVerz
    )
    foreach ($name in $SchutzdateiListe) {
        $QuellPfad = Join-Path $QuellVerz $name
        $ZielPfad  = Join-Path $ZielVerz  $name
        if (-not (Pruefe-Schutzdatei -QuellPfad $QuellPfad -ZielPfad $ZielPfad)) {
            return $false
        }
    }
    return $true
}

# =============================================================================
# HAUPTPROGRAMM
# =============================================================================

Write-Host "=== USB-Synchronisation gestartet ===" -ForegroundColor Cyan
Write-Host ""

# Ziellaufwerk (DATneu) ermitteln
$ZielLaufwerk = Get-LaufwerkNachVolume -VolumeName $ZielVolumeName
if (-not $ZielLaufwerk) {
    Write-Error "Lokales Ziellaufwerk mit Volume-Name '$ZielVolumeName' nicht gefunden. Abbruch."
    exit 1
}
Write-Host "Ziellaufwerk gefunden: $ZielLaufwerk ($ZielVolumeName)" -ForegroundColor Green

# USB-Laufwerke ermitteln
$USBLaufwerke = Get-USB-Laufwerke
if (-not $USBLaufwerke) {
    Write-Host "Keine USB-Laufwerke gefunden." -ForegroundColor Yellow
    exit 0
}

Write-Host "Gefundene USB-Laufwerke: $($USBLaufwerke -join ', ')" -ForegroundColor Green
Write-Host ""

# Jeden USB-Stick durchsuchen
foreach ($USB in $USBLaufwerke) {

    # Sicherstellen, dass Ziellaufwerk ≠ USB-Laufwerk
    if ($USB -eq $ZielLaufwerk) {
        Write-Host "[$USB] Übersprungen (ist das Ziellaufwerk)."
        continue
    }

    Write-Host "--- Durchsuche USB-Laufwerk: $USB ---" -ForegroundColor Cyan

    foreach ($Verzeichnis in $SuchVerzeichnisse) {

        $QuellVerz = "$USB\$Verzeichnis"
        $ZielVerz  = "$ZielLaufwerk\$Verzeichnis"

        if (Test-Path $QuellVerz) {
            Write-Host "  Verzeichnis gefunden: $QuellVerz" -ForegroundColor Green

            if (Pruefe-Schutzdateien -QuellVerz $QuellVerz -ZielVerz $ZielVerz) {

				# Pfade zur Marker-Datei
				$QuelleMarker = Join-Path $QuellVerz $MarkerDatei
				$ZielMarker   = Join-Path $ZielVerz  $MarkerDatei

				# Prüfen ob Robocopy ausgeführt werden soll
				$robocopyAusfuehren = $false

				if (-not (Test-Path $QuelleMarker)) {
					Write-Host "Marker-Datei im Quellverzeichnis " $QuellVerz " nicht gefunden. Abbruch."
					continue
				}

				if (-not (Test-Path $ZielMarker)) {
					Write-Host "Keine Marker-Datei im Zielverzeichnis $Zielverz gefunden – erster Lauf, Kopie wird durchgeführt."
					$robocopyAusfuehren = $true
				} else {
					$QuelleZeit = (Get-Item $QuelleMarker).LastWriteTime
					$ZielZeit   = (Get-Item $ZielMarker).LastWriteTime

					if ($QuelleZeit -gt $ZielZeit) {
						Write-Host "Quelle ($QuelleZeit) ist neuer als Ziel ($ZielZeit) – Kopie wird durchgeführt."
						$robocopyAusfuehren = $true
					} else {
						Write-Host "Ziel ist aktuell ($ZielZeit) – kein Kopiervorgang nötig."
					}
				}

				# Robocopy und anschließendes Aktualisieren der Marker-Dateien
				if ($robocopyAusfuehren) {
					$RobocopyCmd = "robocopy `"$QuellVerz\`" `"$ZielVerz`" /s /mir /r:3 /w:3"
					Write-Host "  Befehl: $RobocopyCmd" -ForegroundColor DarkGray

					# Robocopy ausführen
					& robocopy "$QuellVerz\" "$ZielVerz" /s /mir /r:3 /w:3
					# Robocopy Exit-Codes: 0-7 = OK/Info, 8+ = Fehler
					if ($LASTEXITCODE -lt 8) {
						Write-Host "  Robocopy erfolgreich (Exit-Code: $LASTEXITCODE)" -ForegroundColor Green
					} else {
						Write-Warning "  Robocopy meldet Fehler (Exit-Code: $LASTEXITCODE)"
					}

					# Gemeinsamen Zeitstempel festlegen
					$Zeitstempel = Get-Date

					# Marker-Datei im Quellverzeichnis aktualisieren (0 Bytes)
					[System.IO.File]::WriteAllBytes($QuelleMarker, @())
					(Get-Item $QuelleMarker).LastWriteTime = $Zeitstempel

					# Marker-Datei im Zielverzeichnis aktualisieren (0 Bytes)
					[System.IO.File]::WriteAllBytes($ZielMarker, @())
					(Get-Item $ZielMarker).LastWriteTime = $Zeitstempel

					Write-Host "Marker-Dateien aktualisiert mit Zeitstempel: $Zeitstempel"
				}

            } else {
                Write-Host "  Schutzdateien stimmen NICHT überein - Kopieren wird übersprungen." -ForegroundColor Red
            }

        } else {
            Write-Host "  Verzeichnis nicht vorhanden: $QuellVerz" -ForegroundColor DarkGray
        }
    }
    # --- mo7z-Verzeichnis: bei übereinstimmenden Schutzdateien alle Dateien nach m:\mozip\ kopieren ---
    $Mo7zQuellVerz = Join-Path $USB $Mo7zVerzeichnis

    if (Test-Path $Mo7zQuellVerz) {
        Write-Host "  Verzeichnis gefunden: $Mo7zQuellVerz" -ForegroundColor Green

        if (Pruefe-Schutzdateien -QuellVerz $Mo7zQuellVerz -ZielVerz $Mo7zZiel) {

            # Pfade zur Marker-Datei
            $Mo7zQuelleMarker = Join-Path $Mo7zQuellVerz $MarkerDatei
            $Mo7zZielMarker   = Join-Path $Mo7zZiel       $MarkerDatei

            # Prüfen ob Robocopy ausgeführt werden soll
            $Mo7zRobocopyAusfuehren = $false

            if (-not (Test-Path $Mo7zQuelleMarker)) {
                Write-Host "  Marker-Datei im Quellverzeichnis $Mo7zQuellVerz nicht gefunden. Abbruch."
            } else {
                if (-not (Test-Path $Mo7zZielMarker)) {
                    Write-Host "  Keine Marker-Datei im Zielverzeichnis $Mo7zZiel gefunden – erster Lauf, Kopie wird durchgeführt."
                    $Mo7zRobocopyAusfuehren = $true
                } else {
                    $Mo7zQuelleZeit = (Get-Item $Mo7zQuelleMarker).LastWriteTime
                    $Mo7zZielZeit   = (Get-Item $Mo7zZielMarker).LastWriteTime

                    if ($Mo7zQuelleZeit -gt $Mo7zZielZeit) {
                        Write-Host "  Quelle ($Mo7zQuelleZeit) ist neuer als Ziel ($Mo7zZielZeit) – Kopie wird durchgeführt."
                        $Mo7zRobocopyAusfuehren = $true
                    } else {
                        Write-Host "  Ziel ist aktuell ($Mo7zZielZeit) – kein Kopiervorgang nötig."
                    }
                }

                if ($Mo7zRobocopyAusfuehren) {
                    $RobocopyMo7zCmd = "robocopy `"$Mo7zQuellVerz`" `"$Mo7zZiel`" /e /r:3 /w:3"
                    Write-Host "  Befehl: $RobocopyMo7zCmd" -ForegroundColor DarkGray

                    & robocopy "$Mo7zQuellVerz" "$Mo7zZiel" /e /r:3 /w:3
                    # Robocopy Exit-Codes: 0-7 = OK/Info, 8+ = Fehler
                    if ($LASTEXITCODE -lt 8) {
                        Write-Host "  Robocopy (mo7z) erfolgreich (Exit-Code: $LASTEXITCODE)" -ForegroundColor Green
                    } else {
                        Write-Warning "  Robocopy (mo7z) meldet Fehler (Exit-Code: $LASTEXITCODE)"
                    }

                    # Gemeinsamen Zeitstempel festlegen
                    $Mo7zZeitstempel = Get-Date

                    # Marker-Datei im Quellverzeichnis aktualisieren (0 Bytes)
                    [System.IO.File]::WriteAllBytes($Mo7zQuelleMarker, @())
                    (Get-Item $Mo7zQuelleMarker).LastWriteTime = $Mo7zZeitstempel

                    # Marker-Datei im Zielverzeichnis aktualisieren (0 Bytes)
                    [System.IO.File]::WriteAllBytes($Mo7zZielMarker, @())
                    (Get-Item $Mo7zZielMarker).LastWriteTime = $Mo7zZeitstempel

                    Write-Host "  Marker-Dateien (mo7z) aktualisiert mit Zeitstempel: $Mo7zZeitstempel"
                }
            }

        } else {
            Write-Host "  Schutzdateien (mo7z) stimmen NICHT überein - Kopieren wird übersprungen." -ForegroundColor Red
        }

    } else {
        Write-Host "  Verzeichnis nicht vorhanden: $Mo7zQuellVerz" -ForegroundColor DarkGray
    }

    Write-Host ""
}

Write-Host "=== USB-Synchronisation abgeschlossen ===" -ForegroundColor Cyan

Stop-Transcript