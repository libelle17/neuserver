#Requires -Version 5.1
<#
.SYNOPSIS
    Verschiebt aeltere Backup-Dateien (20*.7z) aus dem Sicherungsverzeichnis in ein Loeschverzeichnis.
.DESCRIPTION
    Wie StutzMOSich.ps1, jedoch wird das massgebliche Datum NICHT aus LastWriteTime,
    sondern aus den ersten 14 Zeichen des Dateinamens gewonnen (Muster: yyyymmddHHMMSS*.7z).
    Dateien, deren Name nicht mit einem gueltigen 14-stelligen Zeitstempel beginnt,
    werden uebersprungen (mit Warnung).

    Aufbewahrungsregeln:
      - Juenger als $Gr2 Tage                    => immer behalten
      - $Gr2 bis $Gr1 Tage alt                   => nur Dateien behalten, deren Tag in $Beh2 vorkommt
      - $Gr1 bis $Gr0 Tage alt                   => nur die 1. Datei des Monats behalten
      - Aelter als $Gr0 Tage                     => nur die 1. Datei des Jahres (Januar) behalten
      - Dateinamen, die mit einem Eintrag in $Ausspar beginnen => immer behalten

.PARAMETER Verbose
    Gibt ausfuehrliche Ausgaben aus.
.EXAMPLE
    .\StutzMOSich_NamensDatum.ps1 -Verbose
#>

[CmdletBinding()]
param()

# ============================================================
# VORGABEN  (hier anpassen)
# ============================================================

# Quellverzeichnis mit den Backup-Dateien
$Vz  = 'H:\mo7z'

# Zielverzeichnis fuer Dateien, die geloescht werden sollen
$Zvz = 'H:\mo7z\loe'

# weiteres Sicherungsverzeichnis
$wSvz = 'D:\mozip'

# Dateinamenmuster der zu pruefenden Dateien
$Muster = '20*.7z'

# Grenze in Tagen: aelter als $Gr0 => nur 1 Datei pro Jahr behalten
$Gr0 = 1095

# Monat, dessen Dateien pro Jahr behalten werden (als Zahl, 1 = Januar)
$Beh0 = 1

# Grenze in Tagen: aelter als $Gr1 => nur 1 Datei pro Monat behalten
$Gr1 = 180

# Tag im Monat, dessen Datei pro Monat behalten wird (als Zahl, 1 = Erster)
$Beh1 = 1

# Grenze in Tagen: aelter als $Gr2 => nur bestimmte Tage pro Monat behalten
$Gr2 = 30

# Tage im Monat, die pro Woche behalten werden (kommagetrennte Liste)
$Beh2 = @(1, 8, 15, 22)

# Dateinamen-Praefix-Liste: Dateien, deren Name mit einem dieser Eintraege beginnt, IMMER behalten.
# Leer lassen @() um nichts auszusparen.
$Ausspar = @('loe', 'files')

# Grenze in MB: wird auf dem Laufwerk von $Vz weniger freier Platz als dieser Wert
# festgestellt, wird das Loeschverzeichnis $Zvz komplett geleert.
$MinFreiMB = 100

# ============================================================
# HILFSFUNKTIONEN
# ============================================================

function Write-Log {
    param([string]$Msg, [string]$Color = 'Cyan')
    if ($VerbosePreference -ne 'SilentlyContinue') {
        Write-Host $Msg -ForegroundColor $Color
    }
}

function Get-DateDiffDays {
    param([datetime]$FileDate)
    return [int][Math]::Floor(( (Get-Date) - $FileDate ).TotalDays)
}

