Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$form = New-Object System.Windows.Forms.Form
$form.Text = "Automationen - Menü"
$form.Size = New-Object System.Drawing.Size(400,380)
$form.StartPosition = "CenterScreen"

# ---------- Hilfsfunktion: Projekt-Root bestimmen ----------
function Get-ProjectRoot {
    if ($PSScriptRoot) { $scriptRoot = $PSScriptRoot } 
    else { $scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path }
    return Split-Path (Split-Path $scriptRoot -Parent) -Parent
}

# ---------- Buttons ----------

# Software Inventory
$btnInventory = New-Object System.Windows.Forms.Button
$btnInventory.Text = "Software Inventory"
$btnInventory.Size = New-Object System.Drawing.Size(150,40)
$btnInventory.Location = New-Object System.Drawing.Point(120,40)
$btnInventory.Add_Click({
    $ProjectRoot = Get-ProjectRoot
    $inventoryScript = Join-Path $ProjectRoot "src\module\softwareInventory.ps1"
    if (Test-Path $inventoryScript) {
        . $inventoryScript
    } else {
        [System.Windows.Forms.MessageBox]::Show(
            "softwareInventory.ps1 nicht gefunden:`n$inventoryScript",
            "Fehler",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Error
        )
    }
})

# Gerät-Check
$btnGeraetCheck = New-Object System.Windows.Forms.Button
$btnGeraetCheck.Text = "Gerät-Check"
$btnGeraetCheck.Size = New-Object System.Drawing.Size(150,40)
$btnGeraetCheck.Location = New-Object System.Drawing.Point(120,100)
$btnGeraetCheck.Add_Click({
    $ProjectRoot = Get-ProjectRoot
    $scriptPath = Join-Path $ProjectRoot "src\module\deviceCheck.ps1"
    if (Test-Path $scriptPath) {
        . $scriptPath
    } else {
        [System.Windows.Forms.MessageBox]::Show(
            "deviceCheck.ps1 nicht gefunden:`n$scriptPath",
            "Fehler"
        )
    }
})

# User erstellen
$btnUser = New-Object System.Windows.Forms.Button
$btnUser.Text = "User erstellen"
$btnUser.Size = New-Object System.Drawing.Size(150,40)
$btnUser.Location = New-Object System.Drawing.Point(120,160)
$btnUser.Add_Click({
    $ProjectRoot = Get-ProjectRoot
    $scriptPath = Join-Path $ProjectRoot "src\module\create_user.ps1"
    if (Test-Path $scriptPath) {
        . $scriptPath
    } else {
        [System.Windows.Forms.MessageBox]::Show(
            "create_user.ps1 nicht gefunden:`n$scriptPath",
            "Fehler"
        )
    }
})

