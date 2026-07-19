# mokopr.ps1 - "Medical Office kopieren": sucht einen angeschlossenen
# USB-Stick (per tukop()), vergleicht dort erst die Schutzdateien aus
# $VglListe (Ransomware-Fruehwarnung, wie bei spiegele.ps1/morueck.ps1)
# gegen das jeweilige Quellverzeichnis und robocopy't bei Uebereinstimmung
# p:\dok, p:\datenbanken, \\wser\indamed, p:\eingelesen sowie \\wser\mo7z
# auf den Stick (jeweils unter dessen Wurzel). Warnt zusaetzlich, wenn der
# erkannte USB-Anschluss langsamer als USB 3.2 Gen 2 ist, und fragt
# interaktiv nach, ob umgesteckt werden soll. Fuer \\wser\indamed wird nach
# dem Kopieren zusaetzlich tumedoff() aufgerufen: aktualisiert serverseitig
# per SSH ein 7z-Archiv von medoffDB und kopiert dieses auf den Stick.
# Aufruf: interaktiv oder per Task Scheduler, ohne Parameter.
#
# HINWEIS zum Code-Zustand: dieses Skript ist erkennbar unfertiger/
# experimenteller als spiegele.ps1/morueck.ps1 - es enthaelt Debug-
# Write-Host-Reste, eine ungenutzte Alternativimplementierung
# (Get-USB-Laufwerke_, s.u.) und - wichtig - nach dem "exit 0" auf Zeile
# ~365 folgen zwei weitere, komplett EIGENSTAENDIGE Skriptfragmente
# ("automatisches Backup und Cleanup" fuer mosich-7z-Archive, sowie ein
# "Sync-NewestBackup.ps1"-Fragment) als TOTER CODE - sie werden wegen des
# vorherigen "exit 0" nie erreicht und scheinen hier nur als Ablage/
# Kopiervorlage fuer aehnliche eigenstaendige Skripte zu dienen, nicht als
# Teil des tatsaechlichen Ablaufs dieser Datei.
#
# Protokoll mitschreiben (Task Scheduler zeigt nur, ob powershell.exe selbst
# abgestuerzt ist, nicht was das Skript intern entschieden hat). Log-Rotation von
# Hand, da Windows kein eingebautes logrotate kennt: ab 5 MB wird die alte Datei
# mit Zeitstempel archiviert, Archive aelter als 30 Tage werden geloescht.
$LogDatei = Join-Path $PSScriptRoot "mokopr-log.txt"
$LogMaxBytes = 5MB
$LogAufbewahrenTage = 30
if ((Test-Path $LogDatei) -and (Get-Item $LogDatei).Length -gt $LogMaxBytes) {
	$ArchivName = $LogDatei -replace '\.txt$', ("-{0}.txt" -f (Get-Date -Format "yyyyMMddHHmmss"))
	Rename-Item -Path $LogDatei -NewName (Split-Path $ArchivName -Leaf)
}
Get-ChildItem -Path $PSScriptRoot -Filter "mokopr-log-*.txt" -ErrorAction SilentlyContinue |
	Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-$LogAufbewahrenTage) } |
	Remove-Item -Force -ErrorAction SilentlyContinue
Start-Transcript -Path $LogDatei -Append

# 1) USB-Stick mit mindestens 1 TB und Unterverzeichnis \indamed suchen
# $minSize = 1000000000000
$minSize = 1000000000000
$minSize=10
$usbDrive = $null
$usbDeviceID = $null
$VglListe = @("Schutzdatei_bitte_belassen.doc","Auch_eine_Schutzdatei_bitte_belassen.jpg","zusätzliche_Schutzdatei_bitte_belassen.pdf") # muessen alle uebereinstimmen, bevor kopiert wird
$data="\\linux1\daten"
$v = if (Get-PSDrive -Name "V" -ErrorAction SilentlyContinue) { "V:" } else { "$data\down" }
$p = if (Get-PSDrive -Name "P" -ErrorAction SilentlyContinue) { "P:" } else { "$data\Patientendokumente" }

