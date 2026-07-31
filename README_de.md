# Proxmox VE Cluster Upgrade Script (Deutsch)

Automatisierte, sichere und sequenzielle Upgrade-Lösung für Proxmox VE (PVE) Cluster mit High-Availability (HA) Wartungsmodus, Live-Evakuierung von VMs/LXCs, Systemupdates (`dist-upgrade`), automatischem Aufräumen (`autoremove`), Reboots und Benachrichtigungen via Gotify & Telegram.

## Funktionen

- **HA Wartungsmodus & Evakuierung**: Versetzt jede Node vor dem Upgrade in den Wartungsmodus (`ha-manager node-maintenance enable <node>`), sodass PVE HA alle VMs und LXC-Container automatisch auf andere Nodes migriert.
- **Evakuierungs-Überwachung**: Prpüft aktiv, ob alle laufenden QEMU-VMs und LXC-Container die Node verlassen haben.
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
1. Einer der Proxmox-Cluster-Nodes (z. B. Node 1).
2. Einem zentralen Verwaltungs-Server (z. B. Ansible-Host oder Admin-PC) mit SSH-Zugriff auf alle Cluster-Nodes.

### Anforderungen
- SSH-Key-Authentifizierung für den `root`-Benutzer (oder Sudoer) auf allen Cluster-Nodes ohne Passwortabfrage.
- `curl` auf dem ausführenden System installiert.
- Proxmox VE HA konfiguriert (für automatische Migration im Maintenance Mode).

---

## Einrichten & Nutzung

1. Repository klonen oder Dateien herunterladen:
   ```bash
   git clone https://github.com/dein-username/proxmox-cluster-upgrade.sh.git
   cd proxmox-cluster-upgrade.sh
   ```

2. Ausführungsrechte vergeben:
   ```bash
   chmod +x cluster-upgrade.sh
   ```

3. Konfigurationsdatei aus der Vorlage erstellen:
   ```bash
   cp config.env.example config.env
   ```

4. `config.env` bearbeiten und deine Nodes sowie Webhooks eintragen:
   ```bash
   NODES=("192.168.1.7" "192.168.1.17" "192.168.1.27")
   
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

## Befehle

### Trockenlauf (Dry-Run)
Testet SSH-Verbindungen und den Ablauf ohne Ausführung von Upgrades oder Reboots:
```bash
./cluster-upgrade.sh --dry-run
```

### Vollständiges Cluster-Upgrade ausführen
Startet den sequenziellen Upgrade-Prozess für alle konfigurierten Nodes:
```bash
./cluster-upgrade.sh
```

---

## Commandline-Optionen

| Option | Option (lang) | Beschreibung |
| :--- | :--- | :--- |
| `-c` | `--config FILE` | Pfad zu einer benutzerdefinierten `config.env` Datei |
| `-d` | `--dry-run` | Simulation ohne echte Änderungen oder Reboots |
| `-h` | `--help` | Zeigt die Hilfe-Meldung an |
