# main.ps1
try {
    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing

    # Hauptfenster erstellen
    $Form = New-Object System.Windows.Forms.Form
    $Form.Text = "Hauptmenü"
    $Form.Size = New-Object System.Drawing.Size(300,200)
    $Form.StartPosition = "CenterScreen"

    
    # Button: Login
    $btnLogin = New-Object System.Windows.Forms.Button
    $btnLogin.Location = New-Object System.Drawing.Point(50,50)
    $btnLogin.Size = New-Object System.Drawing.Size(180,30)
    $btnLogin.Text = "Login"
    $btnLogin.Add_Click({
        try {
            & "$PSScriptRoot\login.ps1"
        } catch {
            [System.Windows.Forms.MessageBox]::Show("Fehler beim Öffnen von login.ps1:`n$_","Fehler","OK","Error")
        }
    })

    # Buttons zum Formular hinzufügen
    
    $Form.Controls.Add($btnLogin)

    # Formular anzeigen
    [void]$Form.ShowDialog()
}
catch {
    [System.Windows.Forms.MessageBox]::Show("Fehler beim Starten der Anwendung:`n$_","Fehler","OK","Error")
}