# USB-Version ermitteln
function Get-USBVersion {
    param ($logicalDeviceID)
    try {
        # Logical -> Partition -> Disk
#		write-host "logicalDeviceID", $logicalDeviceID # ,"logToPart",$logToPart
        $logToPart = Get-WmiObject -Query "ASSOCIATORS OF {Win32_LogicalDisk.DeviceID='$logicalDeviceID'} WHERE AssocClass=Win32_LogicalDiskToPartition" -ErrorAction Stop
        foreach ($partition in $logToPart) {
            $diskIndex = ($partition.DeviceID -replace '.*Disk #(\d+).*','$1')
            # Physischen Disk -> USB-Controller-Kette via PnP
            $diskDrive = Get-WmiObject -Query "SELECT * FROM Win32_DiskDrive WHERE Index=$diskIndex" -ErrorAction Stop
            $pnpID = $diskDrive.PNPDeviceID
            # USB-Hub/Controller suchen, der dieses Gerät enthält
            $usbDevices = Get-WmiObject -Namespace "root\cimv2" -Class Win32_PnPEntity | 
                          Where-Object { $_.PNPDeviceID -like "USB\*" -and $_.PNPDeviceID -ne $null }
            # USB-Controller-Typ über Treibernamen / Beschreibung ermitteln
            $controller = Get-WmiObject -Namespace "root\cimv2" -Class Win32_USBController -ErrorAction SilentlyContinue
            foreach ($ctrl in $controller) {
                $desc = $ctrl.Description + " " + $ctrl.Name
                if ($desc -match "USB 4|Thunderbolt") { return "USB 4 / Thunderbolt" }
                if ($desc -match "3\.2 Gen 2x2|20Gbps")  { return "USB 3.2 Gen 2x2 (20 Gbit/s)" }
                if ($desc -match "3\.2 Gen 2|10Gbps")     { return "USB 3.2 Gen 2 (10 Gbit/s)" }
                if ($desc -match "3\.2 Gen 1|3\.1 Gen 1|3\.0|xHCI") { return "USB 3.x (xHCI)" }
                if ($desc -match "2\.0|EHCI")              { return "USB 2.0 (EHCI)" }
                if ($desc -match "1\.1|OHCI|UHCI")         { return "USB 1.1" }
            }
        }
    } catch {
       "Fehler bei der USB-Auswahl"
    }
    return $null
}

<#
Get-Disk | Select-Object Number, FriendlyName, Path, SerialNumber, PartitionStyle, Size
Get-Disk|sort-object disknumber|Select-Object Number,FriendlyName,@{Name="DeviceID";Expression={"\\.\PHYSICALDRIVE"+$_.Number}},Size,PartitionStyle|Format-Table -AutoSize
Get-Disk | Where-Object { $_.BusType -eq "USB" }| sort-object disknumber|ForEach-Object {
    $disk = $_
    Get-Partition -DiskNumber $disk.Number | ForEach-Object {
        $partition = $_
        $volume = Get-Volume -Partition $partition -ErrorAction SilentlyContinue
        [PSCustomObject]@{
			DeviceID	= "\\.\PHYSICALDRIVE"+$disk.Number
            Disk        = $disk.Number
			USBVersion  = Get-USBVersion($partition.DriveLetter+":")
            DiskModel   = $disk.FriendlyName
            DiskSize_GB = [math]::Round($disk.Size / 1GB, 2)
            Partition   = $partition.PartitionNumber
            DriveLetter = $partition.DriveLetter
            Part_GB     = [math]::Round($partition.Size / 1GB, 2)
            FileSystem  = $volume.FileSystem
            Label       = $volume.FileSystemLabel
            FreeSpace_GB= [math]::Round($volume.SizeRemaining / 1GB, 2)
        }
    }
} | Format-Table -AutoSize
Get-WmiObject Win32_DiskDrive | ForEach-Object { $_ | Select-Object DeviceID, Model, Size }
Get-WmiObject Win32_LogicalDisk | Select-Object DeviceID, DriveType, FileSystem, Size, FreeSpace
exit
#>

