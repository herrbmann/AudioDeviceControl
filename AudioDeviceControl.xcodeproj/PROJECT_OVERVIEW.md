// AudioDeviceControl – Projektüberblick und Agent-Notizen

Dieses Dokument fasst die Architektur, Dateien, Abhängigkeiten und wichtige Entscheidungsstellen des Projekts zusammen. Es dient als Referenz für zukünftige Änderungen und zur schnellen Einarbeitung.

Stand: Automatisch erstellt durch Coding Agent

## Ziel der App
Eine macOS Menüleisten-App, die Ein-/Ausgabe-Audiogeräte anzeigt, priorisiert (per Drag & Drop), ignorieren lässt und automatisch das jeweils höchste verfügbare Gerät als Standard setzt. Die App läuft ohne Dock-Icon und öffnet ein Popover aus der Menüleiste.

---

## Top-Level Einstieg und App-Lebenszyklus

- AudioDeviceControlApp.swift
  - SwiftUI-Einstiegspunkt mit `@main`.
  - Verwendet `@NSApplicationDelegateAdaptor(AppDelegate.self)`, um AppDelegate-Funktionalität zu integrieren.
  - Definiert eine leere `Settings`-Scene (kein klassisches Settings-Fenster).

- AppDelegate.swift
  - Erstellt `StatusBarController` beim Start.
  - Initialisiert `DeviceWatcher.shared` (Start des CoreAudio-Listeners).
  - Setzt Aktivierungs-Policy auf `.accessory` (kein Dock-Icon / keine reguläre Menüleiste).

---

## Menüleiste, Popover und UI

- StatusBarController.swift
  - Erstellt ein `NSStatusItem` mit SF Symbol "headphones" (Template-Icon für Light/Dark Mode).
  - Klick toggelt ein `NSPopover` (Größe: 520×640, Verhalten: `.transient`).
  - Popover-Inhalt: `MainTabsView()` via `NSHostingController`.
  - Aktiviert App im Vordergrund (`NSApp.activate(ignoringOtherApps: true)`).
  - Beobachtet `Notification.Name.closePopoverRequested`, um Popover zu schließen.

- MainTabsView.swift
  - Oberste SwiftUI-Ansicht im Popover.
  - Tabs: „Output“ (0) und „Input“ (1) mit `.segmented` Picker.
  - Zeigt je nach Tab `OutputDevicesView` oder `InputDevicesView`.
  - Steuerung „Show/Hide ignored devices“ (über `AudioState.showIgnored`).
  - Button „Unignore all“ → löscht ignorierte UIDs via `PriorityStore`.
  - Login-Item Toggle „start app on login“ via `ServiceManagement.SMAppService.mainApp`.
  - „Buy me a coffee“-Button (öffnet Ko-fi URL).
  - Footer mit Kontakt, Version/Build und Signatur.
  - Buttons: „Quit App“ (mit Bestätigung) und „Close“ (sendet `closePopoverRequested`).

- OutputDevicesView.swift / InputDevicesView.swift
  - Beziehen Daten aus `AudioState.shared`.
  - Nutzen `ReorderTableView` zur Darstellung und Reorder-Funktion.
  - Auf Reorder: Speichern neue Reihenfolge via `AudioState.updateOutputOrder` / `updateInputOrder`.

- ReorderTableView.swift
  - Generische Listendarstellung mit Drag-and-Drop (`.onMove`).
  - Zeilen enthalten: Icon, Name, Untertitel (Status) und einen Auge/Augeslash-Button.
  - Aktuell: Button ruft immer `AudioState.shared.ignoreDevice(device)` (siehe To-dos unten für Toggle-Verhalten).

- LogoView.swift
  - Zeigt `AppLogo` aus Asset-Katalog, inkl. Preview.

---

## Audio-Backend und Datenmodell

- DeviceWatcher.swift
  - Singleton, startet bei Init das Lauschen auf CoreAudio-Events:
    - `kAudioHardwarePropertyDevices` (Geräteliste geändert)
    - `kAudioHardwarePropertyDefaultInputDevice`
    - `kAudioHardwarePropertyDefaultOutputDevice`
  - Listener-Callbacks sind `Void`-Closures und posten über `scheduleRefresh()` einen debounced Refresh auf den Main-Thread.
  - Aufrufziel: `AudioState.shared.refresh()`.

