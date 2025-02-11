chcp 65001 > $null
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$host.UI.RawUI.WindowTitle = "Advanced DNS Changer"

# Advanced DNS Changer
$currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = New-Object Security.Principal.WindowsPrincipal($currentUser)

if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

$interfaceName = (Get-NetConnectionProfile | Where-Object { $_.IPv4Connectivity -eq 'Internet' -or $_.IPv6Connectivity -eq 'Internet' }).InterfaceAlias
if (-not $interfaceName) {
   Write-Host "Error: You are not connected to any internet interface. You should connect first, then execute this script." -ForegroundColor Red
   exit
}

Write-Host "Interface em uso: $interfaceName" -ForegroundColor Cyan

$dnsServers = @{
    "Google" = @{
        IPv4_1 = "8.8.8.8"
        IPv4_2 = "8.8.4.4"
        IPv6_1 = "2001:4860:4860::8888"
        IPv6_2 = "2001:4860:4860::8844"
    }
    "Cloudflare" = @{
        IPv4_1 = "1.1.1.1"
        IPv4_2 = "1.0.0.1"
        IPv6_1 = "2606:4700:4700::1111"
        IPv6_2 = "2606:4700:4700::1001"
    }
    "AdGuard" = @{
        IPv4_1 = "94.140.14.14"
        IPv4_2 = "94.140.15.15"
        IPv6_1 = "2a10:50c0::ad1:ff"
        IPv6_2 = "2a10:50c0::ad2:ff"
    }
    "Quad9" = @{
        IPv4_1 = "9.9.9.9"
        IPv4_2 = "149.112.112.112"
        IPv6_1 = "2620:fe::fe"
        IPv6_2 = "2620:fe::9"
    }
    "OpenDNS" = @{
        IPv4_1 = "208.67.222.222"
        IPv4_2 = "208.67.220.220"
        IPv6_1 = "2620:119:35::35"
        IPv6_2 = "2620:119:53::53"
    }
    "DNS.WATCH" = @{
        IPv4_1 = "84.200.69.80"
        IPv4_2 = "84.200.70.40"
        IPv6_1 = "2001:1608:10:25::1c04:b12f"
        IPv6_2 = "2001:1608:10:25::9249:d69b"
    }
    "UncensoredDNS" = @{
        IPv4_1 = "91.239.100.100"
        IPv4_2 = "89.233.43.71"
        IPv6_1 = "2001:67c:28a4::"
        IPv6_2 = "2a01:3a0:53:53::"
    }
    "RadicalDNS" = @{
        IPv4_1 = "88.198.92.222"
        IPv4_2 = "192.71.166.92"
        IPv6_1 = "2a01:4f8:1c0c:82c0::1"
        IPv6_2 = "2a03:f80:30:192:71:166:92:1"
    }
    "NextDNS" = @{
        IPv4_1 = "45.90.28.93"
        IPv4_2 = "45.90.30.93"
        IPv6_1 = "2a07:a8c0::f2:b79d"
        IPv6_2 = "2a07:a8c1::f2:b79d"
    }
}

function Show-Menu {
    $host.UI.RawUI.BackgroundColor = "Black"
    $host.UI.RawUI.ForegroundColor = "White"
    Clear-Host
    
    $cursor = $host.UI.RawUI.CursorPosition
    $host.UI.RawUI.CursorSize = 0
    
    $currentChoice = 0
    $choices = $dnsServers.Keys | Sort-Object
    $maxChoice = $choices.Count - 1

    while ($true) {
        
        Write-Host "+------------------------------+" -ForegroundColor Yellow
        Write-Host "| Advanced DNS Changer v1.0.0  |" -ForegroundColor Yellow
        Write-Host "|   github.com/terremoth/adc   |" -ForegroundColor Yellow
        Write-Host "+------------------------------+" -ForegroundColor Yellow
        Write-Host "`n  Select the desired DNS:`n" -ForegroundColor Cyan

        for ($i = 0; $i -lt $choices.Count; $i++) {
            if ($i -eq $currentChoice) {
                Write-Host "  > " -NoNewline -ForegroundColor Green
                Write-Host "$($choices[$i])" -ForegroundColor Green
            } else {
                Write-Host "    $($choices[$i])"
            }
        }

        $key = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

        switch ($key.VirtualKeyCode) {
            38 { # Seta para cima
                $currentChoice--
                if ($currentChoice -lt 0) { $currentChoice = $maxChoice }
                Clear-Host
            }
            40 { # Seta para baixo
                $currentChoice++
                if ($currentChoice -gt $maxChoice) { $currentChoice = 0 }
                Clear-Host
            }
            13 { # Enter
                return $choices[$currentChoice]
            }
            default {
                Clear-Host
            }
        }
    }
}

$selectedDNS = Show-Menu
$dnsConfig = $dnsServers[$selectedDNS]

Write-Host "`nConfiguring DNS for $selectedDNS..." -ForegroundColor Yellow

# Configurar DNS IPv4
netsh interface ipv4 set dns "$interfaceName" static $dnsConfig.IPv4_1 primary validate=no > $null
netsh interface ipv4 add dns "$interfaceName" $dnsConfig.IPv4_2 validate=no > $null

# Configurar DNS IPv6
netsh interface ipv6 set dns "$interfaceName" static $dnsConfig.IPv6_1 primary validate=no > $null
netsh interface ipv6 add dns "$interfaceName" $dnsConfig.IPv6_2 validate=no > $null

Write-Host "`nCleaning DNS cache..." -ForegroundColor Yellow
ipconfig /flushdns > $null

Write-Host "`nDNS successfully configured for $selectedDNS!`n" -ForegroundColor Green
Write-Host "Primary   IPv4: $($dnsConfig.IPv4_1)"
Write-Host "Secondary IPv4: $($dnsConfig.IPv4_2)"
Write-Host "Primary   IPv6: $($dnsConfig.IPv6_1)"
Write-Host "Secondary IPv6: $($dnsConfig.IPv6_2)"

Write-Host "`nPress any key to exit..." -ForegroundColor Cyan
$host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