function Write-Col ($color = "Green",$nl,$nT1,$cT1,$nT2,$cT2,$nT3,$cT3) {
    Write-Host $nT1 -NoNewline
    Write-Host $cT1 -ForegroundColor $color -NoNewline
    Write-Host $nT2 -NoNewline
    Write-Host $cT2 -ForegroundColor $color -NoNewline
    Write-Host $nT3 -NoNewline
    Write-Host $cT3 -ForegroundColor $color -NoNewline
    if ($nl) {Write-Host ""} # Neue Zeile am Ende
}


function Get-USB-Laufwerke {
	write-Host "Get-USB-Laufwerke:"
    $usbLaufwerke = @()
    # Alle physischen Datenträger mit USB-Bus ermitteln
if ($false) {	
    $usbDisks = Get-Disk | Where-Object { $_.BusType -eq "USB" }
} elseif ($true) {	
	$job = start-job { Get-Disk | Where-Object { $_.BusType -eq "USB" } }
	$usbDisks = $job | Wait-Job -Timeout 10 | Receive-Job
}	
	if ( $usbDisks -eq $null ) {
		write-host "Ersatzmethode"
		$usbDisks = Get-WmiObject -Class Win32_DiskDrive | Where-Object { $_.InterfaceType -eq "USB" }
		|ForEach-Object { Get-Disk -Number $_.Index }
	}
    foreach ($disk in $usbDisks) {
        # Partitionen und zugehörige Laufwerksbuchstaben ermitteln
        $buchstaben = $disk | Get-Partition| 
                      Where-Object { $_.DriveLetter } |
                      Select-Object -ExpandProperty DriveLetter
        foreach ($buchstabe in $buchstaben) {
		   write-host "Buchstabe: ",$buchstabe	
  		   $usbLaufwerke += @{Name=$buchstabe}
        }
    }
	write-Host "Ende Get-USB-Laufwerke"
    return $usbLaufwerke
}
function Get-USB-Laufwerke_ {
	write-Host "starte Get-USB-Laufwerke"
    $usbLaufwerke = @()
    # Alle physischen Datenträger mit USB-Bus ermitteln
	write-Host "vor write-host"
    $usbDisks = Get-Disk | Where-Object { $_.BusType -eq "USB" }
if ($false) {	
	$job = start-job { Get-Disk | Where-Object { $_.BusType -eq "USB" } }
	$usbDisks = $job | Wait-Job -Timeout 10 | Receive-Job
}	
	if ( $usbDisks -eq $null ) {
		write-host "Ersatzmethode"
		$usbDisks = Get-WmiObject -Class Win32_DiskDrive | Where-Object { $_.InterfaceType -eq "USB" }
	}
    foreach ($disk in $usbDisks) {
        # Partitionen und zugehörige Laufwerksbuchstaben ermitteln
        $buchstaben = $disk | Get-Partition | 
                      Where-Object { $_.DriveLetter } |
                      Select-Object -ExpandProperty DriveLetter
        foreach ($buchstabe in $buchstaben) {
  		   $usbLaufwerke += @{Name=$buchstabe}
        }
    }
    return $usbLaufwerke
}



# 2) Dateien vergleichen
# Vergleicht eine einzelne Datei zwischen Server und USB; gibt Objekt zurück oder $null bei Fehler (wird pro Datei aus $VglListe von Pruefe-Schutzdateien aufgerufen)
function tuvgl {
	param(
		[Parameter(Mandatory=$true)][string]$fileServer,
		[Parameter(Mandatory=$true)][string]$fileUSB
	)
	if (-not (Test-Path $fileServer)) {
		Write-Host "Serverdatei nicht gefunden: $fileServer" -ForegroundColor Red
		return $null
	}
	if (-not (Test-Path $fileUSB)) {
		Write-Host "USB-Datei nicht gefunden: $fileUSB - Ziel frisch, wird wie uebereinstimmend behandelt" -ForegroundColor Yellow
		return [PSCustomObject]@{
			sizeEqual    = $true
			dateEqual    = $true
			contentEqual = $true
		}
	}
	$infoServer = Get-Item $fileServer
	$infoUSB    = Get-Item $fileUSB
	$sizeEqual    = $infoServer.Length -eq $infoUSB.Length
	$dateEqual    = $infoServer.LastWriteTime -eq $infoUSB.LastWriteTime
	$contentEqual = (Get-FileHash $fileServer -Algorithm SHA256).Hash -eq (Get-FileHash $fileUSB -Algorithm SHA256).Hash
	Write-Col "Green" "1" "Vergleiche: " $fileServer " <-> " $fileUSB ":"
	Write-Host "Größe identisch:   $sizeEqual   (Server: $($infoServer.Length) Bytes, USB: $($infoUSB.Length) Bytes)"
	Write-Host "Datum identisch:   $dateEqual   (Server: $($infoServer.LastWriteTime.ToString("d.M.yy HH:mm:ss")), USB: $($infoUSB.LastWriteTime.ToString("d.M.yy HH:mm:ss")))"
	Write-Host "Inhalt identisch:  $contentEqual"
	return [PSCustomObject]@{
		sizeEqual    = $sizeEqual
		dateEqual    = $dateEqual
		contentEqual = $contentEqual
	}
} # tuvgl