- AudioDeviceManager.swift
  - CoreAudio-Wrapper:
    - `getAllDeviceIDs()`: Liefert alle `AudioDeviceID`s.
    - `getDefaultInputDevice()` / `getDefaultOutputDevice()`.
    - `setDefaultInputDevice(_:)` / `setDefaultOutputDevice(_:)`.
    - `isInputDevice(_:)` / `isOutputDevice(_:)`: Prüft, ob Streams in jeweiliger Richtung vorhanden sind.

- AudioDevice.swift
  - `AudioDevice` Modell mit Eigenschaften: `id`, `name`, `uid`, `isInput`, `isOutput`, `isAlive`, `isDefault`.
  - `state` abgeleitet: `.active` (Default), `.connected` (verbunden, aber nicht Default), `.offline` (nicht alive).
  - Status-Farbe (`NSColor`) und Symbol-Icon heuristisch aus dem Namen abgeleitet (AirPods, Monitor, Mic etc.).
  - Gleichheit (`Equatable`) basiert auf `uid`.

  - `AudioDeviceFactory`
    - Erzeugt `AudioDevice` aus `AudioDeviceID` (liest Name, UID, Alive) und Default-IDs.
    - `makeOffline(...)`: Erzeugt Offline-Platzhalter mit deterministischem Fake-ID-Hash (FNV-1a, high bit gesetzt).

- AudioState.swift
  - `ObservableObject` Singleton, zentrale Quelle für UI.
  - `@Published` Felder: `inputDevices`, `outputDevices`, `showIgnored`, `defaultInputID`, `defaultOutputID`, `listVersion`.
  - `refresh()`
    - Holt alle IDs, Default-IDs und ignorierte UIDs (`PriorityStore`).
    - Baut separate Arrays für Input/Output.
    - Registriert sichtbare Geräte in `DeviceRegistry` (siehe Hinweis unten).
    - Lädt gespeicherte Prioritäten (`PriorityStore`) und baut Listen, die:
      - Gespeicherte Reihenfolge strikt respektieren,
      - Offline-Platzhalter an ursprünglichen Positionen einfügen,
      - Neue Geräte anhängen,
      - Optional (wenn `showIgnored` false) ignorierte Geräte ausblenden.
    - Aktualisiert UI auf Main-Queue, erhöht `listVersion` (erzwingt Neurendern von `ReorderTableView`).
  - Reorder-API: `updateInputOrder`, `updateOutputOrder` → speichert UIDs und ruft `refresh()`.
  - Auto-Selection: `applyAutoSelection()` setzt Default Input/Output auf das erste verbundene Gerät der jeweiligen Liste.
  - Ignore-API: `ignoreDevice(_:)`, `unignoreAllDevices()`.

- PriorityStore.swift
  - Speichert in `UserDefaults`:
    - `audioDevicePriorityOrder_input` (Array<String> UIDs)
    - `audioDevicePriorityOrder_output` (Array<String> UIDs)
    - `audioDeviceIgnoredUIDs` (Array<String> UIDs)

Hinweis: `DeviceRegistry` wird in `AudioState` referenziert, ist aber im sichtbaren Projekt nicht enthalten. Vermutlich existiert eine Datei `DeviceRegistry.swift` mit:
- Speicherung bekannter UIDs und deren Metadaten (Name, isInput, isOutput),
- Zugriff über `DeviceRegistry.shared.metadata(for:)` und `storedUIDs`.
Wenn diese Datei fehlt, sollte sie ergänzt werden, da sie für Offline-Platzhalter und die rekonstruierten Listen verwendet wird.

---

## Datenfluss und Ereignisse (Kurz)

1. App-Start → `AppDelegate` erstellt `StatusBarController` und `DeviceWatcher.shared`.
2. `DeviceWatcher` lauscht CoreAudio-Events → debounced `AudioState.refresh()`.
3. `AudioState.refresh()` liest Geräte, Defaults, Priorität, Ignored-UIDs → baut priorisierte Listen inkl. Offline-Platzhalter → published an Views.
4. Views zeigen Listen über `ReorderTableView`; Reorder speichert neue Reihenfolge und triggert Refresh.
5. `applyAutoSelection()` setzt, falls nötig, Default Input/Output auf oberstes verbundenes Gerät.

---

## Bekannte UX/Code-Verbesserungen (To-dos)

