try {
    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing

    # GUI erstellen
    $Form = New-Object System.Windows.Forms.Form
    $Form.Text = "Login"
    $Form.Size = New-Object System.Drawing.Size(400,220)
    $Form.StartPosition = "CenterScreen"

    # Label und TextBox für Username
    $lblUser = New-Object System.Windows.Forms.Label
    $lblUser.Text = "Username:"
    $lblUser.Location = New-Object System.Drawing.Point(20,20)
    $lblUser.Size = New-Object System.Drawing.Size(120,20)

    $txtUser = New-Object System.Windows.Forms.TextBox
    $txtUser.Location = New-Object System.Drawing.Point(150,20)
    $txtUser.Size = New-Object System.Drawing.Size(200,20)

    # Label und TextBox für Password
    $lblPas = New-Object System.Windows.Forms.Label
    $lblPas.Text = "Password:"
    $lblPas.Location = New-Object System.Drawing.Point(20,60)
    $lblPas.Size = New-Object System.Drawing.Size(120,20)

    $txtPas = New-Object System.Windows.Forms.TextBox
    $txtPas.Location = New-Object System.Drawing.Point(150,60)
    $txtPas.Size = New-Object System.Drawing.Size(200,20)
    $txtPas.UseSystemPasswordChar = $true  # Passwortmaskierung

    # Button zum Login
    $btnLogin = New-Object System.Windows.Forms.Button
    $btnLogin.Text = "Login"
    $btnLogin.Location = New-Object System.Drawing.Point(150,110)
    $btnLogin.Size = New-Object System.Drawing.Size(100,30)

    $user = "admin"
    $pas  = "Password"

    # Click-Event
    $btnLogin.Add_Click({
        $username = $txtUser.Text.Trim()
        $password = $txtPas.Text

        if (-not $username -or -not $password) {
            [System.Windows.Forms.MessageBox]::Show(
                "Bitte Username und Passwort eingeben!",
                "Fehler",
                [System.Windows.Forms.MessageBoxButtons]::OK,
                [System.Windows.Forms.MessageBoxIcon]::Error





            )
            return
        }

        if ($username -eq $user -and $password -eq $pas) {
            [System.Windows.Forms.MessageBox]::Show(
                "Login erfolgreich!",
                "Erfolg",
                [System.Windows.Forms.MessageBoxButtons]::OK,
                [System.Windows.Forms.MessageBoxIcon]::Information
            )
         $basePfad = $PSScriptRoot
         $menuScript = Join-Path $basePfad "\menu.ps1"

        if (Test-Path $menuScript) {
        . $menuScript  # Punkt-Sourcing, führt Menü direkt in der aktuellen Session aus
    }
             
        }
        else {
            [System.Windows.Forms.MessageBox]::Show(
                "Username oder Passwort falsch!",
                "Login fehlgeschlagen",
                [System.Windows.Forms.MessageBoxButtons]::OK,
                [System.Windows.Forms.MessageBoxIcon]::Warning
            )
        }
    })

    # Controls hinzufügen
    $Form.Controls.Add($lblUser)
    $Form.Controls.Add($txtUser)
    $Form.Controls.Add($lblPas)
    $Form.Controls.Add($txtPas)
    $Form.Controls.Add($btnLogin)

    [void]$Form.ShowDialog()
}
catch {
    [System.Windows.Forms.MessageBox]::Show("Fehler:`n$_","Fehler")
}