# Prueft alle Dateien aus $VglListe zwischen zwei Verzeichnissen; liefert erst dann
# $true, wenn Groesse+Datum+Inhalt bei JEDER einzelnen Datei uebereinstimmen
# (Fail-Fast: bricht bei der ersten Abweichung/fehlenden Datei sofort ab)
function Pruefe-Schutzdateien {
	param(
		[Parameter(Mandatory=$true)][string]$QuellVerz,
		[Parameter(Mandatory=$true)][string]$ZielVerz
	)
	foreach ($name in $VglListe) {
		$fileServer = Join-Path $QuellVerz $name
		$fileUSB    = Join-Path $ZielVerz  $name
		$vglErg = tuvgl -fileServer $fileServer -fileUSB $fileUSB
		if ($vglErg -eq $null) { return $false }
		if (-not ($vglErg.sizeEqual -and $vglErg.dateEqual -and $vglErg.contentEqual)) { return $false }
	}
	return $true
} # Pruefe-Schutzdateien

function tukop{
	param(
		[Parameter(Mandatory=$true)]
		[string]$qvz,
		[string]$zvz,
		[string[]]$avz = @()
	)
#	$drives = Get-PSDrive -PSProvider FileSystem | Where-Object { $_.Root -match '^[A-Z]:\\$' }
	write-col "green" "1" "Suche " "`"$qvz`"" " auf ..."
	$drives = Get-USB-Laufwerke
	
	$gef=$false
	foreach ($drive in $drives) {
		write-host "tukop, versuche USB-Laufwerk: ",$drive
		try {
			$usbDrive    = "$($drive.Name):"
			$disk = Get-WmiObject -Query "SELECT * FROM Win32_LogicalDisk WHERE DeviceID='$usbDrive'" -ErrorAction Stop
			$usbDeviceID = $disk.DeviceID
	#		$obusb=($disk.drivetype -in 2,3)
	#		write-host "   ", $disk.drivetype, $disk.size, $obusb
			if ($disk <# -and $disk.DriveType -in 2,3 #> -and $disk.Size -ge $minSize) {
				$jPath = Join-Path $usbDrive $zvz
#				$groe= "{0}: (DriveType {1}) mit {2:N0} Bytes -> `"{3}`" " -f $drive.name,$disk.DriveType,$disk.size,$jPath
#				write-host $groe -nonewline
				$groe = ": (DriveType {0}) mit {1:N0} Bytes -> `"" -f $disk.DriveType,$disk.size 
				write-col "green" "" "" $drive.name $groe $jPath "`" "
				if (Test-Path $jPath -PathType Container) {
					$gef = $true
					Write-Col "green" "1" "" "gefunden" # ": $usbDrive" ", Device-ID: " $usbDeviceID

					# Prüfen ob USB 3.1 Gen 2 oder schneller – falls nicht, Rückfrage
					$usbVersion = Get-USBVersion -logicalDeviceID $usbDeviceID
										
					$slowUSB = $false
					if ($usbVersion) {
						$fastPattern = "USB 4|Thunderbolt|3\.2 Gen 2|USB 3\.x \(xHCI\)"
						if ($usbVersion -notmatch $fastPattern) {
							$slowUSB = $true
						}
					} else {
						Write-Host "USB-Version konnte nicht ermittelt werden." -ForegroundColor Yellow
						$slowUSB = $true
					}
					if ($slowUSB) {
						$versionText = if ($usbVersion) { $usbVersion } else { "unbekannt" }
						Write-Host ""
						Write-Host "======================================================" -ForegroundColor Yellow
						Write-Host " HINWEIS: Der USB-Stick steckt in einem Anschluss mit:" -ForegroundColor Yellow
						Write-Host "          $versionText" -ForegroundColor Cyan
						Write-Host ""
						Write-Host " Für optimale Übertragungsgeschwindigkeit empfiehlt"    -ForegroundColor Yellow
						Write-Host " sich ein USB 3.2 Gen 2 (10 Gbit/s) oder schnellerer"  -ForegroundColor Yellow
						Write-Host " Anschluss."                                             -ForegroundColor Yellow
						Write-Host "======================================================" -ForegroundColor Yellow
						Write-Host ""
						$answer = Read-Host "Möchten Sie den Stick in einen schnelleren USB-Anschluss umstecken? (j/n)"
						if ($answer -match "^[jJyY]") {
							Write-Host "`nBitte Stick umstecken und Script neu starten." -ForegroundColor Cyan
							exit 0
						}
						Write-Host "`nFortfahren mit $versionText ..." -ForegroundColor Yellow
					}
					$alleSchutzdateienOK = Pruefe-Schutzdateien -QuellVerz $qvz -ZielVerz "$usbDrive$zvz"
					break
				} else {	
					write-host "nicht gefunden" -ForegroundColor Yellow
	#				continue
				}
	#			break # muss dann gelöscht werden
			}        
		} catch {
			continue
		}
	}	

	if (-not $gef) {
		$groe= "{0:N0}" -f $minSize
		Write-Host "Kein passender USB-Stick gefunden (mind. $groe Byte, Unterverzeichnis `"$usbDrive$zvz`")." -ForegroundColor Red
		return
	}



	# 3) Robocopy nur wenn alle Schutzdateien (Groesse+Datum+Inhalt) uebereinstimmen
	if ($alleSchutzdateienOK) {
		Write-Host " => Alle Kriterien erfüllt – starte Robocopy..." -ForegroundColor Green
		$xdArgs = @()
		foreach ($a in $avz) {
			$xdArgs += "/XD"
			$xdArgs += "$qvz\$a"
		}
		Write-host "robocopy `"$qvz\`" `"$usbDrive$zvz\`" /s /mir /MT:16 /w:3 /r:3 $($xdArgs -join ' ')"
		$script:tukopUsbDrive = $usbDrive
		robocopy "$qvz\" "$usbDrive$zvz\" /s /mir /MT:16 /w:3 /r:3 @xdArgs
					# Zeitstempel festlegen
					$Zeitstempel = Get-Date
					# Pfade zur Marker-Datei
					$MarkerDatei = "gesichert"
					$ZielMarker   = Join-Path $usbDrive$zvz  $MarkerDatei

					# Marker-Datei im Zielverzeichnis aktualisieren (0 Bytes)
					[System.IO.File]::WriteAllBytes($ZielMarker, @())
					(Get-Item $ZielMarker).LastWriteTime = $Zeitstempel

					Write-Host "Marker-Datei $ZielMarker aktualisiert mit Zeitstempel: $Zeitstempel"
		
	} else {
		Write-Host "`nSchutzdateien sind NICHT identisch – Robocopy wird nicht ausgeführt." -ForegroundColor Yellow
	}
} # tukop