# Leert $Pfad vollstaendig, wenn auf dem Laufwerk von $Pfad weniger als
# $MinFreiMB Megabyte frei sind.
function Clear-LoeschverzeichnisBeiWenigPlatz {
    param(
        [string]$Pfad,
        [int]$MinFreiMB
    )
    $Laufwerksbuchstabe = (Split-Path -Path $Pfad -Qualifier).TrimEnd(':')
    $Laufwerk = Get-PSDrive -Name $Laufwerksbuchstabe -ErrorAction SilentlyContinue
    if (-not $Laufwerk) {
        Write-Warning "Laufwerk '${Laufwerksbuchstabe}:' konnte nicht ermittelt werden => Platzpruefung uebersprungen."
        return
    }

    $FreiMB = [Math]::Round($Laufwerk.Free / 1MB, 1)
    Write-Log "Freier Speicherplatz auf ${Laufwerksbuchstabe}: $FreiMB MB" 'Cyan'

    if ($FreiMB -ge $MinFreiMB) {
        return
    }

    Write-Log "Weniger als $MinFreiMB MB frei auf ${Laufwerksbuchstabe}: => leere '$Pfad'" 'Red'
    Get-ChildItem -Path $Pfad -Force | Remove-Item -Recurse -Force
}

# ### GEAENDERT gegenueber StutzMOSich.ps1 ###
# Liest die ersten 14 Zeichen des Dateinamens als "yyyyMMddHHmmss" und
# liefert ein [datetime]-Objekt zurueck, oder $null bei ungueltigem Format.
function Get-DateFromFilename {
    param([string]$Filename)
    if ($Filename -notmatch '^\d{14}') {
        return $null
    }
    $stamp = $Filename.Substring(0, 14)   # z.B. "20250312012217"
    try {
        return [datetime]::ParseExact(
            $stamp,
            'yyyyMMddHHmmss',
            [System.Globalization.CultureInfo]::InvariantCulture
        )
    } catch {
        return $null
    }
}

# ### GEAENDERT gegenueber StutzMOSich.ps1 ###
# Vergleicht Dateien anhand ihres Namens-Datums statt LastWriteTime.
# Liefert die erste (aelteste) Datei im Pruefzeitraum vor $FileDate, oder $null.
function Find-OlderFileInPeriod {
    param(
        [datetime]$PeriodStart,   # Beginn des Pruefzeitraums (1. des Monats / 1. Januar)
        [datetime]$FileDate       # Namens-Datum der aktuell geprueften Datei
    )
    $candidate = Get-ChildItem -Path $Vz -Filter $Muster -File |
        ForEach-Object {
            $d = Get-DateFromFilename $_.Name
            if ($null -ne $d) {
                [PSCustomObject]@{ File = $_; NamensDatum = $d }
            }
        } |
        Where-Object {
            $_.NamensDatum -ge $PeriodStart -and
            $_.NamensDatum -lt  $FileDate
        } |
        Sort-Object NamensDatum |
        Select-Object -First 1
    return $candidate
}

# ============================================================
# HAUPTPROGRAMM
# ============================================================

# Zielverzeichnis anlegen, falls nicht vorhanden
if (-not (Test-Path $Zvz)) {
    New-Item -ItemType Directory -Path $Zvz | Out-Null
    Write-Log "Verzeichnis erstellt: $Zvz" 'Green'
}

# Abbruch, wenn Zielverzeichnis immer noch nicht existiert
if (-not (Test-Path $Zvz)) {
    Write-Error "Zielverzeichnis '$Zvz' konnte nicht erstellt werden. Abbruch."
    exit 1
}

if (test-path $wSvz) {
	robocopy "$vz" "$wsvz" *.7z /copy:dat /np
}

# ### GEAENDERT gegenueber StutzMOSich.ps1 ###
# Dateien werden nach ihrem Namens-Datum sortiert, nicht nach LastWriteTime.
$Dateien = Get-ChildItem -Path $Vz -Filter $Muster -File |
    ForEach-Object {
        $d = Get-DateFromFilename $_.Name
        if ($null -ne $d) {
            [PSCustomObject]@{ File = $_; NamensDatum = $d }
        } else {
            Write-Warning "Datei '$($_.Name)' beginnt nicht mit einem gueltigen 14-stelligen Zeitstempel => wird uebersprungen."
        }
    } |
    Where-Object { $null -ne $_ } |
    Sort-Object NamensDatum

if (-not $Dateien) {
    Write-Log "Keine auswertbaren Dateien mit Muster '$Muster' in '$Vz' gefunden." 'Yellow'
    exit 0
}

Write-Log "Gefunden: $($Dateien.Count) Datei(en) mit Muster '$Muster' in '$Vz'" 'Cyan'

