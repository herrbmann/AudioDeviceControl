# Changelog

## [Unreleased] - 2024-12-XX

- **WiFi-Verbesserungen**: 
  - Zugriff auf alle gespeicherten macOS WLANs im Dropdown (nicht nur aktuell verbundenes)
  - Automatische Erkennung des WiFi-Interfaces
  - Bei unbekanntem WiFi bleibt das aktuelle Profil aktiv (kein automatischer Wechsel)
- **Profil-Editor Redesign**: 
  - Speichern/Abbrechen-Buttons jetzt unten statt oben für bessere Navigation
  - Quit/Settings/Close-Buttons während Bearbeitung ausgeblendet
  - Zentrierte Elemente (Icons, Farben, WiFi-Auswahl, Standardprofil-Checkbox)
  - Mehr Platz für Geräte-Listen (Fensterhöhe auf 800px erhöht)
  - Visuelle Separators zwischen den einzelnen Bereichen
  - Einheitliche Überschriften-Formatierung für bessere Übersicht
  - Farbcode-Legende ("Geräte-Prioritäten") über Output-Geräten positioniert
  - Erhöhter Abstand zwischen Blöcken für aufgeräumteres Layout
- **Deutsche Übersetzungen**: 
  - Konsistente Begriffe: "Geräte-Prioritäten", "Ausgabe-Geräte", "Eingabe-Geräte"
  - Farbcode-Legende vollständig auf Deutsch (Grün/Blau/Grau)
  - Erklärung für Standardprofil auf Deutsch

### Neu hinzugefügt

#### WiFi-basierter automatischer Profilwechsel
- **Automatischer Profilwechsel basierend auf WiFi-Netzwerk**: Profile können jetzt einem WiFi-Netzwerk (SSID) zugeordnet werden. Die App wechselt automatisch zum passenden Profil, wenn sich das verbundene WiFi-Netzwerk ändert.
- **WiFi-Auswahl im Profil-Editor**: Neues Dropdown-Menü im Profil-Editor zur Auswahl des WiFi-Netzwerks
  - Zeigt alle gemerkten WiFi-Netzwerke aus anderen Profilen
  - Zeigt aktuell verbundenes WiFi mit Icon und "(aktuell)" Markierung
  - Option "Kein WiFi" zum Entfernen der Zuordnung
- **Automatischer Wechsel zu Default-Profil**: Wenn ein unbekanntes WiFi-Netzwerk verbunden wird, wechselt die App automatisch zum Standard-Profil
- **Toggle für WiFi-basierten Wechsel**: Neue Einstellung in den Allgemein-Settings zum Ein/Ausschalten der automatischen WiFi-Erkennung
- **Location Services Integration**: 
  - Automatische Anfrage nach Location Services Berechtigung beim App-Start
  - UI-Hinweis mit Anleitung, wenn Berechtigung fehlt
  - Button zum manuellen Anfordern der Berechtigung
  - Button zum Öffnen der System Settings

#### Default-Profil Funktionalität
- **Standard-Profil setzen**: Profile können jetzt als Standard-Profil markiert werden
- **Checkbox im Profil-Editor**: "Als Standard-Profil verwenden" Checkbox zum Setzen des Default-Profils
- **Automatische Aktivierung**: Default-Profil wird automatisch aktiviert, wenn kein passendes WiFi-Profil gefunden wird

#### StatusBar Rechtsklick-Menü
- **Funktionierendes Kontextmenü**: Rechtsklick auf das StatusBar-Icon zeigt jetzt ein voll funktionsfähiges Menü
  - Anzeige des aktiven Profils
  - Schneller Profil-Wechsel direkt aus dem Menü
  - Einstellungen öffnen (funktioniert jetzt korrekt)
  - App beenden

### Design-Änderungen

#### Hauptansicht Redesign
- **Neue MainProfileView Struktur**: 
  - App-Title oben mit Divider
  - Content-Bereich in der Mitte mit flexibler Höhe
  - Bottom-Buttons (Quit App, Settings/Zurück, Close) fest am unteren Rand
  - Feste Breite von 520px für konsistente Darstellung
- **ProfileCardView Design**:
  - Große Emoji-Icons (32pt) für bessere Sichtbarkeit
  - Farbige Hintergründe basierend auf Profil-Farbe (20% Opacity)
  - Aktive Profile mit farbigem Rahmen (2pt) in Profil-Farbe
  - Edit- und Delete-Buttons rechts in jeder Karte
  - Tap-Geste zum Aktivieren von Profilen
- **Status-Info Bereich**:
  - Zeigt aktives Profil mit Icon und Name in Profil-Farbe
  - Zeigt aktive Input- und Output-Geräte
  - Statischer Bereich unter der scrollbaren Profil-Liste