# Serverseitige Vorbereitung für indamed-Backup:
# 1) Prüft Identität aller Schutzdateien aus $VglListe zwischen Server und USB (via Pruefe-Schutzdateien)
# 2) ssh: robocopy medoffDB -> medoffDBKop auf Server
# 3) ssh: 7z-Archiv medoffDB.7z auf Server erstellen/aktualisieren
# 4) robocopy: medoffDB.7z vom Server auf USB-Stick kopieren
function tumedoff {
	param(
		[Parameter(Mandatory=$true)][string]$usbDrive  # z.B. "E:"
	)
	Write-Host "tumedoff: Prüfe Voraussetzungen für indamed-Backup auf $usbDrive ..." -ForegroundColor Cyan

	# 1) Verzeichnis \\wser\indamed auf USB vorhanden?
	if (-not (Test-Path "$usbDrive\indamed" -PathType Container)) {
		Write-Host "  $usbDrive\indamed nicht gefunden – tumedoff übersprungen." -ForegroundColor Yellow
		return
	}

	# 2) Schutzdateien vergleichen
	if (-not (Pruefe-Schutzdateien -QuellVerz "\\wser\indamed" -ZielVerz "$usbDrive\indamed")) {
		Write-Host "  Vergleichsdateien nicht identisch – tumedoff wird nicht ausgeführt." -ForegroundColor Yellow
		return
	}
	Write-Host "  Vergleichsdateien identisch – starte serverseitige Vorbereitung ..." -ForegroundColor Green

	# 3) ssh: robocopy medoffDB -> medoffDBKop auf dem Server
	$sshRobo = 'robocopy d:\indamed\dat\medoffDB\ d:\indamed\dat\medoffDBKop\ /s /copy:dat'
	Write-Host "  ssh wser $sshRobo"
	ssh wser $sshRobo

	# 4) ssh: 7z-Archiv auf dem Server erstellen/aktualisieren
	$sshZip  = '"C:\Program Files\7-Zip\7z.exe" u -t7z -mx=5 -pdiabdachau d:\indamed\dat\medoffDB.7z d:\indamed\dat\medoffDBKop\'
	Write-Host "  ssh wser $sshZip"
	ssh wser $sshZip

	# 5) medoffDB.7z vom Server auf USB-Stick kopieren
	Write-Host "  robocopy \\wser\indamed\dat\ $usbDrive\indamed\dat\ medoffDB.7z /copy:dat"
	robocopy "\\wser\indamed\dat\" "$usbDrive\indamed\dat\" "medoffDB.7z" /copy:dat
} # tumedoff

