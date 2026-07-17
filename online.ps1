# online.ps1 - zeigt rasch an, welche der bekannten Linux-Server und
# Windows-PCs im LAN gerade eingeschaltet/erreichbar sind, mit
# Name, IPv4- und MAC-Adresse. Pings laufen parallel (Jobs) fuer Tempo.

$linuxPcs = "linux0","linux1","linux2","linux3","linux7","linux8"
$winPcs   = "anmoo","anmww","anmmo","anmmw","anmh","bzw2","fuss","labor3","res1","res3","sono1","sr6","srn2","szo1","szon1","szoo1","szow1","szs1","szn4","wexp","wres","wser","amd","hss"

function Test-Gruppe($namen, $gruppe) {
    $jobs = foreach ($n in $namen) {
        Start-Job -ArgumentList $n, $gruppe, $env:COMPUTERNAME -ScriptBlock {
            param($name, $grp, $eigenname)
            # Test-Connection liefert je nach PowerShell-Version unterschiedliche Objekte
            # und Parameter: PS7+ (pwsh) kennt -IPv4 (erzwingt reine IPv4-Aufloesung,
            # vermeidet Mehrdeutigkeit bei Hosts mit mehreren/veralteten DNS-Eintraegen)
            # und liefert die Adresse in .Address; PS5.1 (powershell.exe) kennt -IPv4
            # NICHT und liefert die Adresse in .IPV4Address.
            if ($PSVersionTable.PSVersion.Major -ge 6) {
                $r = Test-Connection -ComputerName $name -Count 1 -IPv4 -ErrorAction SilentlyContinue
            } else {
                $r = Test-Connection -ComputerName $name -Count 1 -ErrorAction SilentlyContinue
            }
            if ($r) {
                if ($PSVersionTable.PSVersion.Major -ge 6) {
                    $ip = $r.Address.IPAddressToString
                } else {
                    $ip = $r.IPV4Address.IPAddressToString
                }
                # PS7 liefert bei manchen nicht wirklich erreichbaren Hosts trotzdem ein
                # (dann leeres) Ergebnisobjekt zurueck, anders als PS5.1 (dort $null) -
                # ohne gueltige IP behandeln wir das wie "nicht erreichbar":
                if (-not $ip -and -not ($name -ieq $eigenname)) { return }
                $mac = $null
                if ($name -ieq $eigenname) {
                    # eigene IP/MAC nicht per Testverbindung (liefert bei sich selbst z.T. IPv6-Linklokal) -
                    # stattdessen direkt die eigene aktive Netzwerkkarte abfragen
                    $adapter = Get-NetAdapter -Physical | Where-Object Status -eq 'Up' | Select-Object -First 1
                    $mac = $adapter.MacAddress
                    $ip = (Get-NetIPAddress -InterfaceIndex $adapter.ifIndex -AddressFamily IPv4 -ErrorAction SilentlyContinue | Select-Object -First 1 -ExpandProperty IPAddress)
                } elseif ($ip) {
                    # Get-NetNeighbor mit leerer/null IPAddress wirft einen Parameter-
                    # Validierungsfehler, den -ErrorAction SilentlyContinue NICHT abfaengt
                    # (der Fehler entsteht schon beim Parameter-Binden) - daher nur aufrufen,
                    # wenn $ip tatsaechlich gesetzt ist.
                    $mac = (Get-NetNeighbor -IPAddress $ip -ErrorAction SilentlyContinue | Select-Object -First 1 -ExpandProperty LinkLayerAddress)
                }
                [PSCustomObject]@{ Gruppe = $grp; Name = $name; IP = $ip; Eigen = ($name -ieq $eigenname); MAC = $mac }
            }
        }
    }
    $jobs | Wait-Job | Receive-Job
    $jobs | Remove-Job
}

function Show-Tabelle($ergebnisse) {
    if (-not $ergebnisse) { return }
    $wName = ($ergebnisse.Name | Measure-Object -Property Length -Maximum).Maximum
    $wIP   = [Math]::Max(2, ($ergebnisse.IP   | Measure-Object -Property Length -Maximum).Maximum)
    $zeile = "{0,-$wName}  {1,-$wIP}  {2}"
    Write-Host ($zeile -f "Name", "IP", "MAC")
    Write-Host ($zeile -f ('-' * $wName), ('-' * $wIP), '---')
    foreach ($e in $ergebnisse) {
        $text = $zeile -f $e.Name, $e.IP, $e.MAC
        if ($e.Eigen) { Write-Host $text -ForegroundColor Magenta } else { Write-Host $text }
    }
}

$linuxErg = Test-Gruppe $linuxPcs "linux" | Sort-Object Name
$winErg   = Test-Gruppe $winPcs   "windows" | Sort-Object Name

Write-Host "=== Linux-Server ===" -ForegroundColor Cyan
Show-Tabelle $linuxErg

Write-Host "=== Windows-PCs ===" -ForegroundColor Cyan
Show-Tabelle $winErg

Write-Host "$($linuxErg.Count) von $($linuxPcs.Count) Linux-Servern, $($winErg.Count) von $($winPcs.Count) Windows-PCs erreichbar."
