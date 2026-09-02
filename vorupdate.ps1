<#
    vorupdate.ps1

    Vor einem medical office / indamed Versionsupdate:
      1. Loescht alle bis auf die zwei juengsten Sicherungsordner "indamed<yyyymmdd>" / "Indamed<yyyymmdd>" in D:\.
      2. Erstellt eine neue Sicherung von D:\indamed nach D:\indamed<heutiges Datum>, unter Auslassung
         einzelner grosser Unterordner/Dateien (siehe $ExcludeDirs / $ExcludeFilePatterns unten).

    Aufruf:
      .\vorupdate.ps1              -> normaler Lauf, fragt vor dem Loeschen nach
      .\vorupdate.ps1 -Force       -> loescht ohne Rueckfrage (z.B. fuer automatisierten Aufruf)
      .\vorupdate.ps1 -DryRun      -> zeigt nur an, was passieren wuerde (nichts wird geloescht/kopiert)
#>

[CmdletBinding()]
param(
    [switch]$Force,
    [switch]$DryRun
)

$ErrorActionPreference = 'Stop'

# --- Konfiguration -----------------------------------------------------

$ParentDir  = 'D:\'
$SourceRoot = Join-Path $ParentDir 'indamed'
$KeepCount  = 2

# Unterordner, die bei der neuen Sicherung komplett ausgelassen werden (volle Pfade unter $SourceRoot).
$ExcludeDirs = @(
    (Join-Path $SourceRoot 'dat\files')
    (Join-Path $SourceRoot 'dat\medoffDBKop')
    (Join-Path $SourceRoot 'gehtso')
)

# Datei-Muster, die bei der neuen Sicherung ausgelassen werden.
# Hinweis: robocopy /XF akzeptiert nur Dateinamen/Wildcards, keine vollen Pfade - das Muster gilt daher
# ueberall im kopierten Baum. Alle Muster unten sind spezifisch genug (medical office / indamed
# Dump-/Backup-Dateien), um Kollisionen ausserhalb ihrer eigentlichen Ordner praktisch auszuschliessen.
$ExcludeFilePatterns = @(
    'moupd*.exe'
    'medoffdump*.sql'
    'medoffDB.7z'
)

# --- Vorbereitung --------------------------------------------------------

if (-not (Test-Path -LiteralPath $SourceRoot -PathType Container)) {
    throw "Quellordner '$SourceRoot' wurde nicht gefunden."
}

# Zielordner fuer die heutige Sicherung schon jetzt bestimmen: Wurde das Skript heute bereits
# (erfolgreich oder abgebrochen) gestartet, existiert dieser Ordner bereits. In dem Fall soll er
# weder bei der Zaehlung der zu behaltenden/loeschenden Sicherungsordner mitgerechnet noch geloescht
# werden - stattdessen wird die laufende Sicherung unten per robocopy fortgesetzt/aktualisiert.
$today          = Get-Date -Format 'yyyyMMdd'
$newBackupName  = "indamed$today"
$newBackupPath  = Join-Path $ParentDir $newBackupName
$resumingToday  = Test-Path -LiteralPath $newBackupPath