- Ignore-Toggle in `ReorderTableView`
  - Aktuell ruft der Button immer `AudioState.shared.ignoreDevice(device)` auf.
  - Erwartet: Toggle-Verhalten (wenn bereits ignoriert → wieder sichtbar machen). Vorschlag:
    - Entweder `AudioState` um `unignoreDevice(_:)` erweitern und hier nutzen,
    - Oder direkt im Button-Handler: `if isIgnored { PriorityStore.shared.removeIgnoredUID(device.persistentUID) } else { PriorityStore.shared.addIgnoredUID(...) } ; AudioState.shared.refresh()`.

- Zugriff auf `UserDefaults` in der View reduzieren
  - `ReorderTableView` liest `PriorityStore.shared.loadIgnoredUIDs()` pro Zeile. Besser: einmal pro Render cachen oder durch `AudioState` als `@Published` Set bereitstellen.

- Auto-Selection Toggle
  - Optionaler Nutzer-Toggle „Auto-select devices“. Bei schnellen Wechseln eine kurze Verzögerung (Debounce) oder Suppression nach manuellen Änderungen.

- StatusBarController: Observer Cleanup
  - Optional `deinit` mit `NotificationCenter.default.removeObserver(self)` hinzufügen.

- Kontextmenü/Tastenkürzel
  - Rechtsklick-Menü für das Status-Icon (Open/Close/Preferences/Quit).
  - Globales Hotkey zum Öffnen/Schließen des Popovers.

- Icon-Heuristik
  - Weitere Muster ergänzen (z. B. spezifische Hersteller/Produktnamen).

- Dokumentation `DeviceRegistry`
  - Sicherstellen, dass `DeviceRegistry.shared` implementiert ist (Metadatenhaltung für Offline-Platzhalter). Falls nicht vorhanden, hinzufügen.

---

## Persistenzschlüssel (UserDefaults)
- `audioDevicePriorityOrder_input`: Reihenfolge Input-Geräte (UIDs)
- `audioDevicePriorityOrder_output`: Reihenfolge Output-Geräte (UIDs)
- `audioDeviceIgnoredUIDs`: Ignorierte Geräte (UIDs)

---

## Login-Item (Start bei Anmeldung)
- Verwendet `ServiceManagement.SMAppService.mainApp`.
- `setEnabled(_:)` registriert/entfernt das Login-Item.
- Fehler werden angezeigt; nach Änderung wird `launchAtLogin` mit realem Status synchronisiert.
- Wichtige Voraussetzung: korrekte Code-Signierung und Entitlements.

---

## Build-/Laufzeit-Hinweise
- macOS-App ohne Dock-Icon (`.accessory`).
- Popover wird aktiv im Vordergrund geöffnet.
- `CoreAudio` erfordert keine Sandbox-Ausnahmen für die verwendeten Funktionen.
- Für Login-Item ggf. Entitlements/Signierung prüfen.

---

## Schnellstart für neue Contributor
- Einstieg über `AudioDeviceControlApp` → `AppDelegate` → `StatusBarController`.
- UI-Änderungen in `MainTabsView`, `InputDevicesView`, `OutputDevicesView`, `ReorderTableView`.
- Audio/Logik in `AudioState`, `AudioDeviceManager`, `DeviceWatcher`, `AudioDevice`/`AudioDeviceFactory`.
- Reihenfolge/Ignore in `PriorityStore` (UserDefaults).

---

## Offene Fragen/Prüfpunkte
- Existiert `DeviceRegistry.swift`? Falls nein, implementieren (Metadatenhaltung für Offline-Anzeige).
- Soll Auto-Selection optional werden?
- Soll ein Kontextmenü oder Hotkey ergänzt werden?
- Soll ein Preferences-Fenster (statt leerer Settings-Scene) hinzugefügt werden?

---

## Changelog-Hinweise (für künftige Pflege)
- Bei Änderungen an der Prioritätslogik oder Ignore-Strategie: Dokumentiere API-Verhalten in diesem Dokument.
- Bei Hinzufügen neuer Dateien: Ergänze sie in den oben stehenden Abschnitten (Top-Level, UI, Backend).

---

## Kontakt/Meta
- Kontaktadresse in UI: `audiocontrol@techbude.com`.
- „Buy me a coffee“: https://ko-fi.com/X7X01OMYL7

Ende der Notizen.
