# ==============================
# complianceCheck.ps1 – Compliance Snapshot + HTML Dashboard
# ==============================

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# --------------------------
# Projekt-Root korrekt ermitteln
# (src\module → 2 Ebenen hoch)
# --------------------------
$projectDir = Resolve-Path (Join-Path $PSScriptRoot "..\..")

# Zielordner
$exportFolder = Join-Path $projectDir "reports\exports\compliance"
if (-not (Test-Path $exportFolder)) {
    New-Item -ItemType Directory -Path $exportFolder -Force | Out-Null
}

$jsonFile = Join-Path $exportFolder "compliance.json"
$htmlFile = Join-Path $exportFolder "dashboard_compliance.html"

# --------------------------
# Findings sammeln
# --------------------------
$script:ComplianceResults = @()

function Add-Finding {
    param(
        [string]$Check,
        [string]$Status,
        [string]$Details
    )

    $script:ComplianceResults += [PSCustomObject]@{
        Check   = $Check
        Status  = $Status
        Details = $Details
    }
}

# --------------------------
# 1️⃣ Firewall Status
# --------------------------
try {
    $fw = Get-NetFirewallProfile -ErrorAction Stop | Select-Object Name, Enabled
    foreach ($f in $fw) {
        $state = if ($f.Enabled) { "OK" } else { "FAIL" }
        Add-Finding "Firewall ($($f.Name))" $state "Enabled: $($f.Enabled)"
    }
}
catch {
    Add-Finding "Firewall" "WARN" "Status nicht prüfbar"
}

# --------------------------
# 2️⃣ Windows Defender Status
# --------------------------
try {
    $defender = Get-MpComputerStatus -ErrorAction Stop
    $state = if ($defender.AntispywareEnabled -and $defender.RealTimeProtectionEnabled) {
        "OK"
    } else {
        "FAIL"
    }

    Add-Finding "Defender" $state `
        "Realtime=$($defender.RealTimeProtectionEnabled), Antispyware=$($defender.AntispywareEnabled)"
}
catch {
    Add-Finding "Defender" "WARN" "Status nicht prüfbar"
}

# --------------------------
# 3️⃣ SMBv1
# --------------------------
try {
    $smb = Get-WindowsOptionalFeature -Online -FeatureName SMB1Protocol -ErrorAction Stop
    if ($smb.State -eq "Enabled") {
        Add-Finding "SMBv1" "FAIL" "SMBv1 ist aktiviert"
    }
    else {
        Add-Finding "SMBv1" "OK" "SMBv1 ist deaktiviert"
    }
}
catch {
    Add-Finding "SMBv1" "WARN" "Keine Adminrechte – Status nicht prüfbar"
}

# --------------------------
# 4️⃣ RDP Status
# --------------------------
try {
    $rdpKey = "HKLM:\System\CurrentControlSet\Control\Terminal Server"
    $rdpVal = Get-ItemProperty -Path $rdpKey -Name "fDenyTSConnections" -ErrorAction Stop

    $state = if ($rdpVal.fDenyTSConnections -eq 0) { "FAIL" } else { "OK" }
    Add-Finding "RDP" $state "fDenyTSConnections=$($rdpVal.fDenyTSConnections)"
}
catch {
    Add-Finding "RDP" "WARN" "Status nicht prüfbar"
}

# --------------------------
# 5️⃣ Lokale Administratoren
# --------------------------
try {
    $admins = Get-LocalGroupMember Administrators -ErrorAction Stop |
              Select-Object -Expand Name

    Add-Finding "Lokale Administratoren" "INFO" ($admins -join ", ")
}
catch {
    Add-Finding "Lokale Administratoren" "WARN" "Admins konnten nicht gelesen werden"
}

# --------------------------
# 6️⃣ Autostarts
# --------------------------
try {
    $startupKeys = @(
        "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run",
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run"
    )

    $autoStart = @()
    foreach ($key in $startupKeys) {
        if (Test-Path $key) {
            $autoStart += Get-ItemProperty $key |
                Get-Member -MemberType NoteProperty |
                Select-Object -Expand Name
        }
    }

    $autoStartList = if ($autoStart.Count -gt 0) {
        $autoStart -join ", "
    } else {
        "Keine"
    }

    Add-Finding "Autostarts" "INFO" $autoStartList
}
catch {
    Add-Finding "Autostarts" "WARN" "Autostarts konnten nicht gelesen werden"
}

# --------------------------
# JSON speichern
# --------------------------
try {
    $script:ComplianceResults |
        ConvertTo-Json -Depth 3 |
        Set-Content -Path $jsonFile -Encoding UTF8
}
catch {
    Write-Warning "JSON konnte nicht gespeichert werden: $_"
}

# --------------------------
# HTML Dashboard erzeugen
# --------------------------
try {
    $html = @"
<!DOCTYPE html>
<html lang="de">
<head>
<meta charset="UTF-8">
<title>Compliance Dashboard</title>
<style>
body { font-family: Arial; margin: 20px; }
table { border-collapse: collapse; width: 100%; }
th, td { border: 1px solid black; padding: 6px; }
th { background-color: #4CAF50; color: white; }
.ok { background-color: #c6efce; }
.fail { background-color: #ffc7ce; }
.warn { background-color: #ffeb9c; }
.info { background-color: #d9e1f2; }
</style>
</head>
<body>
<h2>Compliance Dashboard</h2>
<table>
<tr><th>Check</th><th>Status</th><th>Details</th></tr>
"@

    foreach ($f in $script:ComplianceResults) {
        $cls = switch ($f.Status) {
            "OK"   { "ok" }
            "FAIL" { "fail" }
            "WARN" { "warn" }
            "INFO" { "info" }
        }

        $html += "<tr class='$cls'><td>$($f.Check)</td><td>$($f.Status)</td><td>$($f.Details)</td></tr>`n"
    }

    $html += "</table></body></html>"

    Set-Content -Path $htmlFile -Value $html -Encoding UTF8
    $chrome = "C:\Program Files\Google\Chrome\Application\chrome.exe"
    Start-Process $chrome -ArgumentList $htmlFile


    Start-Process $htmlFile
}
catch {
    Write-Warning "HTML Dashboard konnte nicht erstellt werden: $_"
}
