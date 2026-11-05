<#
.SYNOPSIS
    Sucht auf USB-Sticks nach definierten Unterverzeichnissen und synchronisiert
    diese mit einer lokalen Platte (Volume "DATneu"), wenn alle Schutzdateien identisch sind.

.NOTES
    Korrekturen vom 18.09.2026 (uebernommen aus morueck9.ps1, das dasselbe auf
    dem zweiten PC mit dem Volume "NVMe-Daten" macht):

    1. SHA256 wird pur in .NET gebildet statt mit Get-FileHash, und ein
       fehlgeschlagener Hash-Vergleich fuehrt zu "nicht kopieren". Vorher galt
       bei einem Ausfall von Get-FileHash ($null -eq $null) alles als
       "identisch", der Inhaltsvergleich fiel also still weg und es blieb nur
       Groesse + Datum. (Get-FileHash steckt im Modul
       Microsoft.PowerShell.Utility, dessen Autoload scheitern kann.)
    2. Die Marker-Datei wird von robocopy ausgeschlossen (/xf). Vorher wurde sie
       als normale Datei aus dem Quellverzeichnis mitkopiert, gleich am Anfang
       des Lauf. Ein Abbruch mitten im Kopieren (Strom weg, Stick abgezogen)
       liess das halbfertige Ziel danach als "aktuell" gelten - es waere nie
       vollstaendig geworden.
    3. Die Marker-Datei auf dem Stick wird nicht mehr veraendert; gesetzt wird
       nur noch der Marker im Ziel, mit dem Zeitstempel der Quelle. Die Sticks
       werden inzwischen von zwei PCs zurueckgesichert. Schreibt dieser PC den
       Stick-Zeitstempel neu, haelt der andere seine fertige Kopie fuer veraltet
       und laeuft alles noch einmal durch. Der Zeitstempel auf dem Stick kommt
       allein von mokopr.ps1 aus der Praxis.
    4. Der Marker wird nur nach erfolgreichem robocopy gesetzt (Exit-Code < 8).
       Vorher wurde er auch nach einem Fehler geschrieben, der fehlgeschlagene
       Lauf galt damit als erledigt und wurde nie wiederholt. Ausserdem liefert
       das Skript jetzt einen eigenen Exit-Code (0 = sauber, 1 = Probleme) statt
       den Exit-Code des letzten robocopy durchzulassen.

    Ergaenzung vom 10.10.2026: medoffDB-Varianten und Altbestaende unter
    indamed\dat\files kommen nicht mehr auf den Stick (mokopr.ps1). Diese
    Verzeichnisse sind hier per /xd ($NichtSpiegeln) ausgenommen, damit /mir
    die Kopien im Ziel nicht loescht. mo7z wird ohnehin nur ergaenzt (/e).
    Alte mo7z-Archive loescht morueck9.ps1 auf linux9 vom Stick - deshalb
    muss dieses Skript auf hss VOR morueck9.ps1 laufen.

    Nebenbei: Get-CimInstance statt Get-WmiObject - HSS laeuft mit PowerShell 7,
    dort ist Get-WmiObject nur noch eine Proxy-Funktion, die im Hintergrund eine
    Windows-PowerShell-5.1-Sitzung startet und die Objekte serialisiert
    durchreicht. Die beiden ungenutzten Varianten Get-USB-Laufwerke-Alt und
    Get-USB-Laufwerke-2 sind entfallen.
#>

# PSModulePath bereinigen: wird dieses Skript von Windows PowerShell 5.1 aus
# einer PowerShell-7-Umgebung heraus gestartet (geerbte Umgebungsvariable), so
# versucht die 5.1-Engine PS7-Module zu laden. Das Laden von
# Microsoft.PowerShell.Utility scheitert dann mit einem Typdaten-Konflikt
# ("Das Element 'AuditToString' ist bereits vorhanden") und Cmdlets wie
# Get-FileHash fehlen anschliessend still. Darum die PS7-Pfade entfernen.
if ($PSVersionTable.PSEdition -eq 'Desktop' -and $env:PSModulePath) {
    $env:PSModulePath = (($env:PSModulePath -split ';' | Where-Object {
        $_ -and $_ -notmatch '\\PowerShell\\7' -and $_ -notmatch '\\Program Files\\PowerShell'
    }) -join ';')
}