if (1) {
tukop -qvz "p:\dok" -zvz "\dok"
tukop -qvz "p:\datenbanken" -zvz "\datenbanken"
$script:tukopUsbDrive = $null
tukop -qvz "\\wser\indamed" -zvz "\indamed" -avz "dat\medoffDB","dat\medoffDBKop"
if ($script:tukopUsbDrive) { tumedoff -usbDrive $script:tukopUsbDrive }  # serverseitige Vorbereitung + Kopie medoffDB.7z
tukop -qvz "p:\eingelesen" -zvz "\eingelesen"
}
tukop -qvz "\\wser\mo7z" -zvz "\mo7z" -avz "loe"
Stop-Transcript
exit 0



# PowerShell Script für automatisches Backup und Cleanup
# Findet das jüngste Verzeichnis mit Format ^\d{14} in h:\mosich
# Erstellt .7z Archiv falls nicht vorhanden und >= 1379 MB
# Löscht danach alle älteren .7z Dateien

$basePath = "\\wser\mosich"
$minSizeMB = 1379
$7zipPath = "C:\7-Zip\7z.exe"

Function Write-Colr
{
    Param ([String[]]$Tx,[ConsoleColor[]]$Cl,[Switch]$NoN=$false)
    For ([int]$i = 0; $i -lt $Tx.Length; $i++) { Write-Host $Tx[$i] -Foreground $Cl[$i] -NoNewLine }
    If ($NoN -eq $false) { Write-Host '' }
}

# Prüfe ob Verzeichnis existiert
if (-not (Test-Path $basePath)) {
    Write-Warning "Verzeichnis $basePath existiert nicht!"
    exit 1
}

# Finde alle Verzeichnisse mit dem Pattern ^\d{14}
$directories = Get-ChildItem -Path $basePath -Directory | Where-Object {
    $_.Name -match '^\d{14}$'
} | Sort-Object Name -Descending

if ($directories.Count -eq 0) {
    Write-Warning "Keine Verzeichnisse mit dem Pattern ^\d{14} gefunden."
    exit 0
}

# Das jüngste Verzeichnis (höchste Zahl = neuestes Datum)
$newestDir = $directories[0]
$archiveName = "$($newestDir.Name).7z"
$archivePath = Join-Path $basePath $archiveName