#### Profil-Editor Redesign
- **Neuer Header-Bereich**:
  - Zurück-Button links mit Chevron-Icon
  - Titel "Profil bearbeiten" zentriert
  - Abbrechen- und Speichern-Buttons rechts
  - Klare visuelle Trennung mit Divider
- **Kompakte Emoji-Auswahl**:
  - Horizontale Anzeige aller verfügbaren Emojis
  - Ausgewähltes Emoji mit Accent-Farbe Hintergrund und Rahmen
  - 36x36pt Buttons für bessere Bedienbarkeit
- **Kompakte Farb-Auswahl**:
  - Farbkreise (28pt) mit Checkmark bei Auswahl
  - Primärfarbe-Rahmen für ausgewählte Farbe
  - Horizontale Anordnung für schnelle Auswahl
- **WiFi-Picker Verbesserungen**:
  - Aktuelles WiFi mit Icon und "(aktuell)" Markierung
  - Refresh-Button zum manuellen Aktualisieren
  - Automatische Aktualisierung alle 2 Sekunden
  - Warnung mit Anleitung bei fehlender Location Services Berechtigung
- **ScrollView für bessere Navigation**:
  - Alle Inhalte in einer scrollbaren Ansicht
  - Klare Sektionen mit Dividers
  - Farbcode-Erklärung am Ende

#### Settings-View
- **Separate Settings-Ansicht**:
  - Eigene ScrollView für alle Einstellungen
  - "Buy me a coffee" Button oben mit lila Tint
  - Strukturierte Sections mit "Allgemein" Überschrift
  - Dividers zur visuellen Trennung
  - App-Info und Version am Ende

### Geändert

- **Profile-Modell erweitert**: 
  - Neues optionales Feld `wifiSSID` für WiFi-Zuordnung
  - Neues Feld `isDefault` bereits vorhanden, jetzt mit UI-Unterstützung
- **ProfileManager erweitert**:
  - `setDefaultProfile()` - Setzt ein Profil als Standard
  - `getDefaultProfile()` - Gibt das Standard-Profil zurück
  - `getAllKnownWiFiSSIDs()` - Gibt alle gemerkten WiFi-SSIDs zurück
  - Automatischer Profilwechsel basierend auf WiFi-Verbindung
- **WiFiWatcher**: 
  - Automatische Überwachung von WiFi-Änderungen mit 2-Sekunden-Intervall
  - Wechselt automatisch zum passenden Profil bei WiFi-Änderung
  - Wechselt zum Default-Profil bei unbekanntem WiFi-Netzwerk
  - Respektiert den WiFi-Auto-Switch Toggle aus den Settings
- **WiFiManager**:
  - Abfrage der aktuellen WiFi-SSID über CoreWLAN Framework
  - Location Services Berechtigungsprüfung
  - Automatische Berechtigungsanfrage beim ersten Start
- **StatusBarController**: 
  - Rechtsklick-Menü-Funktionen repariert (target-Attribute hinzugefügt)
  - Settings-Öffnen über Rechtsklick-Menü funktioniert jetzt korrekt (Notification-basierte Kommunikation)
- **MainProfileView**: 
  - Komplettes Redesign mit neuer Struktur
  - Settings-Integration direkt in der View
  - ProfileCardView für bessere visuelle Darstellung
- **ProfileEditorView**: 
  - Neuer Header mit Navigation
  - Kompakte Emoji- und Farb-Auswahl
  - ScrollView für bessere Navigation
- **SettingsView**: 
  - Separate, scrollbare Settings-Ansicht
  - Strukturierte Sections mit Dividers

### Technische Details

#### Neue Dateien
- `WiFiManager.swift` - Singleton zur Abfrage der aktuellen WiFi-SSID über CoreWLAN
- `WiFiStore.swift` - UserDefaults-basierter Store für WiFi-Auto-Switch Einstellung
- `WiFiWatcher.swift` - Timer-basierte Überwachung mit automatischem Profilwechsel
- `AudioDeviceControl.entitlements` - Entitlements File mit Location Services Berechtigung

#### Abhängigkeiten
- **CoreWLAN Framework**: Für WiFi-SSID Abfrage
- **CoreLocation Framework**: Für Location Services Berechtigung
- **Location Services Capability**: Muss in Xcode aktiviert sein
- **Info.plist Key**: `NSLocationWhenInUseUsageDescription` wurde hinzugefügt

### Bekannte Einschränkungen

- **Location Services erforderlich**: WiFi-Erkennung benötigt Location Services Berechtigung (macOS Sicherheitsfeature)
- **Simulator**: WiFi-Erkennung funktioniert im Simulator oft nicht - Test auf echtem Mac empfohlen
- **Erste Berechtigung**: Beim ersten Start muss der Benutzer die Location Services Berechtigung erteilen

### Dokumentation

- `WIFI_SETUP.md` - Setup-Anleitung für WiFi-Funktion
- `LOCATION_PERMISSION_FIX.md` - Detaillierte Anleitung zur Location Services Berechtigung

