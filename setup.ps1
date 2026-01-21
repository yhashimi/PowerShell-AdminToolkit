
# setup.ps1
# ------------------------------------------
# Dieses Skript erstellt automatisch alle
# benötigten Ordner für das Projekt.
# Leere Ordner werden von Git nicht gespeichert,
# deshalb sorgt dieses Skript dafür, dass alles
# nach dem Klonen vorhanden ist.






$root = "$env:USERPROFILE\Desktop\PowerShell-AdminToolkit"

$folders = @(
    "$root\src",
    "$root\src\script",
    "$root\src\module",
    "$root\src\function",
    "$root\config",
    "$root\reports",
    "$root\reports\exports",
    "$root\reports\logs",
    "$root\test",
    "$root\logs",
    "$root\Logdateien"
	

)

foreach ($folder in $folders) {
    if (-not (Test-Path $folder)) {
        New-Item -ItemType Directory -Path $folder -Force | Out-Null
    }
}

New-Item -Path "$root\README.md" -ItemType File -Force


