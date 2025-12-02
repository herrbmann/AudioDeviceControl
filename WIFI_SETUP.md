# WiFi-Funktion Setup in Xcode

## Problem
Die WiFi-Erkennung funktioniert nicht, weil die App im Sandbox-Modus läuft und Location Services benötigt.

## Lösung

### 1. Location Services in Xcode aktivieren

1. Öffne das Projekt in Xcode
2. Wähle das Target "AudioDeviceControl" aus
3. Gehe zum Tab **"Signing & Capabilities"**
4. Klicke auf **"+ Capability"**
5. Suche nach **"Location Services"** und füge es hinzu

**ODER** manuell in `project.pbxproj`:
- Suche nach `ENABLE_RESOURCE_ACCESS_LOCATION = NO;`
- Ändere zu `ENABLE_RESOURCE_ACCESS_LOCATION = YES;`

### 2. Info.plist Einträge hinzufügen

Falls eine Info.plist Datei existiert, füge diese Keys hinzu:

```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>WiFi-Netzwerk-Erkennung für automatischen Profilwechsel</string>
```

**ODER** in Xcode:
1. Wähle das Target "AudioDeviceControl"
2. Gehe zum Tab **"Info"**
3. Füge einen neuen Key hinzu: `Privacy - Location When In Use Usage Description`
4. Wert: `WiFi-Netzwerk-Erkennung für automatischen Profilwechsel`

### 3. Wichtig: Simulator vs. echter Mac

- **Simulator**: WiFi-Erkennung funktioniert oft nicht im Simulator
- **Echter Mac**: Teste auf einem echten Mac, um WiFi-Funktionalität zu prüfen

### 4. Nach den Änderungen

1. Clean Build Folder (Cmd+Shift+K)
2. Projekt neu bauen
3. App neu starten
4. Beim ersten Start wird macOS nach Location-Berechtigung fragen → **"Allow"** wählen

### 5. Debug-Logging

Die App gibt jetzt Debug-Meldungen aus:
- `📡 WiFiManager: Aktuelle SSID: ...` - WiFi wurde gefunden
- `📡 WiFiManager: Keine WiFi-Interface gefunden` - Problem mit CoreWLAN
- `📡 WiFiManager: WiFi ist nicht aktiviert` - WiFi ist ausgeschaltet
- `📡 WiFiPickerView: ...` - Was in der Dropdown-Liste angezeigt wird

Prüfe die Console in Xcode, um zu sehen, was passiert.

