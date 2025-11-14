# AudioDeviceControl

AudioDeviceControl ist eine leichte macOS-Menüleisten-App, die automatisch dein bevorzugtes Audio-Ein- und -Ausgabegerät auswählt, basierend auf einer von dir festgelegten Prioritätsliste. Schluss mit AirPods-Chaos, falschen Mikrofonen und ständigem Umschalten.

![Screenshot](Docs/screenshot.png)

---

## Übersicht

macOS neigt dazu, beim Anschließen neuer Geräte das Default-Mikrofon oder den Default-Lautsprecher zu ändern, selbst wenn du das nicht willst. AudioDeviceControl löst dieses Problem dauerhaft:

- Du sortierst Input- und Output-Geräte per Drag & Drop nach Priorität.  
- Die App speichert diese Reihenfolge permanent.  
- Sobald das Top-Prio-Gerät verfügbar ist, wird es automatisch aktiviert.  
- Die App läuft sauber in der Menüleiste und aktualisiert sich live.

---

## Features

- **Drag & Drop Priorisierung** für Input & Output Devices  
- **Automatisches Umschalten**, sobald ein besser priorisiertes Device verfügbar ist  
- **Statusfarben** für jedes Gerät:  
  - 🟢 aktiv  
  - 🔵 verbunden, aber nicht aktiv  
  - ⚪ offline  
- **Live Device Detection**  
- **Persistente Speicherung** der Prioritäten  
- **Cleanes, minimalistisches macOS UI**  
- **Kein Dock Icon**, reine Menüleisten-App  

---

## Anforderungen

- macOS 13+
- Xcode 15+
- Swift 5.9+
- CoreAudio.framework

---

## Installation (Development)

```bash
git clone https://github.com/DEINNAME/AudioDeviceControl.git
cd AudioDeviceControl
open AudioDeviceControl.xcodeproj
