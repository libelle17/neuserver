# online.ps1 - zeigt rasch an, welche der bekannten Linux-Server und
# Windows-PCs im LAN gerade eingeschaltet/erreichbar sind, mit
# Name, IPv4- und MAC-Adresse. Pings laufen parallel (Jobs) fuer Tempo.

$linuxPcs = "linux0","linux1","linux2","linux3","linux7","linux8"
$winPcs   = "anmoo","anmww","anmmo","anmmw","anmh","bzw2","fuss","labor3","res1","res3","sono1","sr6","srn2","szo1","szon1","szoo1","szow1","szs1","szn4","wexp","wres","wser","amd","hss"

function Test-Gruppe($namen, $gruppe) {
    $jobs = foreach ($n in $namen) {
        Start-Job -ArgumentList $n, $gruppe, $env:COMPUTERNAME -ScriptBlock {
            param($name, $grp, $eigenname)
            $r = Test-Connection -ComputerName $name -Count 1 -ErrorAction SilentlyContinue
            if ($r) {
                # Test-Connection liefert je nach PowerShell-Version unterschiedliche Objekte:
                # PS7+ (pwsh): .Address ist bereits die IPAddress; PS5.1 (powershell.exe): .IPV4Address
                if ($PSVersionTable.PSVersion.Major -ge 6) {
                    $ip = $r.Address.IPAddressToString
                } else {
                    $ip = $r.IPV4Address.IPAddressToString
                }
                if ($name -ieq $eigenname) {
                    # eigene IP/MAC nicht per Testverbindung (liefert bei sich selbst z.T. IPv6-Linklokal) -
                    # stattdessen direkt die eigene aktive Netzwerkkarte abfragen
                    $adapter = Get-NetAdapter -Physical | Where-Object Status -eq 'Up' | Select-Object -First 1
                    $mac = $adapter.MacAddress
                    $ip = (Get-NetIPAddress -InterfaceIndex $adapter.ifIndex -AddressFamily IPv4 -ErrorAction SilentlyContinue | Select-Object -First 1 -ExpandProperty IPAddress)
                } else {
                    $mac = (Get-NetNeighbor -IPAddress $ip -ErrorAction SilentlyContinue | Select-Object -First 1 -ExpandProperty LinkLayerAddress)
                }
                [PSCustomObject]@{ Gruppe = $grp; Name = $name; IP = $ip; MAC = $mac }
            }
        }
    }
    $jobs | Wait-Job | Receive-Job
    $jobs | Remove-Job
}

$linuxErg = Test-Gruppe $linuxPcs "linux" | Sort-Object Name
$winErg   = Test-Gruppe $winPcs   "windows" | Sort-Object Name

Write-Host "=== Linux-Server ===" -ForegroundColor Cyan
$linuxErg | Format-Table Name, IP, MAC -AutoSize

Write-Host "=== Windows-PCs ===" -ForegroundColor Cyan
$winErg | Format-Table Name, IP, MAC -AutoSize

Write-Host "$($linuxErg.Count) von $($linuxPcs.Count) Linux-Servern, $($winErg.Count) von $($winPcs.Count) Windows-PCs erreichbar."
