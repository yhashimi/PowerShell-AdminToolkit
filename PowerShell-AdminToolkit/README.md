# PowerShell-AdminToolkit

Projektname: PowerShell-AdminToolkit

Dieses Projekt enthält mehrere PowerShell-Module, die lokale Systemchecks, Software-Inventar, Benutzerverwaltung und Compliance-Dashboards automatisieren,html seite.


Ziel des Projekts

-Das Ziel meines Projekts ist es, ein portables, lokal ausführbares Automations-Tool für Windows-Systeme zu erstellen, das folgende Funktionen abdeckt:

-Software Inventory – Erfassen aller auf dem lokalen System installierten Programme und deren Details (Name, Version, Hersteller, Installationsdatum).

-Geräte-Check – Prüfen von Geräteeinstellungen, Sicherheitsfeatures und Status wichtiger Windows-Komponenten.

-User Management – Lokale Benutzer erstellen oder verwalten.

-Compliance-Check & Dashboard – Prüfen von Sicherheits- und Compliance-Aspekten (z.B. Firewall, Windows Defender, SMBv1, RDP, lokale Admins, Autostarts) und Darstellung der Ergebnisse in einer übersichtlichen HTML-Zusammenfassung.

-Logging – Umfassendes Logging aller Aktionen mit:

Rotierenden Logdateien (max. Anzahl definierbar)

Log-Level (INFO, WARN, ERROR)

Korrelierbarer Run-ID für jede Ausführung

-Export-Funktion – Ergebnisse aus Software Inventory und Compliance-Check können in CSV, JSON gespeichert werden, optional auch als HTML (für Compliance Dashboard).

-Portable Menüoberfläche – Alle Funktionen werden über ein Windows-Formular (WinForms) bedient, ohne dass direkt PowerShell-Fenster sichtbar sind.



## 📁 Projektstruktur

```text
PowerShell-AdminToolkit/
├─ config/
│  └─ logging.ps1        # Logging-Funktionen: Rotierende Logs, Run-ID, Levels
│                        # Logdateien werden unter logs/Logdateien gespeichert
├─ logs/
│  └─ Logdateien/        # Hier werden die Logs vom Logging-Skript gespeichert
├─ reports/
│  └─ exports/           # Exportierte Ergebnisse der Skripte
│     ├─ compliance/     # Compliance-Status (JSON + HTML)
│     ├─ csv/            # Software Inventory CSV-Dateien
│     ├─ json/           # Software Inventory JSON-Dateien
│     ├─ user/           # User-Erstellung Informationen
│     └─ ampelstatus/    # Ampelstatus der Checks (rot/gelb/grün)
├─ src/
│  ├─ module/            # Funktions-Skripte
│  │  ├─ complianceCheck.ps1
│  │  ├─ create_user.ps1
│  │  ├─ deviceCheck.ps1
│  │  └─ softwareInventory.ps1
│  ├─ funktion/          # Weitere Funktions-Skripte (Helper / Utilities)
│  │  └─ ...
│  ├─ scripte/           # Steuerungs-Skripte
│  │  ├─ login.ps1
│  │  ├─ main.ps1
│  │  └─ menu.ps1
│  └─ test/              # Test-Skripte / Beispiele
└─ README.md             # Projektdokumentation
```



🖥️ Installation & Setup

PowerShell ≥ 5.1 empfohlen.

Projektordner auf deinen Desktop oder gewünschten Pfad kopieren.

Stelle sicher, dass ExecutionPolicy erlaubt ist, Skripte auszuführen:

Set-ExecutionPolicy RemoteSigned -Scope CurrentUser




Führe main.ps1 aus, um das Menü zu öffnen.

📝 Module & Funktionen
1️⃣ Software Inventory (softwareInventory.ps1)

Liest lokal installierte Programme über die Registry (32-/64-Bit).

Export in CSV oder JSON unter reports/exports/csv oder reports/exports/json.

Öffnet die Export-Datei automatisch nach Abschluss.

Features:

Installationsdatum wird korrekt formatiert (YYYY-MM-DD).

Fehlerbehandlung über try/catch.

Logging via logging.ps1 möglich.

2️⃣ Geräte-Check (deviceCheck.ps1)

Prüft Desktop-Speicher, definierte Services (wuauserv, Spooler) und EventLog Errors.

Berechnet Ampelstatus: Grün, Gelb, Rot.

Export als CSV/JSON in reports/exports/ampelstatus.

GUI zeigt Ampelfarbe an und gibt Details via MessageBox aus.

3️⃣ Benutzer erstellen (create_user.ps1)

GUI zum Erstellen eines Users mit Username & Homefolder.

Erstellt automatisch Unterordner (Documents, Downloads, Desktop, Pictures).

Setzt Standardrechte (FullControl für aktuellen User).

Erzeugt Willkommensdatei Willkommen.txt.

4️⃣ Compliance-Check (complianceCheck.ps1)

Prüft: Firewall-Status, Defender, SMBv1, RDP, lokale Admins, Autostarts.

Ergebnisse werden als JSON in reports/exports/compliance/compliance.json gespeichert.

Optionales Dashboard öffnet HTML-Seite automatisch mit Tabellen & Status.

Fehlerbehandlung: fehlende Adminrechte, nicht gefundene Gruppen, SMBv1-Status.

5️⃣ Logging (logging.ps1)

Unterstützt rotierende Logs mit Zeitstempel.

Fehlerkategorien (INFO, WARN, ERROR) werden unterschieden.

Run-ID kann zur Korrelation von Logs genutzt werden.

Beispiel:

Write-Log -Level INFO -Message "Software-Inventory gestartet"


Logs werden standardmäßig in logs/Logdateien geschrieben.

📊 Dashboard & HTML-Reports

Dashboard erstellt HTML-Seiten, die im Browser geöffnet werden.

Anzeige:

Compliance Checks (Tabelle mit Check, Status, Message)

Top Findings & Ampelstatus

HTML-Dateien werden in reports/exports/compliance gespeichert.




Hinweise zur Nutzung

Um das Projekt korrekt zu starten und einen vollständigen Überblick zu erhalten, gehen Sie wie folgt vor:

Projektstart: Führen Sie die Datei main.ps1 aus.

Login: Melden Sie sich mit folgendem Benutzerkonto an:

Benutzername: admin

Passwort: password

Buttons:

Software Inventory -> Erfasst installierte Software und exportiert die Daten als CSV oder JSON.

Gerät-Check -> Prüft lokale Gerätekonfigurationen

User erstellen  -> Erstellt neue lokale Benutzerkonten. (C:\.....)

Dashboard  ->   Klick auf Dashboard öffnet automatisch HTML-Seite.

logging anzeigen -> Ergebnis als Markdown




Fehlerbehandlung

In allen wichtigen Skripten wird eine strukturierte Fehlerbehandlung mit try / catch eingesetzt.

Ziele der Fehlerbehandlung:

Abfangen unerwarteter Fehler (z. B. fehlende Rechte, nicht vorhandene Dateien)

Saubere Benutzerhinweise über MessageBoxen

Protokollierung der Fehler im Logging-System

Vermeidung von Script-Abbrüchen ohne Rückmeldung

Beispielhafte Einsatzbereiche:

Registry-Zugriffe

Datei- und Ordneroperationen

Exporte (CSV / JSON)

Compliance-Checks


Modulaufrufe aus dem Menü