Write-Host "Jüngstes Verzeichnis: " -nonewline; write-host $($newestDir.FullName) -ForegroundColor Blue
Write-Host "Archivpfad: " -NoNewLine; write-host $archivePath -ForegroundColor Blue

# Prüfe ob Archiv bereits existiert
$abarbeiten=1
if (Test-Path $archivePath) {
    $archiveSize = (Get-Item $archivePath).Length
    $archiveSizeMB = [math]::Round($archiveSize / 1MB, 2)
    if ($archiveSizeMB -ge $minSizeMB) {
        Write-Colr -Tx "Archiv existiert bereits und ist ",$archiveSizeMB," MB groß (>= ",$minSizeMB," MB)." `
					-Cl White,Blue,White,Blue,White
		$abarbeiten=0
    } else {
        Write-Colr -Tx "Archiv existiert, ist aber nur ",$archiveSizeMB," MB groß (< ",$minSizeMB," MB)." `
					-Cl DarkYellow,Blue,DarkYellow,Blue,DarkYellow
        Write-Host "Archiv wird aufgefrischt."
	}
}
if ($abarbeiten) {
    # Erstelle das Archiv mit 7-Zip
	Write-Colr -Tx "Erstelle Archiv ",$archivePath," ..." -Cl White,Blue,White
    # Prüfe ob 7-Zip installiert ist
    if (-not (Test-Path $7zipPath)) {
		$7zipPath = "C:\Program Files\7-Zip\7z.exe"
	}	
    if (-not (Test-Path $7zipPath)) {
        $7zipPath = "C:\Program Files (x86)\7-Zip\7z.exe"
    }
    if (-not (Test-Path $7zipPath)) {
        Write-Host "7-Zip wurde nicht gefunden. Bitte installiere 7-Zip oder passe den Pfad an."
        exit 1
    }    
    # Komprimiere das Verzeichnis
    $arguments = "u", "-t7z", "-mx=5", "$archivePath", "$($newestDir.FullName)\*"
	Write-Host "Befehl: " -NoNewline; Write-Host "$7zipPath $arguments" -ForegroundColor Blue
    & $7zipPath $arguments
    if ($LASTEXITCODE -ne 0) {
        Write-Warning "Fehler beim Erstellen des Archivs. Exit Code: $LASTEXITCODE"
        exit 1
    }
    # Prüfe Größe des erstellten Archivs
    if (Test-Path $archivePath) {
        $archiveSize = (Get-Item $archivePath).Length
        $archiveSizeMB = [math]::Round($archiveSize / 1MB, 2)
		Write-Colr -Tx "Archiv erstellt: ",$archiveSizeMB," MB" -Cl White,Blue,White
        if ($archiveSizeMB -lt $minSizeMB) {
            Write-Warning "WARNUNG: Archiv ist nur $archiveSizeMB MB groß (< $minSizeMB MB)!"
            Write-Warning "Ältere Archive werden NICHT gelöscht."
            exit 0
        }
    } else {
        Write-Warning "Archiv wurde nicht erstellt, da $archivePath nicht gefunden!"
        exit 1
    }
}

## Lösche alle älteren .7z Dateien mit dem Pattern ^\d{14}.7z
#Write-Host "`nSuche nach älteren Archiven zum Löschen..."

#$allArchives = Get-ChildItem -Path $basePath -File -Filter "*.7z" | Where-Object {
#    $_.BaseName -match '^\d{14}$'
#} | Sort-Object Name -Descending

#$archivesToDelete = $allArchives | Where-Object {
#    $_.Name -ne $archiveName
#}

#if ($archivesToDelete.Count -gt 0) {
#    Write-Host "Folgende ältere Archive werden gelöscht:"
#    foreach ($archive in $archivesToDelete) {
#        $sizeMB = [math]::Round($archive.Length / 1MB, 2)
#        Write-Host "  - $($archive.Name) ($sizeMB MB)"
#    }
    
#    # Lösche die Dateien
#    $archivesToDelete | Remove-Item -Force
#    Write-Host "`n$($archivesToDelete.Count) ältere Archive wurden gelöscht."
#} else {
#    Write-Host "Keine älteren Archive zum Löschen gefunden."
#}


