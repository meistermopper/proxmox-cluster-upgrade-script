# Proxmox VE Cluster Upgrade - Schnellanleitung & Befehlsübersicht

Diese Übersicht zeigt dir alle Möglichkeiten, das Upgrade-Skript einfach auszuführen.

> **💡 Intelligenter Modus (Smart Upgrade):** Das Skript prüft vor jedem Upgrade automatisch, ob auf der Node Paketupdates vorliegen oder ein Neustart erforderlich ist. Nodes, die bereits auf dem neuesten Stand sind, werden automatisch übersprungen (keine VM-Evakuierung, kein Reboot).

---

## 🖱️ 1. Per Doppelklick unter Windows (Am einfachsten)

Du kannst das Skript unter Windows direkt per Doppelklick im Explorer starten. Dafür wurden zwei Hilfsdateien angelegt:

* **[dry-run.bat](file:///c:/Users/thoma/dev/active/proxmox-cluster-upgrade-script/dry-run.bat)**:
  Führt den **Trockenlauf** (Simulation) aus. Es werden keine echten Änderungen oder Reboots gemacht. Das Fenster bleibt am Ende offen, damit du die Ausgabe prüfen kannst.
  
* **[run-upgrade.bat](file:///c:/Users/thoma/dev/active/proxmox-cluster-upgrade-script/run-upgrade.bat)**:
  Startet das **echte Cluster-Upgrade**. Vor dem Start wirst du Sicherheits-halber nach einer Bestätigung (`y/N`) gefragt.

---

## 💻 2. Befehle im Terminal (PowerShell / Git Bash)

Öffne dein Terminal im Ordner des Skripts und nutze folgende Befehle:

### Trockenlauf (Testmodus)
```powershell
bash ./cluster-upgrade.sh --dry-run
```

### Echte Aktualisierung aller Nodes
```powershell
bash ./cluster-upgrade.sh
```

### Mit benutzerdefinierter Konfigurationsdatei
```powershell
bash ./cluster-upgrade.sh --config /pfad/zu/deiner_config.env
```

---

## ⚡ 3. PowerShell-Kürzel anlegen (Optional)

Wenn du im Terminal noch kürzer tippen möchtest, kannst du dir in deiner PowerShell temporär oder dauerhaft ein Kürzel (Alias) einrichten:

```powershell
# Kürzel für den Trockenlauf:
function pve-dry { bash ./cluster-upgrade.sh --dry-run }

# Kürzel für das echte Upgrade:
function pve-upgrade { bash ./cluster-upgrade.sh }
```

Danach reicht die Eingabe von `pve-dry` oder `pve-upgrade` im Terminal!