# Zaehler fuer den Exit-Code (0 = sauber, 1 = Probleme)
$script:Fehleranzahl = 0

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

# Verzeichnisse, die mokopr.ps1 nicht (mehr) auf den Stick kopiert bzw. dort
# loescht, um Platz zu sparen. Hier per /XD ausgenommen, damit /mir die schon
# vorhandenen Kopien im Ziel nicht loescht. Namen mit Platzhaltern, gelten
# fuer Verzeichnisse dieses Namens irgendwo unterhalb des Suchverzeichnisses.
$NichtSpiegeln = @{
    "indamed" = @("*medoffDB*", "x01641915300_*")
}

# Volume-Name der lokalen Zielplatte
$ZielVolumeName = "DATneu"

# Name des Quellverzeichnisses fuer die 7z-Sicherung und festes Zielverzeichnis dafuer
$Mo7zVerzeichnis = "mo7z"
$Mo7zZiel        = "m:\mozip\"

# --- Hilfsfunktion: Laufwerksbuchstabe anhand Volume-Name ermitteln ---
function Get-LaufwerkNachVolume {
    param([string]$VolumeName)
    $laufwerk = Get-CimInstance Win32_LogicalDisk | Where-Object {
        $_.VolumeName -eq $VolumeName
    }
    if ($laufwerk) {
        return @($laufwerk)[0].DeviceID  # z.B. "M:"
    }
    return $null
}

# --- Hilfsfunktion: USB-Laufwerke ermitteln ---
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

# --- Hilfsfunktion: SHA256 einer Datei, ohne Get-FileHash (siehe .NOTES Punkt 1) ---
function Get-DateiHash {
    param([string]$Pfad)
    $sha = [System.Security.Cryptography.SHA256]::Create()
    $strom = [System.IO.File]::Open($Pfad, [System.IO.FileMode]::Open,
                                    [System.IO.FileAccess]::Read,
                                    [System.IO.FileShare]::ReadWrite)
    try {
        return [BitConverter]::ToString($sha.ComputeHash($strom)).Replace("-","")
    } finally {
        $strom.Dispose()
        $sha.Dispose()
    }
}

