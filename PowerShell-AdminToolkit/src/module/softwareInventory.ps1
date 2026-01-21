# ==============================
# Software Inventory – Lokal
# ==============================

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# --------------------------
# Logging-Skript einbinden (portabel)
# --------------------------
$basePath = if ($PSScriptRoot) { $PSScriptRoot } else { Get-Location }
$logPath  = Join-Path $basePath "..\..\config\logging.ps1"

try {
    $logPath = Resolve-Path $logPath -ErrorAction Stop
    . $logPath
    Write-Log -Level INFO -Message "Software-Inventory gestartet"
}
catch {
    [System.Windows.Forms.MessageBox]::Show("Logging-Skript nicht gefunden: $logPath","Fehler")
    exit
}

# --------------------------
# Funktionen
# --------------------------
function Get-SoftwareInventory {
    $apps = @()  # Array initialisieren
    try {
        $keys = @(
            "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall",
            "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall"
        )

        foreach ($key in $keys) {
            try {
                $subkeys = Get-ChildItem -Path $key -ErrorAction Stop
                foreach ($subkey in $subkeys) {
                    $props = Get-ItemProperty -Path $subkey.PSPath
                    if ($props.DisplayName) {
                        $rawDate = $props.InstallDate
                        if ($rawDate -match '^\d{8}$') {
                            $installDate = "$($rawDate.Substring(0,4))-$($rawDate.Substring(4,2))-$($rawDate.Substring(6,2))"
                        } else {
                            $installDate = $null
                        }

                        # Immer ins Array hinzufügen
                        $apps += [PSCustomObject]@{
                            Name        = $props.DisplayName
                            Version     = $props.DisplayVersion
                            Vendor      = $props.Publisher
                            InstallDate = $installDate
                        }
                    }
                }
            }
            catch {
                Write-Log -Level WARN -Message "Registry-Pfad konnte nicht ausgelesen werden: $key"
            }
        }
    }
    catch {
        [System.Windows.Forms.MessageBox]::Show("Fehler beim Auslesen der Software:`n$_","Fehler")
        Write-Log -Level ERROR -Message "Fehler beim Auslesen der Software: $_"
    }

    # Sicherstellen, dass immer ein Array zurückgegeben wird
    if ($apps -eq $null) { $apps = @() }
    elseif ($apps -isnot [System.Array]) { $apps = @($apps) }

    return $apps
}


function Export-SoftwareInventory {
    param (
        $Data,
        [ValidateSet("CSV","JSON")]
        [string]$Format
    )

    # Sicherstellen, dass $Data ein Array ist
    if (-not $Data -or @($Data).Count -eq 0) {
        [System.Windows.Forms.MessageBox]::Show(
            "Keine Software gefunden zum Export.",
            "Fehler"
        )
        return
    }

    try {
        if ($PSScriptRoot) {
            $scriptRoot = $PSScriptRoot
        } else {
            $scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
        }
        $projectDir = Split-Path (Split-Path $scriptRoot -Parent) -Parent

        $targetFolder = Join-Path $projectDir "reports\exports\$($Format.ToLower())"
        if (-not (Test-Path $targetFolder)) { New-Item -Path $targetFolder -ItemType Directory -Force | Out-Null }

        $filePath = Join-Path $targetFolder "SoftwareInventory.$($Format.ToLower())"

        if ($Format -eq "CSV") {
            @($Data) | Export-Csv -Path $filePath -NoTypeInformation -Encoding UTF8
        } else {
            @($Data) | ConvertTo-Json -Depth 3 | Out-File $filePath -Encoding UTF8
        }

        Start-Process $filePath
        [System.Windows.Forms.MessageBox]::Show("Export abgeschlossen und Datei wurde geöffnet:`n$filePath","Fertig")
    }
    catch {
        [System.Windows.Forms.MessageBox]::Show("Fehler beim Export:`n$($_.Exception.Message)","Fehler")
    }
}


# --------------------------
# UI (FORM)
# --------------------------

$form = New-Object System.Windows.Forms.Form
$form.Text = "Software Inventory"
$form.Size = New-Object System.Drawing.Size(450,300)
$form.StartPosition = "CenterScreen"

$lblInfo = New-Object System.Windows.Forms.Label
$lblInfo.Text = "Dieses Tool arbeitet nur auf dem lokalen PC"
$lblInfo.Location = New-Object System.Drawing.Point(30,20)
$lblInfo.AutoSize = $true

$lblFormat = New-Object System.Windows.Forms.Label
$lblFormat.Text = "Export Format:"
$lblFormat.Location = New-Object System.Drawing.Point(30,60)

$cbFormat = New-Object System.Windows.Forms.ComboBox
$cbFormat.Items.AddRange(@("CSV","JSON"))
$cbFormat.SelectedIndex = 0
$cbFormat.Location = New-Object System.Drawing.Point(30,85)
$cbFormat.Width = 120

$btnStart = New-Object System.Windows.Forms.Button
$btnStart.Text = "Start Inventory"
$btnStart.Location = New-Object System.Drawing.Point(30,130)
$btnStart.Width = 150

$btnStart.Add_Click({
    try {
        $data = Get-SoftwareInventory
        Export-SoftwareInventory -Data $data -Format $cbFormat.SelectedItem
    }
    catch {
        Write-Log -Level ERROR -Message "Fehler beim Starten des Software-Inventory: $_"
        [System.Windows.Forms.MessageBox]::Show("Fehler beim Starten des Software-Inventory:`n$_","Fehler")
    }
})

$form.Controls.AddRange(@($lblInfo,$lblFormat,$cbFormat,$btnStart))
$form.ShowDialog()
