# ==============================
# deviceCheck.ps1 – Geräte-Check mit Ampelstatus + Export + Logging
# ==============================

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# -----------------------------
# Projekt-Root bestimmen
# -----------------------------
$scriptRoot = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }
$projectRoot = Split-Path (Split-Path $scriptRoot -Parent) -Parent

# Logger einbinden (portabel)
$loggerPath = Join-Path $projectRoot "config\logging.ps1"
if (-not (Test-Path $loggerPath)) {
    [System.Windows.Forms.MessageBox]::Show("Logging-Skript nicht gefunden:`n$loggerPath","Fehler")
    return
}
. $loggerPath
Write-Log -Level INFO -Message "Device-Check gestartet"

# -----------------------------
# Funktion Ampelstatus
# -----------------------------
function Get-DeviceStatus {
    $desktopStatus = "Grün"
    $serviceStatus = "Grün"
    $eventStatus   = "Grün"

    try {
        # --- Desktop Space ---
        try {
            $drives = Get-PSDrive -PSProvider 'FileSystem'
            foreach ($d in $drives) {
                if ($d.Free -ne $null -and $d.Used -ne $null -and ($d.Free + $d.Used) -gt 0) {
                    $freePercent = ($d.Free / ($d.Free + $d.Used)) * 100
                    if ($freePercent -lt 20) { $desktopStatus = "Gelb" }
                    if ($freePercent -lt 10) { $desktopStatus = "Rot"; break }
                }
            }
            Write-Log -Level INFO -Message "DesktopSpace geprüft: $desktopStatus"
        } catch {
            $desktopStatus = "Rot"
            Write-Log -Level ERROR -Message "Fehler bei DesktopSpace-Check: $_"
        }

        # --- Services ---
        try {
            $servicesToCheck = @("wuauserv","Spooler")
            foreach ($s in $servicesToCheck) {
                $svc = Get-Service -Name $s -ErrorAction SilentlyContinue
                if ($svc -and $svc.Status -ne "Running") {
                    $serviceStatus = if ($serviceStatus -eq "Rot") { "Rot" } else { "Gelb" }
                }
            }
            Write-Log -Level INFO -Message "Services geprüft: $serviceStatus"
        } catch {
            $serviceStatus = "Rot"
            Write-Log -Level ERROR -Message "Fehler beim Services-Check: $_"
        }

        # --- EventLog QuickCheck ---
        try {
            $events = Get-EventLog -LogName System -EntryType Error -Newest 20
            if ($events.Count -gt 0) { $eventStatus = "Rot" }
            Write-Log -Level INFO -Message "EventLog geprüft: $eventStatus ($($events.Count) Fehler-Einträge)"
        } catch {
            $eventStatus = "Rot"
            Write-Log -Level ERROR -Message "Fehler beim EventLog-Check: $_"
        }

        # --- Gesamter Ampelstatus ---
        $ampel = "Grün"
        if ($desktopStatus -eq "Rot" -or $serviceStatus -eq "Rot" -or $eventStatus -eq "Rot") {
            $ampel = "Rot"
        } elseif ($desktopStatus -eq "Gelb" -or $serviceStatus -eq "Gelb" -or $eventStatus -eq "Gelb") {
            $ampel = "Gelb"
        }
        Write-Log -Level INFO -Message "Ampelstatus berechnet: $ampel"

        return [PSCustomObject]@{
            DesktopSpace = $desktopStatus
            Services     = $serviceStatus
            EventLog     = $eventStatus
            Ampel        = $ampel
        }
    }
    catch {
        Write-Log -Level ERROR -Message "Fehler bei Device-Check: $_"
        return [PSCustomObject]@{
            DesktopSpace = "Rot"
            Services     = "Rot"
            EventLog     = "Rot"
            Ampel        = "Rot"
        }
    }
}

# -----------------------------
# Funktion Export
# -----------------------------
function Export-DeviceCheck {
    param (
        [PSCustomObject]$Result
    )

    if (-not $Result) { return }

    try {
        $targetFolder = Join-Path $projectRoot "reports\exports\ampelstatus"

        if (-not (Test-Path $targetFolder)) {
            New-Item -Path $targetFolder -ItemType Directory -Force | Out-Null
            Write-Log -Level INFO -Message "Ordner für Ampelstatus erstellt: $targetFolder"
        }

        # CSV
        $csvPath = Join-Path $targetFolder "deviceCheck.csv"
        $Result | Export-Csv -Path $csvPath -NoTypeInformation -Encoding UTF8
        Write-Log -Level INFO -Message "Device-Check CSV exportiert: $csvPath"

        # JSON
        $jsonPath = Join-Path $targetFolder "deviceCheck.json"
        $Result | ConvertTo-Json -Depth 3 | Out-File $jsonPath -Encoding UTF8
        Write-Log -Level INFO -Message "Device-Check JSON exportiert: $jsonPath"
    }
    catch {
        Write-Log -Level ERROR -Message "Fehler beim Export Device-Check: $_"
    }
}

# -----------------------------
# UI erstellen
# -----------------------------
$form = New-Object System.Windows.Forms.Form
$form.Text = "Geräte-Check – Ampelstatus"
$form.Size = New-Object System.Drawing.Size(400,220)
$form.StartPosition = "CenterScreen"

$lblAmpel = New-Object System.Windows.Forms.Label
$lblAmpel.Text = "Ampelstatus:"
$lblAmpel.Location = New-Object System.Drawing.Point(30,20)
$lblAmpel.AutoSize = $true

$pbAmpel = New-Object System.Windows.Forms.PictureBox
$pbAmpel.Size = New-Object System.Drawing.Size(50,50)
$pbAmpel.Location = New-Object System.Drawing.Point(150,15)
$pbAmpel.BackColor = [System.Drawing.Color]::Gray

$btnCheck = New-Object System.Windows.Forms.Button
$btnCheck.Text = "Geräte-Check starten"
$btnCheck.Location = New-Object System.Drawing.Point(30,90)
$btnCheck.Width = 200

$btnCheck.Add_Click({
    try {
        $result = Get-DeviceStatus

        switch ($result.Ampel) {
            "Grün" {$pbAmpel.BackColor = [System.Drawing.Color]::Green}
            "Gelb" {$pbAmpel.BackColor = [System.Drawing.Color]::Yellow}
            "Rot"  {$pbAmpel.BackColor = [System.Drawing.Color]::Red}
        }

        Export-DeviceCheck -Result $result

        [System.Windows.Forms.MessageBox]::Show(
            "Ampelstatus: $($result.Ampel)`n" +
            "DesktopSpace: $($result.DesktopSpace)`n" +
            "Services: $($result.Services)`n" +
            "EventLog: $($result.EventLog)`n`n" +
            "Ergebnisse wurden gespeichert in:`n$($projectRoot)\reports\exports\ampelstatus",
            "Geräte-Check"
        )

        Write-Log -Level INFO -Message "Device-Check ausgeführt und Ampelstatus angezeigt"
    }
    catch {
        Write-Log -Level ERROR -Message "Fehler beim Klicken auf Geräte-Check Button: $_"
        [System.Windows.Forms.MessageBox]::Show(
            "Fehler beim Geräte-Check:`n$($_)",
            "Fehler"
        )
    }
})

$form.Controls.AddRange(@($lblAmpel,$pbAmpel,$btnCheck))
$form.ShowDialog()
