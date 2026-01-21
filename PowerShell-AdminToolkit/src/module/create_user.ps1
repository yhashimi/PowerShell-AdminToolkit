# ==============================
# create_user.ps1 – User erstellen mit Logging
# ==============================

$base=$PSScriptRoot
$usebse = Join-Path $base "config\logging.ps1"

try {
    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing
    

     $scriptRoot = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }

    # Projekt-Root = 2 Ebenen hoch
    $projectRoot = Split-Path (Split-Path $scriptRoot -Parent) -Parent

    # logging.ps1 Pfad
    $logScript = Join-Path $projectRoot "config\logging.ps1"

    # Einbinden
    if (Test-Path $logScript) {
        . $logScript
    } else {
        [System.Windows.Forms.MessageBox]::Show(
            "logging.ps1 nicht gefunden:`n$logScript",
            "Fehler",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Error
        )
    }

    # Logger einbinden
    #. "C:\Users\Damago\Desktop\powershell_projectautomationen\config\logging.ps1"
    Write-Log -Level INFO -Message "User-Erstellung gestartet"

    # GUI erstellen
    $Form = New-Object System.Windows.Forms.Form
    $Form.Text = "User erstellen"
    $Form.Size = New-Object System.Drawing.Size(400,220)
    $Form.StartPosition = "CenterScreen"

    # Label und TextBox für Username
    $lblUser = New-Object System.Windows.Forms.Label
    $lblUser.Text = "Username:"
    $lblUser.Location = New-Object System.Drawing.Point(20,20)
    $txtUser = New-Object System.Windows.Forms.TextBox
    $txtUser.Location = New-Object System.Drawing.Point(150,20)
    $txtUser.Size = New-Object System.Drawing.Size(200,20)

    # Label und TextBox für Home-Verzeichnis
    $lblDir = New-Object System.Windows.Forms.Label
    $lblDir.Text = "Verzeichnis:"
    $lblDir.Location = New-Object System.Drawing.Point(20,60)
    $txtDir = New-Object System.Windows.Forms.TextBox
    $txtDir.Location = New-Object System.Drawing.Point(150,60)
    $txtDir.Size = New-Object System.Drawing.Size(200,20)

    # Button zum Erstellen
    $btnCreate = New-Object System.Windows.Forms.Button
    $btnCreate.Text = "Erstellen"
    $btnCreate.Location = New-Object System.Drawing.Point(150,110)
    $btnCreate.Size = New-Object System.Drawing.Size(100,30)

    $btnCreate.Add_Click({
        try {
            $username = $txtUser.Text.Trim()
            $homeDir = $txtDir.Text.Trim()

            if (-not $username -or -not $homeDir) {
                [System.Windows.Forms.MessageBox]::Show("Bitte Username und Home-Verzeichnis eingeben!","Fehler")
                Write-Log -Level WARN -Message "User-Erstellung abgebrochen: Username oder HomeDir leer"
                return
            }

            # --- 1️⃣ Homefolder / Ordnerstruktur erstellen ---
            $userFolder = Join-Path $homeDir $username
            $folders = @("Documents","Downloads","Desktop","Pictures")
            if (-not (Test-Path $userFolder)) {
                New-Item -ItemType Directory -Path $userFolder | Out-Null
                Write-Log -Level INFO -Message "User-Ordner erstellt: $userFolder"
            }
            foreach ($f in $folders) {
                $path = Join-Path $userFolder $f
                if (-not (Test-Path $path)) {
                    New-Item -ItemType Directory -Path $path | Out-Null
                    Write-Log -Level INFO -Message "Unterordner erstellt: $path"
                }
            }

            # --- 2️⃣ Standardrechte setzen ---
            $acl = Get-Acl $userFolder
            $accessRule = New-Object System.Security.AccessControl.FileSystemAccessRule("$env:USERNAME","FullControl","ContainerInherit,ObjectInherit","None","Allow")
            $acl.SetAccessRule($accessRule)
            Set-Acl $userFolder $acl
            Write-Log -Level INFO -Message "Zugriffsrechte gesetzt für $userFolder"

            # --- 3️⃣ Willkommensdatei erzeugen ---
            $welcomeFile = Join-Path $userFolder "Willkommen.txt"
            "Willkommen, $username!" | Out-File -FilePath $welcomeFile -Encoding UTF8
            Write-Log -Level INFO -Message "Willkommensdatei erstellt: $welcomeFile"

            # Optional: User-Daten exportieren
            try {
                $projectDir = "C:\Users\Damago\Desktop\powershell_projectautomationen"
                $targetFolder = Join-Path $projectDir "reports\exports\user"
                if (-not (Test-Path $targetFolder)) { New-Item -ItemType Directory -Path $targetFolder -Force | Out-Null }

                $userData = [PSCustomObject]@{
                    Username = $username
                    HomeDir  = $userFolder
                    Created  = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
                }

                $csvPath = Join-Path $targetFolder "users.csv"
                if (Test-Path $csvPath) {
                    $userData | Export-Csv -Path $csvPath -NoTypeInformation -Encoding UTF8 -Append
                } else {
                    $userData | Export-Csv -Path $csvPath -NoTypeInformation -Encoding UTF8
                }

                $jsonPath = Join-Path $targetFolder "users.json"
                $allUsers = @()
                if (Test-Path $jsonPath) { $allUsers = Get-Content $jsonPath | ConvertFrom-Json }
                $allUsers += $userData
                $allUsers | ConvertTo-Json -Depth 3 | Out-File -FilePath $jsonPath -Encoding UTF8

                Write-Log -Level INFO -Message "User-Daten exportiert: CSV=$csvPath JSON=$jsonPath"
            } catch {
                Write-Log -Level ERROR -Message "Fehler beim Export der User-Daten: $_"
            }

            [System.Windows.Forms.MessageBox]::Show("User '$username' erfolgreich erstellt!`nHomefolder: $userFolder","Erfolg")
            Write-Log -Level INFO -Message "User '$username' erfolgreich erstellt"
            $Form.Close()

        } catch {
            [System.Windows.Forms.MessageBox]::Show("Fehler beim Erstellen des Users:`n$_","Fehler")
            Write-Log -Level ERROR -Message "Fehler beim User-Erstellen: $_"
        }
    })

    # Controls hinzufügen
    $Form.Controls.Add($lblUser)
    $Form.Controls.Add($txtUser)
    $Form.Controls.Add($lblDir)
    $Form.Controls.Add($txtDir)
    $Form.Controls.Add($btnCreate)

    [void]$Form.ShowDialog()
}
catch {
    [System.Windows.Forms.MessageBox]::Show("Fehler beim Laden der Benutzererstellung:`n$_","Fehler")
    Write-Log -Level ERROR -Message "Fehler beim Start von create_user.ps1: $_"
}
