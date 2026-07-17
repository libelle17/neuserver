# online.ps1 - zeigt rasch an, welche der bekannten Linux-Server und
# Windows-PCs im LAN gerade eingeschaltet/erreichbar sind, mit
# Name, IPv4- und MAC-Adresse. Pings laufen parallel (Jobs) fuer Tempo.

$linuxPcs = "linux0","linux1","linux2","linux3","linux7","linux8"
$winPcs   = "anmoo","anmww","anmmo","anmmw","anmh","bzw2","fuss","labor3","res1","res3","sono1","sr6","srn2","szo1","szon1","szoo1","szow1","szs1","szn4","wexp","wres","wser","amd","hss"

function Test-Gruppe($namen, $gruppe) {
    $jobs = foreach ($n in $namen) {
        Start-Job -ArgumentList $n, $gruppe -ScriptBlock {
            param($name, $grp)
            $r = Test-Connection -ComputerName $name -Count 1 -ErrorAction SilentlyContinue
            if ($r) {
                $ip = $r.IPV4Address.IPAddressToString
                $mac = (Get-NetNeighbor -IPAddress $ip -ErrorAction SilentlyContinue | Select-Object -First 1 -ExpandProperty LinkLayerAddress)
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
