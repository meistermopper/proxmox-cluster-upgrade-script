# Proxmox VE Cluster Upgrade Script (Deutsch)

> **[🇬🇧 English version of this documentation](README.md)**

[![Version](https://img.shields.io/github/v/release/meistermopper/proxmox-cluster-upgrade-script?label=version&color=blue)](CHANGELOG.md)
[![ShellCheck CI](https://github.com/meistermopper/proxmox-cluster-upgrade-script/actions/workflows/lint.yml/badge.svg)](https://github.com/meistermopper/proxmox-cluster-upgrade-script/actions/workflows/lint.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Proxmox VE](https://img.shields.io/badge/Proxmox_VE-8.x_%7C_9.x-orange.svg)](https://www.proxmox.com)
[![Language: Bash](https://img.shields.io/badge/Language-Bash-4EAA25.svg)](cluster-upgrade.sh)
![Editor](https://img.shields.io/badge/Editor-Antigravity%20IDE-blueviolet?style=flat-square)

Automatisierte, sichere und sequenzielle Upgrade-Lösung für Proxmox VE (PVE) Cluster mit High-Availability (HA) Wartungsmodus, Live-Evakuierung von VMs/LXCs, Systemupdates (`dist-upgrade`), automatischem Aufräumen (`autoremove`), Reboots und Benachrichtigungen via Gotify & Telegram.

## Funktionen

- **Cluster Pre-Flight Health Check**: Führt vor dem Upgrade aller Nodes eine automatische Gesundheitsprüfung durch (Quorum-Check via `pvecm status` und HA-Fehlerprüfung via `ha-manager status`). Bricht bei Problemen ab, um die Cluster-Stabilität zu schützen.
- **Intelligente Vorab-Prüfung (Smart Upgrade)**: Prüft vor dem Evakuieren und Neustarten, ob auf der Node tatsächlich ausstehende Updates oder ein erforderlicher Reboot vorliegen. Ist die Node bereits aktuell, werden Evakuierung und Reboot automatisch übersprungen.
- **Einzel-Node-Upgrade (`--node`)**: Ermöglicht die gezielte Aktualisierung einer einzelnen spezifischen Node im Cluster.
- **HA Wartungsmodus & Evakuierung**: Versetzt jede Node vor dem Upgrade in den Wartungsmodus (`ha-manager crm-command node-maintenance enable <node>`), sodass PVE HA alle VMs und LXC-Container automatisch auf andere Nodes migriert.
- **Evakuierungs-Überwachung**: Prüft aktiv, ob alle laufenden QEMU-VMs und LXC-Container die Node verlassen haben.
- **System-Upgrade & Cleanup**: Führt `apt-get update`, `apt-get dist-upgrade -y` und `apt-get autoremove -y` aus.
- **Sicherer Reboot & Quorum-Check**: Rebootet die Node und wartet, bis die Node wieder erreichbar ist und den Cluster-Quorum-Status (`pvecm status`) erreicht hat.
- **Automatische Freigabe**: Deaktiviert den Wartungsmodus nach erfolgreichem Reboot wieder.
- **Gotify & Telegram Notifications**:
  - **Gotify**: Push-Benachrichtigungen mit Prioritäten (Info, Success, Warning, Error).
  - **Telegram**: Formatierte Benachrichtigungen direkt in dein Telegram-Chatfenster oder deine Gruppe.
- **Dry-Run-Modus**: Testet die Konfiguration und SSH-Verbindungen ohne echte Änderungen/Reboots (`--dry-run`).

---

## Voraussetzungen

### Ausführungsort

Das Skript kann wahlweise ausgeführt werden von:

1. **Einem zentralen Verwaltungs-Server / Admin-PC (Empfohlen)** mit SSH-Zugriff auf alle Cluster-Nodes.
2. **Einer der Proxmox-Cluster-Nodes (z. B. Node 1)**:
   > **Wichtiger Hinweis:** Wenn das Skript direkt auf einer Node ausgeführt wird, die sich im `NODES`-Array befindet, wird der Prozess während des Reboots dieser Node vom Betriebssystem beendet. Trage in diesem Fall die ausführende Node an die **letzte Stelle** in `NODES` ein oder verwende einen externen Host / eine HA-VM.

### SSH- & Sudo-Anforderungen

- **SSH-Key-Authentifizierung**: SSH-Public-Key-Login ohne Passwortabfrage auf allen Ziel-Nodes eingerichtet.
- **Benutzerrechte**:
  - **Option A (`root` - Standard)**: `SSH_USER="root"` in `config.env`. SSH-Key in `/root/.ssh/authorized_keys` auf allen Nodes.
  - **Option B (Non-Root User mit Sudo, z. B. `username`)**: `SSH_USER="username"` und `USE_SUDO=true` in `config.env`.
    Der Benutzer muss auf allen Ziel-Nodes in `/etc/sudoers.d/<username>` mit passwortlosem Sudo konfiguriert sein:
    ```bash
    username ALL=(ALL) NOPASSWD: ALL
    ```
- `curl` auf dem ausführenden System installiert (für Benachrichtigungen).
- Proxmox VE HA konfiguriert (für automatische Live-Migration im Maintenance Mode).

---

## Einrichten & Nutzung

1. Repository klonen oder Dateien herunterladen:

   ```bash
   git clone https://github.com/meistermopper/proxmox-cluster-upgrade-script.git
   cd proxmox-cluster-upgrade-script
   ```

2. Ausführungsrechte vergeben:

   ```bash
   chmod +x cluster-upgrade.sh
   ```

3. Konfigurationsdatei aus der Vorlage erstellen:

   ```bash
   cp config.env.example config.env
   ```

4. `config.env` bearbeiten und deine Nodes, SSH-Einstellungen sowie Webhooks eintragen:

   ```bash
   NODES=("192.168.1.7" "192.168.1.17" "192.168.1.27")

   # SSH-Einstellungen
   SSH_USER="username"      # 'root' oder ein Sudo-Benutzer
   USE_SUDO=true           # Auf 'true' setzen, wenn SSH_USER kein root ist (erfordert NOPASSWD in sudoers)
   SSH_PORT="22"
   SSH_KEY_PATH=""         # Pfad zum SSH-Key oder leer lassen für Standard-SSH-Agent

   # Gotify (optional)
   GOTIFY_ENABLED=true
   GOTIFY_URL="https://gotify.deinedomain.de"
   GOTIFY_TOKEN="dein_token"

   # Telegram (optional)
   TELEGRAM_ENABLED=true
   TELEGRAM_BOT_TOKEN="123456789:ABCdefGHIjklMNOpqrsTUVwxyz"
   TELEGRAM_CHAT_ID="-100123456789"
   ```

---

## Befehle & Ausführung

Eine detaillierte Schnellanleitung findest du in **[docs/QUICKSTART_de.md](file:///c:/Users/thoma/dev/active/proxmox-cluster-upgrade-script/docs/QUICKSTART_de.md)**.

### Windows 1-Klick-Hilfsskripte (Im Explorer)

- **[dry-run.bat](file:///c:/Users/thoma/dev/active/proxmox-cluster-upgrade-script/dry-run.bat)**: Startet den Trockenlauf per Doppelklick.
- **[run-upgrade.bat](file:///c:/Users/thoma/dev/active/proxmox-cluster-upgrade-script/run-upgrade.bat)**: Startet das echte Cluster-Upgrade mit Sicherheits-Bestätigung.

---

### Terminal (PowerShell / Git Bash)

#### Trockenlauf (Dry-Run)

Testet SSH-Verbindungen und den Ablauf ohne Ausführung von Upgrades oder Reboots:

```bash
bash ./cluster-upgrade.sh --dry-run
```

#### Vollständiges Cluster-Upgrade ausführen

Startet den sequenziellen Upgrade-Prozess für alle konfigurierten Nodes:

```bash
bash ./cluster-upgrade.sh
```

---

## Commandline-Optionen

| Option | Option (lang)   | Beschreibung                                                  |
| :----- | :-------------- | :------------------------------------------------------------ |
| `-c`   | `--config FILE` | Pfad zu einer benutzerdefinierten `config.env` Datei          |
| `-d`   | `--dry-run`     | Simulation ohne echte Änderungen oder Reboots                 |
| `-n`   | `--node NODE`   | Einzelne spezifische Node gezielt upgraden (IP oder Hostname) |
| `-h`   | `--help`        | Zeigt die Hilfe-Meldung an                                    |

---

## Changelog

Eine detaillierte Übersicht aller Änderungen und der Versionshistorie findest du in der **[CHANGELOG.md](CHANGELOG.md)** (bzw. für ältere Versionen in **[CHANGELOG_OLD.md](CHANGELOG_OLD.md)**).

---

## Lizenz

MIT Lizenz. Freie Nutzung und Anpassung ausdrücklich erlaubt.