# --- Hilfsfunktion: Zwei Dateien inhaltlich vergleichen ---
#     Im Zweifel $false: laesst sich ein Hash nicht bilden, wird nicht kopiert.
function Vergleiche-DateiInhalt {
    param(
        [string]$Pfad1,
        [string]$Pfad2
    )
    try {
        $hash1 = Get-DateiHash -Pfad $Pfad1
        $hash2 = Get-DateiHash -Pfad $Pfad2
    } catch {
        Write-Warning "  Hash konnte nicht gebildet werden: $($_.Exception.Message)"
        return $false
    }
    if (-not $hash1 -or -not $hash2) {
        Write-Warning "  Hash leer - Vergleich nicht moeglich, es wird nicht kopiert."
        return $false
    }
    return ($hash1 -eq $hash2)
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

				# Robocopy und anschließendes Setzen der Ziel-Marker-Datei
				if ($robocopyAusfuehren) {
					# /xf $MarkerDatei: die Marker-Datei darf nicht mitkopiert
					# werden (siehe .NOTES Punkt 2). Geprueft: /xf schuetzt die
					# Datei im Ziel auch vor dem Aufraeumen durch /mir.
					$XdArgs = @()
					if ($NichtSpiegeln[$Verzeichnis]) { $XdArgs = @("/xd") + $NichtSpiegeln[$Verzeichnis] }
					$RobocopyCmd = "robocopy `"$QuellVerz\`" `"$ZielVerz`" /s /mir /r:3 /w:3 /xf $MarkerDatei $($XdArgs -join ' ')"
					Write-Host "  Befehl: $RobocopyCmd" -ForegroundColor DarkGray

					# Robocopy ausführen
					& robocopy "$QuellVerz\" "$ZielVerz" /s /mir /r:3 /w:3 /xf $MarkerDatei @XdArgs
					# Robocopy Exit-Codes: 0-7 = OK/Info, 8+ = Fehler
					if ($LASTEXITCODE -lt 8) {
						Write-Host "  Robocopy erfolgreich (Exit-Code: $LASTEXITCODE)" -ForegroundColor Green

						# Nur den Marker im ZIEL setzen, mit dem Zeitstempel der
						# Quelle - der Stick bleibt unangetastet (.NOTES Punkt 3).
						$Zeitstempel = (Get-Item $QuelleMarker).LastWriteTime
						[System.IO.File]::WriteAllBytes($ZielMarker, @())
						(Get-Item $ZielMarker).LastWriteTime = $Zeitstempel

						Write-Host "Ziel-Marker $ZielMarker gesetzt auf Zeitstempel der Quelle: $Zeitstempel"
					} else {
						# Kein Marker nach einem Fehler, sonst gilt der
						# fehlgeschlagene Lauf als erledigt (.NOTES Punkt 4).
						Write-Warning "  Robocopy meldet Fehler (Exit-Code: $LASTEXITCODE)"
						Write-Warning "  Marker nicht gesetzt - beim nächsten Lauf wird erneut kopiert."
						$script:Fehleranzahl++
					}
				}

            } else {
                Write-Host "  Schutzdateien stimmen NICHT überein - Kopieren wird übersprungen." -ForegroundColor Red
                $script:Fehleranzahl++
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
                    # /xf $MarkerDatei und Marker nur bei Erfolg - siehe oben
                    # uebertragen-linux9.txt: Quittung von morueck9.ps1, gehoert nicht ins Ziel
                    $RobocopyMo7zCmd = "robocopy `"$Mo7zQuellVerz`" `"$Mo7zZiel`" /e /r:3 /w:3 /xf $MarkerDatei uebertragen-linux9.txt"
                    Write-Host "  Befehl: $RobocopyMo7zCmd" -ForegroundColor DarkGray

                    & robocopy "$Mo7zQuellVerz" "$Mo7zZiel" /e /r:3 /w:3 /xf $MarkerDatei uebertragen-linux9.txt
                    # Robocopy Exit-Codes: 0-7 = OK/Info, 8+ = Fehler
                    if ($LASTEXITCODE -lt 8) {
                        Write-Host "  Robocopy (mo7z) erfolgreich (Exit-Code: $LASTEXITCODE)" -ForegroundColor Green

                        # Nur der Marker im ZIEL, Zeitstempel aus der Quelle
                        $Mo7zZeitstempel = (Get-Item $Mo7zQuelleMarker).LastWriteTime
                        [System.IO.File]::WriteAllBytes($Mo7zZielMarker, @())
                        (Get-Item $Mo7zZielMarker).LastWriteTime = $Mo7zZeitstempel

                        Write-Host "  Ziel-Marker (mo7z) gesetzt auf Zeitstempel der Quelle: $Mo7zZeitstempel"
                    } else {
                        Write-Warning "  Robocopy (mo7z) meldet Fehler (Exit-Code: $LASTEXITCODE)"
                        Write-Warning "  Marker nicht gesetzt - beim nächsten Lauf wird erneut kopiert."
                        $script:Fehleranzahl++
                    }
                }
            }

        } else {
            Write-Host "  Schutzdateien (mo7z) stimmen NICHT überein - Kopieren wird übersprungen." -ForegroundColor Red
            $script:Fehleranzahl++
        }

    } else {
        Write-Host "  Verzeichnis nicht vorhanden: $Mo7zQuellVerz" -ForegroundColor DarkGray
    }

    Write-Host ""
}

if ($script:Fehleranzahl -eq 0) {
    Write-Host "=== USB-Synchronisation abgeschlossen (keine Probleme) ===" -ForegroundColor Cyan
} else {
    Write-Host "=== USB-Synchronisation abgeschlossen, $script:Fehleranzahl Problem(e) - siehe Meldungen oben ===" -ForegroundColor Yellow
}

Stop-Transcript
# Eigener Exit-Code, damit der Task Scheduler nicht den Exit-Code des letzten
# robocopy sieht (robocopy liefert z.B. 1 = "Dateien kopiert", kein Fehler).
exit ([int]($script:Fehleranzahl -gt 0))
