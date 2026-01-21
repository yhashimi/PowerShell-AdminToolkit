# ==============================
# logger.ps1 – Rotating Logs, Kategorien, Run-ID, portabel
# ==============================

param (
    [string]$LogFolder = (Join-Path (Split-Path $PSScriptRoot -Parent) "logs\Logdateien"),
    [int]$MaxFiles = 5
)

# -----------------------------
# Run-ID generieren (einmal pro PowerShell-Sitzung)
# -----------------------------
if (-not (Get-Variable -Name RunID -Scope Global -ErrorAction SilentlyContinue)) {
    $Global:RunID = [guid]::NewGuid().ToString()
}

# -----------------------------
# Log-Ordner erstellen, falls nicht vorhanden
# -----------------------------
if (-not (Test-Path $LogFolder)) {
    New-Item -Path $LogFolder -ItemType Directory -Force | Out-Null
}

# -----------------------------
# Write-Log Funktion
# -----------------------------
function Write-Log {
    param (
        [Parameter(Mandatory=$true)]
        [ValidateSet("INFO","WARN","ERROR")]
        [string]$Level,

        [Parameter(Mandatory=$true)]
        [string]$Message
    )

    # Timestamp
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

    # Log-Datei für heutigen Tag
    $logFile = Join-Path $LogFolder ("log_" + (Get-Date -Format "yyyyMMdd") + ".txt")

    # Log-Eintrag
    $entry = "$timestamp | RunID=$Global:RunID | $Level | $Message"

    # In Datei schreiben
    Add-Content -Path $logFile -Value $entry

    # -----------------------------
    # Rotierende Logs: maximal $MaxFiles
    # -----------------------------
    $files = @(Get-ChildItem -Path $LogFolder -Filter "log_*.txt" | Sort-Object LastWriteTime -Descending)

    if ($files.Count -gt $MaxFiles) {
        $files[$MaxFiles..($files.Count-1)] | Remove-Item -Force
    }
}