foreach ($Eintrag in $Dateien) {

    $Datei    = $Eintrag.File
    $Name     = $Datei.Name
    # ### GEAENDERT: Datum kommt aus dem Dateinamen, nicht aus LastWriteTime ###
    $FileDate = $Eintrag.NamensDatum
    $DiffDays = Get-DateDiffDays -FileDate $FileDate

    $Jahr     = $FileDate.Year
    $Monat    = $FileDate.Month
    $Tag      = $FileDate.Day

    Write-Log "`n--- $Name  (Alter: $DiffDays Tage, Namens-Datum: $($FileDate.ToString('yyyy-MM-dd HH:mm:ss')))" 'White'

    # --- Ausspar-Pruefung ---------------------------------
    $AusgespartUND = $false
    foreach ($prae in $Ausspar) {
        if ($Name -like "$prae*") {
            Write-Log "  Ausgespart (Praefix '$prae') => behalten" 'Green'
            $AusgespartUND = $true
            break
        }
    }
    if ($AusgespartUND) { continue }

    # --- Regelpruefung  (Runde 0 = jaehrlich, 1 = monatlich, 2 = woechentlich) ---
    $Verschoben = $false

    foreach ($Runde in 0, 1, 2) {

        switch ($Runde) {
            0 {
                $Grenze      = $Gr0
                $BehWert     = $Beh0          # Monatszahl, die behalten wird
                $Vergleich   = $Monat         # Monat der Datei
                $PeriodStart = [datetime]"$Jahr-01-01"
                $RundeName   = 'jaehrlich'
            }
            1 {
                $Grenze      = $Gr1
                $BehWert     = $Beh1          # Tageszahl, die behalten wird
                $Vergleich   = $Tag
                $PeriodStart = [datetime]"$Jahr-$Monat-01"
                $RundeName   = 'monatlich'
            }
            2 {
                $Grenze      = $Gr2
                $BehWert     = $Beh2          # Array von Tageszahlen
                $Vergleich   = $Tag
                $PeriodStart = [datetime]"$Jahr-$Monat-01"
                $RundeName   = 'woechentlich'
            }
        }

        # Datei juenger als Grenze => fuer diese Runde nicht relevant
        if ($DiffDays -le $Grenze) {
            Write-Log "  Runde $Runde ($RundeName): Alter $DiffDays <= $Grenze Tage => Runde ueberspringen" 'DarkGray'
            continue
        }

        # Pruefen, ob der Datumswert (Tag oder Monat) zum Behalten-Kriterium passt
        $IstBehaltetag = if ($Runde -eq 2) {
            $BehWert -contains $Vergleich
        } else {
            $Vergleich -eq $BehWert
        }

        if ($IstBehaltetag) {
            Write-Log "  Runde $Runde ($RundeName): Datumswert $Vergleich stimmt => behalten" 'Green'
            continue
        }

        # Datumswert stimmt NICHT => gibt es eine aeltere Datei im gleichen Zeitraum?
        Write-Log "  Runde $Runde ($RundeName): Datumswert $Vergleich passt nicht; suche aeltere Datei ab $($PeriodStart.ToString('yyyy-MM-dd'))..." 'Yellow'

        $AeltereEintrag = Find-OlderFileInPeriod -PeriodStart $PeriodStart -FileDate $FileDate

        if ($AeltereEintrag) {
            Write-Log "  => Aeltere Datei gefunden: $($AeltereEintrag.File.Name) => verschiebe '$Name' nach '$Zvz'" 'Red'
            Move-Item -Path $Datei.FullName -Destination $Zvz -Force
            $Verschoben = $true
            break   # nicht weiter pruefen
        } else {
            Write-Log "  => Keine aeltere Datei im Zeitraum gefunden => behalten (Lueckenfuellung)" 'Green'
        }
    }

    if (-not $Verschoben) {
        Write-Log "  Ergebnis: behalten" 'Green'
    }
}

Clear-LoeschverzeichnisBeiWenigPlatz -Pfad $Zvz -MinFreiMB $MinFreiMB

Write-Log "`nFertig: $($MyInvocation.MyCommand.Path)" 'Cyan'