function Get-CopySizeBytes {
    param(
        [string]$Root,
        [string[]]$ExcludeDirs,
        [string[]]$ExcludeFilePatterns
    )
    $total = 0L
    Get-ChildItem -LiteralPath $Root -Recurse -File -Force -ErrorAction SilentlyContinue |
        ForEach-Object {
            $full = $_.FullName
            $skip = $false
            foreach ($d in $ExcludeDirs) {
                if ($full.Equals($d, [System.StringComparison]::OrdinalIgnoreCase) -or
                    $full.StartsWith("$d\", [System.StringComparison]::OrdinalIgnoreCase)) {
                    $skip = $true
                    break
                }
            }
            if (-not $skip) {
                foreach ($pat in $ExcludeFilePatterns) {
                    if ($_.Name -like $pat) { $skip = $true; break }
                }
            }
            if (-not $skip) { $total += $_.Length }
        }
    return $total
}

function Get-FolderSizeBytes {
    param([string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) { return 0L }
    $sum = (Get-ChildItem -LiteralPath $Path -Recurse -File -Force -ErrorAction SilentlyContinue |
        Measure-Object -Property Length -Sum).Sum
    if (-not $sum) { return 0L }
    return $sum
}

function Get-BackupFolders {
    Get-ChildItem -LiteralPath $ParentDir -Directory |
        Where-Object { $_.Name -match '^[Ii]ndamed(\d{8})$' } |
        ForEach-Object {
            $null = $_.Name -match '^[Ii]ndamed(\d{8})$'
            [pscustomobject]@{
                Item = $_
                Date = [datetime]::ParseExact($Matches[1], 'yyyyMMdd', $null)
            }
        } |
        Sort-Object Date -Descending
}

$backups = @(Get-BackupFolders | Where-Object {
    -not $_.Item.FullName.Equals($newBackupPath, [System.StringComparison]::OrdinalIgnoreCase)
})

if ($resumingToday) {
    Write-Host "Hinweis: '$newBackupName' existiert bereits (Skript wurde heute schon gestartet)."
    Write-Host "Dieser Ordner wird bei der folgenden Zaehlung nicht mitgerechnet und unten per robocopy aktualisiert."
    Write-Host ""
}

Write-Host "Gefundene Sicherungsordner (neueste zuerst, ohne heutigen Ordner):"
$backups | ForEach-Object { Write-Host ("  {0}  ({1:yyyy-MM-dd})" -f $_.Item.Name, $_.Date) }

$toDelete = @($backups | Select-Object -Skip $KeepCount)
$toKeep   = @($backups | Select-Object -First $KeepCount)

Write-Host ""
Write-Host "Werden behalten (letzte $KeepCount):"
$toKeep | ForEach-Object { Write-Host "  $($_.Item.Name)" }

Write-Host ""
if ($toDelete.Count -eq 0) {
    Write-Host "Nichts zu loeschen (es gibt hoechstens $KeepCount Sicherungsordner)."
}
else {
    Write-Host "Werden geloescht:"
    $toDelete | ForEach-Object { Write-Host "  $($_.Item.FullName)" }

    if ($DryRun) {
        Write-Host ""
        Write-Host "[DryRun] Es wird nichts geloescht."
    }
    else {
        if (-not $Force) {
            $answer = Read-Host "`nDiese Ordner jetzt endgueltig loeschen? (ja/nein)"
            if ($answer -notin @('ja', 'j', 'y', 'yes')) {
                Write-Host "Abgebrochen. Es wurde nichts geloescht oder kopiert."
                exit 1
            }
        }
        foreach ($b in $toDelete) {
            Write-Host "Loesche $($b.Item.FullName) ..."
            Remove-Item -LiteralPath $b.Item.FullName -Recurse -Force
        }
        Write-Host "Alte Sicherungsordner geloescht."
    }
}

# --- Neue Sicherung erstellen --------------------------------------------

Write-Host ""
if ($resumingToday) {
    Write-Host "Setze heutige Sicherung fort/aktualisiere sie: $SourceRoot -> $newBackupPath"
}
else {
    Write-Host "Erstelle neue Sicherung: $SourceRoot -> $newBackupPath"
}
Write-Host "Ausgeschlossene Ordner:"
$ExcludeDirs | ForEach-Object { Write-Host "  $_" }
Write-Host "Ausgeschlossene Dateimuster:"
$ExcludeFilePatterns | ForEach-Object { Write-Host "  $_" }

$logFile = Join-Path $ParentDir "vorupdate_robocopy_$today.log"

$robocopyArgs = @(
    $SourceRoot
    $newBackupPath
    '/E'                # inkl. Unterordner (auch leere)
    '/COPY:DAT'          # Data, Attribute, Timestamps
    '/DCOPY:DAT'         # dito fuer Ordner
    '/R:2'               # 2 Wiederholungen bei gesperrten Dateien
    '/W:5'               # 5 Sek. Wartezeit zwischen Wiederholungen
    '/MT:8'              # 8 Threads
    '/J'                 # ungepuffertes I/O, besser fuer sehr grosse Dateien
    '/XD'; $ExcludeDirs
    '/XF'; $ExcludeFilePatterns
    '/NP'                # keine Fortschritts-Prozentanzeige (bessere Log-Lesbarkeit)
    "/LOG:$logFile"
    '/TEE'               # Ausgabe zusaetzlich auf der Konsole
)

if ($resumingToday) {
    # Heutiger Ordner existiert schon (Skript wurde heute schon einmal gestartet): mit /PURGE
    # werden im Ziel auch Dateien/Ordner entfernt, die im Quellbaum nicht mehr vorhanden sind -
    # das robocopy-Aequivalent zu "rsync --delete" unter Linux.
    $robocopyArgs += '/PURGE'
    Write-Host "Heutiger Sicherungsordner existiert bereits -> robocopy laeuft mit /PURGE (loescht im Ziel, was in der Quelle fehlt)."
}

if ($DryRun) {
    $robocopyArgs += '/L'   # nur auflisten, nichts kopieren
    Write-Host "[DryRun] robocopy laeuft im Listen-Modus (/L), es wird nichts kopiert."

    Write-Host ""
    Write-Host "Starte robocopy ..."
    & robocopy @robocopyArgs
    $rc = $LASTEXITCODE

    if ($rc -ge 8) {
        throw "robocopy meldet Fehler (Exitcode $rc). Details im Log: $logFile"
    }

    Write-Host ""
    Write-Host "[DryRun] Testlauf abgeschlossen (Exitcode $rc). Log: $logFile"
}
else {
    # Gesamtgroesse vorab ermitteln, um waehrend des Kopierens einen echten Fortschritt anzeigen zu koennen
    # (robocopy /MT liefert keine brauchbare Gesamt-Prozentanzeige ueber mehrere Threads hinweg).
    Write-Host ""
    Write-Host "Ermittle Gesamtgroesse der zu kopierenden Daten ..."
    $totalBytes = Get-CopySizeBytes -Root $SourceRoot -ExcludeDirs $ExcludeDirs -ExcludeFilePatterns $ExcludeFilePatterns
    Write-Host ("Zu kopieren: {0:N2} GB" -f ($totalBytes / 1GB))

    Write-Host ""
    Write-Host "Starte robocopy ..."
    $proc = Start-Process -FilePath 'robocopy' -ArgumentList $robocopyArgs -NoNewWindow -PassThru

    $pollSeconds = 20
    while (-not $proc.HasExited) {
        Start-Sleep -Seconds $pollSeconds
        if ($proc.HasExited) { break }
        $copied = Get-FolderSizeBytes -Path $newBackupPath
        $pct = 0
        if ($totalBytes -gt 0) { $pct = [math]::Min(100, [math]::Round(($copied / $totalBytes) * 100, 1)) }
        Write-Host ("Fortschritt: {0:N2} GB / {1:N2} GB ({2} %)" -f ($copied / 1GB), ($totalBytes / 1GB), $pct)
    }
    $proc.WaitForExit()
    $rc = $proc.ExitCode

    # Robocopy-Exitcodes 0-7 sind Erfolg (siehe robocopy /?), ab 8 ist ein Fehler aufgetreten.
    if ($rc -ge 8) {
        throw "robocopy meldet Fehler (Exitcode $rc). Details im Log: $logFile"
    }

    Write-Host ""
    Write-Host "==================================================================="
    Write-Host "FERTIG: Neue Sicherung erfolgreich erstellt: $newBackupPath"
    Write-Host "==================================================================="
    Write-Host "robocopy Exitcode: $rc   Log: $logFile"
}