# Dashboard / Compliance
$btnDashboard = New-Object System.Windows.Forms.Button
$btnDashboard.Text = "Dashboard"
$btnDashboard.Size = New-Object System.Drawing.Size(150,40)
$btnDashboard.Location = New-Object System.Drawing.Point(120,220)
$btnDashboard.Add_Click({
    try {
        $ProjectRoot = Get-ProjectRoot
        $jsonFile = Join-Path $ProjectRoot "reports\exports\compliance\compliance.json"
        if (-not (Test-Path $jsonFile)) {
            [System.Windows.Forms.MessageBox]::Show("Compliance-JSON nicht gefunden:`n$jsonFile","Fehler")
            return
        }

        $data = Get-Content $jsonFile -Raw | ConvertFrom-Json

        $html = @"
<!DOCTYPE html>
<html>
<head>
<title>Compliance Dashboard</title>
<style>
body { font-family: Arial; padding: 20px; }
table { border-collapse: collapse; width: 100%; }
th, td { border: 1px solid #333; padding: 8px; }
th { background-color: #4CAF50; color: white; }
.OK { background-color: #d4edda; }
.FAIL { background-color: #f8d7da; }
.WARN { background-color: #fff3cd; }
.INFO { background-color: #d1ecf1; }
</style>
</head>
<body>
<h2>Compliance Dashboard</h2>
<table>
<tr><th>Check</th><th>Status</th><th>Details</th></tr>
"@

        foreach ($item in $data) {
            $statusClass = $item.Status
            $details = if ($item.Details) { $item.Details } else { $item.Message }
            $html += "<tr class='$statusClass'><td>$($item.Check)</td><td>$($item.Status)</td><td>$details</td></tr>`n"
        }

        $html += "</table></body></html>"

        $htmlFile = Join-Path $ProjectRoot "reports\exports\compliance\dashboard_compliance.html"

        # HTML schreiben mit UTF8
        $html | Out-File -FilePath $htmlFile -Encoding UTF8 -Force

        $chrome = "C:\Program Files\Google\Chrome\Application\chrome.exe"
        Start-Process $chrome -ArgumentList $htmlFile

    }
    catch {
        [System.Windows.Forms.MessageBox]::Show($_.Exception.Message, "Fehler")
    }
})


# Logging Info
# Button für Logging
$btnLogging = New-Object System.Windows.Forms.Button
$btnLogging.Text = "Logging anzeigen"
$btnLogging.Size = New-Object System.Drawing.Size(150,40)
$btnLogging.Location = New-Object System.Drawing.Point(120,280)

$btnLogging.Add_Click({
    try {
        # -----------------------------
        # ScriptRoot dynamisch bestimmen
        # -----------------------------
        if ($PSScriptRoot) { $scriptRoot = $PSScriptRoot } else { $scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path }
        $ProjectRoot = Split-Path (Split-Path $scriptRoot -Parent) -Parent

        # Log-Ordner
        $logFolder = Join-Path $ProjectRoot "logs\Logdateien"
        $todayLog = Get-ChildItem -Path $logFolder -Filter "log_*.txt" | Sort-Object LastWriteTime -Descending | Select-Object -First 1

        if (-not $todayLog) {
            [System.Windows.Forms.MessageBox]::Show("Keine Logs gefunden.","Info")
            return
        }

        $logContent = Get-Content $todayLog.FullName

        # -----------------------------
        # Markdown-Fenster erstellen
        # -----------------------------
        $logForm = New-Object System.Windows.Forms.Form
        $logForm.Text = "Logging – Markdown View"
        $logForm.Size = New-Object System.Drawing.Size(800,600)
        $logForm.StartPosition = "CenterScreen"

        $txtBox = New-Object System.Windows.Forms.TextBox
        $txtBox.Multiline = $true
        $txtBox.ScrollBars = "Both"
        $txtBox.WordWrap = $false
        $txtBox.ReadOnly = $true
        $txtBox.Font = New-Object System.Drawing.Font("Consolas",10)
        $txtBox.Dock = "Fill"

        # Markdown Format: Tabelle simulieren
        $markdown = "| Timestamp | RunID | Level | Message |`n|---|---|---|---|`n"
        foreach ($line in $logContent) {
            $parts = $line -split "\|"
            if ($parts.Count -ge 4) {
                $markdown += "| $($parts[0].Trim()) | $($parts[1].Trim()) | $($parts[2].Trim()) | $($parts[3..($parts.Count-1)] -join '|').Trim() |`n"
            }
        }

        $txtBox.Text = $markdown
        $logForm.Controls.Add($txtBox)
        $logForm.ShowDialog()
    }
    catch {
        [System.Windows.Forms.MessageBox]::Show("Fehler beim Laden der Logs:`n$_","Fehler")
    }
})

$form.Controls.Add($btnLogging)



# ---------- Controls hinzufügen ----------
$form.Controls.AddRange(@($btnInventory,$btnGeraetCheck,$btnUser,$btnDashboard,$btnLogging))

# ---------- Formular anzeigen ----------
$form.ShowDialog()
