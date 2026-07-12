<#
.SYNOPSIS
    Ersatz fuer spiegele.bat: spiegelt d:\indamed\ nach h:\indamed\ und
    c:\users\sturm\ nach e:\users\sturm\ - aber nur, wenn die Schutzdateien
    (Ransomware-Fruehwarnung) auf Quelle und Ziel inhaltlich uebereinstimmen.

.NOTES
    Laeuft auf Windows Server 2019 mit Windows PowerShell 5.1 (nicht PowerShell 7!).
    Bewusst KEINE PS7-Syntax verwendet: kein Ternary-Operator (?:), kein
    Null-Coalescing (?? / ??=), kein Pipeline-Chaining (&&/||), kein
    ForEach-Object -Parallel.
#>

# Protokoll mitschreiben: Task Scheduler zeigt nur, ob powershell.exe selbst
# abgestuerzt ist, nicht ob der Schutzdatei-Vergleich intern bestanden hat oder
# das Kopieren uebersprungen wurde (Write-Host landet bei einer nicht-interaktiv
# gestarteten Aufgabe sonst nirgends). Datei liegt neben dem Skript, waechst mit
# jedem Lauf (-Append).
$LogDatei = Join-Path $PSScriptRoot "spiegele-log.txt"

# Einfache Log-Rotation (Windows kennt kein eingebautes logrotate): wird die
# Log-Datei zu gross, vor dem naechsten Start umbenennen (mit Zeitstempel
# archivieren) und alte Archive jenseits von $LogAufbewahrenTage loeschen.
$LogMaxBytes = 5MB
$LogAufbewahrenTage = 30
if ((Test-Path $LogDatei) -and (Get-Item $LogDatei).Length -gt $LogMaxBytes) {
    $ArchivName = $LogDatei -replace '\.txt$', ("-{0}.txt" -f (Get-Date -Format "yyyyMMddHHmmss"))
    Rename-Item -Path $LogDatei -NewName (Split-Path $ArchivName -Leaf)
}
Get-ChildItem -Path $PSScriptRoot -Filter "spiegele-log-*.txt" -ErrorAction SilentlyContinue |
    Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-$LogAufbewahrenTage) } |
    Remove-Item -Force -ErrorAction SilentlyContinue

Start-Transcript -Path $LogDatei -Append

# Namen der Schutzdateien (muessen alle uebereinstimmen, bevor gespiegelt wird)
$SchutzdateiListe = @("Schutzdatei_bitte_belassen.doc","Auch_eine_Schutzdatei_bitte_belassen.jpg","zusätzliche_Schutzdatei_bitte_belassen.pdf")

# --- Hilfsfunktion: zwei Dateien inhaltlich vergleichen (SHA-256) ---
function Vergleiche-DateiInhalt {
    param(
        [string]$Pfad1,
        [string]$Pfad2
    )
    $hash1 = Get-FileHash -Path $Pfad1 -Algorithm SHA256
    $hash2 = Get-FileHash -Path $Pfad2 -Algorithm SHA256
    return ($hash1.Hash -eq $hash2.Hash)
}

# --- Hilfsfunktion: eine Schutzdatei auf Groesse, Datum und Inhalt pruefen ---
function Pruefe-Schutzdatei {
    param(
        [string]$QuellPfad,
        [string]$ZielPfad
    )
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

    # Groesse vergleichen
    if ($quelle.Length -ne $ziel.Length) {
        Write-Host "  Schutzdatei: Groesse unterschiedlich ($($quelle.Length) vs $($ziel.Length) Bytes)" -ForegroundColor Yellow
        return $false
    }

    # Letztes Aenderungsdatum vergleichen (auf Sekunden genau)
    $quelleDatum = $quelle.LastWriteTime.ToString("yyyy-MM-dd HH:mm:ss")
    $zielDatum   = $ziel.LastWriteTime.ToString("yyyy-MM-dd HH:mm:ss")
    if ($quelleDatum -ne $zielDatum) {
        Write-Host "  Schutzdatei: Aenderungsdatum unterschiedlich ($quelleDatum vs $zielDatum)" -ForegroundColor Yellow
        return $false
    }

    # Inhalt (Hash) vergleichen
    if (-not (Vergleiche-DateiInhalt -Pfad1 $QuellPfad -Pfad2 $ZielPfad)) {
        Write-Host "  Schutzdatei: Inhalt unterschiedlich (Hash-Vergleich)" -ForegroundColor Yellow
        return $false
    }

    return $true
}

# --- Hilfsfunktion: ALLE Schutzdateien aus $SchutzdateiListe zwischen zwei
#     Verzeichnissen pruefen; liefert erst $true, wenn jede einzelne
#     uebereinstimmt (Fail-Fast: bricht bei der ersten Abweichung ab) ---
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

# --- Hilfsfunktion: ein Verzeichnis spiegeln, wenn die Schutzdateien passen ---
function Spiegele-Verzeichnis {
    param(
        [string]$QuellVerz,
        [string]$ZielVerz
    )
    Write-Host "--- Pruefe $QuellVerz -> $ZielVerz ---" -ForegroundColor Cyan

    if (-not (Test-Path $QuellVerz)) {
        Write-Warning "Quellverzeichnis nicht gefunden: $QuellVerz - uebersprungen."
        return
    }
    if (-not (Test-Path $ZielVerz)) {
        Write-Warning "Zielverzeichnis nicht gefunden: $ZielVerz - uebersprungen."
        return
    }

    if (Pruefe-Schutzdateien -QuellVerz $QuellVerz -ZielVerz $ZielVerz) {
        Write-Host "Schutzdateien identisch - starte Robocopy ..." -ForegroundColor Green
        # kein /mir (wie im Original spiegele.bat): auf dem Ziel geloeschte bzw.
        # nicht mehr vorhandene Quelldateien werden NICHT geloescht - falls doch
        # einmal eine Verschluesselung durchrutscht, bleibt so die letzte gute
        # Zielkopie zumindest von aktiver Loeschung verschont.
        robocopy "$QuellVerz\" "$ZielVerz\" /copy:dat /s
        if ($LASTEXITCODE -lt 8) {
            Write-Host "Robocopy erfolgreich (Exit-Code: $LASTEXITCODE)" -ForegroundColor Green
        } else {
            Write-Warning "Robocopy meldet Fehler (Exit-Code: $LASTEXITCODE)"
        }
    } else {
        Write-Host "Schutzdateien stimmen NICHT ueberein - Spiegelung wird uebersprungen (moeglicher Ransomware-Verdacht)." -ForegroundColor Red
    }
    Write-Host ""
}

# =============================================================================
# HAUPTPROGRAMM (entspricht den zwei robocopy-Zeilen aus spiegele.bat)
# =============================================================================

Write-Host "=== Spiegelung gestartet ===" -ForegroundColor Cyan
Write-Host ""

Spiegele-Verzeichnis -QuellVerz "d:\indamed" -ZielVerz "h:\indamed"
Spiegele-Verzeichnis -QuellVerz "c:\users\sturm" -ZielVerz "e:\users\sturm"

Write-Host "=== Spiegelung abgeschlossen ===" -ForegroundColor Cyan

Stop-Transcript