# Sync-NewestBackup.ps1
# Kopiert das neueste Verzeichnis aus h:\mosich\ auf USB-Stick g:\
# und löscht vorher ältere Kopien vom USB-Stick

# Quell- und Zielpfade
$sourcePath = "\\wser\mosich"
# Prüfen, ob Quellpfad existiert
if (-not (Test-Path $sourcePath)) {
    Write-Host "Quellpfad $sourcePath existiert nicht!"
    exit 1
}

$drives = Get-USB-Laufwerke
foreach ($drive in $drives) {
	try {
		$disk="$($drive.Name):"
		# Alle Dateien mit dem Muster YYYYMMDDHHMMSS.7z finden
		Write-Host "Fange an, die zu kopierende Datei zu suchen ..." -NoNewLine
		$pattern = '^\d{14}\.7z$'
		$sourceFiles = Get-ChildItem -Path $sourcePath -File -Depth 1| 
			Where-Object { $_.Name -match $pattern } |
			Sort-Object Name -Descending
		write-host "`rGefunden: ",$sourceFiles.Count,", Jüngste: ",$sourceFiles[0]
		if ($sourceFiles.Count -eq 0) {
			write-warning "Keine Dateien mit Muster $pattern in $sourcePath zum Kopieren gefunden!"
			exit 0
		}	
		$zuKop=$sourceFiles[0]
		$zuKopNam=$zuKop.Name
		Write-Host "Neueste Datei gefunden: $zuKopNam" -ForegroundColor Green
		$destFilPath = Join-Path $disk $zuKopNam
		write-host "Ziel: ",$destFilPath
		# Alle älteren Dateien mit dem Muster vom USB-Stick löschen
		Write-Host "Suche nach älteren Dateien auf $disk ..." -ForegroundColor Cyan
		$destFiles = Get-ChildItem -Path $disk -File -Depth 1| 
			Where-Object { $_.Name -match $pattern -and $_.Name -ne $zuKopNam}
		if ($destFiles.Count -gt 0) {
			Write-Host "Folgende ältere Dateien werden gelöscht:" -ForegroundColor Yellow
			foreach ($fil in $destFiles) {
				Write-Host "  - $($fil.Name)" -ForegroundColor Yellow
			}
			
			# Dateien löschen
			foreach ($fil in $destFiles) {
				try {
					Remove-Item -Path $fil.FullName -Force
					Write-Host "Gelöscht: $($fil.Name)" -ForegroundColor Red
				}
				catch {
					Write-Host "Fehler beim Löschen von $($fil.Name): $_"
				}
			}
		} else {
			Write-Host "Keine älteren Dateien auf $disk gefunden." -ForegroundColor Cyan
		}
		# Die neueste Datei auf den USB-Stick kopieren
		Write-Host "`nKopiere $zuKopNam nach $disk ..." -ForegroundColor Green
		try {
		#    Copy-Item -Path $newestDir.FullName -Destination $disk -Recurse -Force
			write-host robocopy "$sourcePath" "$disk" "$zuKopNam" /s /V /MT:16 /reg /r:2 /w:1
			robocopy "$sourcePath" "$disk" "$zuKopNam" /s /V /MT:16 /reg /r:2 /w:1
			Write-Host "Erfolgreich kopiert!" -ForegroundColor Green
			
			# Bestätigung
			if (Test-Path $destFilPath) {
				$sourceSize = (Get-ChildItem -Path $zuKop.FullName  | Measure-Object -Property Length -Sum).Sum
				$destSize = (Get-ChildItem -Path $destFilPath | Measure-Object -Property Length -Sum).Sum
				
				Write-Host "Zusammenfassung:" -ForegroundColor Cyan
				Write-Host " Quellgröße: $([math]::Round($sourceSize/1MB, 2)) MB" -ForegroundColor Cyan
				Write-Host " Zielgröße:  $([math]::Round($destSize/1MB, 2)) MB" -ForegroundColor Cyan
			}
		}
		catch {
			Write-Host "Fehler beim Kopieren: $_"
			exit 1
		}
		
		break
	}
	catch {
	    continue
	}
}

Write-Host "Vorgang abgeschlossen!" -ForegroundColor Green
exit 0