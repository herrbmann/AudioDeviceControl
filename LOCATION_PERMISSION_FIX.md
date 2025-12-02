# Location Services Berechtigung - Komplette Lösung

## Problem
Die App erscheint nicht in den Location Services Einstellungen und fragt nicht nach der Berechtigung.

## Lösung

### 1. Entitlements File wurde erstellt
✅ `AudioDeviceControl.entitlements` wurde erstellt mit:
- `com.apple.security.personal-information.location` = `true`

### 2. In Xcode konfigurieren

1. **Öffne das Projekt in Xcode**

2. **Wähle das Target "AudioDeviceControl"**

3. **Gehe zum Tab "Signing & Capabilities"**
   - Prüfe, ob "Location Services" als Capability hinzugefügt ist
   - Falls nicht: Klicke auf "+ Capability" → "Location Services"

4. **Gehe zum Tab "Build Settings"**
   - Suche nach "Code Signing Entitlements"
   - Setze den Wert auf: `AudioDeviceControl/AudioDeviceControl.entitlements`
   - (Oder den relativen Pfad zu deinem Entitlements File)

5. **Gehe zum Tab "Info"**
   - Prüfe, ob `Privacy - Location When In Use Usage Description` vorhanden ist
   - Falls nicht: Füge es hinzu mit Wert: `WiFi-Netzwerk-Erkennung für automatischen Profilwechsel`

### 3. Clean & Rebuild

1. **Clean Build Folder**: Cmd+Shift+K
2. **Projekt neu bauen**: Cmd+B
3. **App starten**: Cmd+R

### 4. Was passiert jetzt

- Beim ersten Start sollte macOS nach Location Services Berechtigung fragen
- Falls nicht automatisch: Die App hat jetzt einen Button "Berechtigung anfordern" im WiFi-Picker
- Nach Klick auf den Button sollte macOS nach der Berechtigung fragen
- Die App sollte dann in System Settings → Privacy & Security → Location Services erscheinen

### 5. Falls es immer noch nicht funktioniert

1. **Prüfe die Console** in Xcode:
   - Suche nach `📡 WiFiManager: Location Services Status: ...`
   - Status 0 = notDetermined (noch nicht angefragt)
   - Status 1 = restricted
   - Status 2 = denied
   - Status 3 = authorizedAlways
   - Status 4 = authorizedWhenInUse

2. **Manuell in System Settings prüfen**:
   - System Settings → Privacy & Security → Location Services
   - Scrolle nach unten - AudioDeviceControl sollte erscheinen
   - Falls nicht: App komplett beenden und neu starten

3. **Entitlements File prüfen**:
   - Öffne `AudioDeviceControl.entitlements` in Xcode
   - Stelle sicher, dass `com.apple.security.personal-information.location` = `true` ist

### 6. Alternative: Manuell in System Settings aktivieren

Falls die automatische Abfrage nicht funktioniert:
1. System Settings → Privacy & Security → Location Services
2. Scrolle zu "AudioDeviceControl"
3. Aktiviere den Schalter
4. Starte die App neu

