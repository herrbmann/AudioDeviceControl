# AudioDeviceControl

![macOS](https://img.shields.io/badge/platform-macOS-000000)
![Swift](https://img.shields.io/badge/Swift-5.9-orange)
![Xcode](https://img.shields.io/badge/Xcode-15%2B-blue)
![License](https://img.shields.io/badge/License-MIT-green)

AudioDeviceControl is a lightweight macOS menu bar app that automatically selects your preferred audio input and output device — based on a priority list you define. No more AirPods chaos, wrong microphones, or constant switching.

## Screenshots

- Main Window (Prioritization & Status)
<img width="592" height="672" alt="SCR-20251204-qbyd" src="https://github.com/user-attachments/assets/fac85bea-3029-41be-bdeb-036208682484" />



## Overview

macOS tends to change the default microphone or default speakers when new devices are connected — even if you don't want it to. AudioDeviceControl fixes this for good with **Profiles**:

- **Create profiles** for different scenarios (Home, Work, Gaming, etc.) with custom names, emoji icons, and color accents
- **Customize device priorities** for each profile — sort your input and output devices by priority via drag & drop within each profile
- **Switch profiles** with a single click to instantly apply different audio configurations
- **Automatic activation** — as soon as the top-priority device in your active profile becomes available, it's activated automatically
- The app runs cleanly in the menu bar and updates live


---

## Features (V1)

- **Drag & drop prioritization** for input & output devices
- **Automatic switching** as soon as a higher-priority device becomes available
- **Status colors** for each device:
  - 🟢 active
  - 🔵 connected but not active
  - ⚪ offline
- **Live device detection** (devices appear/disappear dynamically)
- **Persistent storage** of priorities
- **Clean, minimal macOS UI**
- **No Dock icon**, menu bar–only app

Profile Editor


<img width="592" height="872" alt="SCR-20251204-qccd" src="https://github.com/user-attachments/assets/28791d1b-6e5c-4207-a293-e94c93aa38f5" />

<img width="592" height="872" alt="SCR-20251204-qcnt" src="https://github.com/user-attachments/assets/4e75032c-42e1-4c9b-92ee-c4d357b1c3d5" />




---

## New in version 1.3

### Automatic profile switching via Wi-Fi
Profiles can now be assigned to a Wi-Fi network. The app automatically switches to the matching profile as soon as the connected Wi-Fi network changes.

### Sound feedback
Optional audio feedback on profile switches. Configurable volume in the settings.

### Notifications
Push notifications inform you about automatic profile switches based on Wi-Fi connections.

### Device overview in profile cards
Each profile card now directly shows the active input and output devices – so you can see at a glance which hardware is active.

### Per-profile ignore list
Devices can now be ignored on a per-profile basis. Each profile manages its own list of ignored devices for maximum flexibility.

### Global device management
Devices can be completely removed from the app’s memory. They will reappear when reconnected, but remain hidden by default.

## Improvements

- Dark mode optimizations for better readability
- Centered volume control in the sound feedback section
- Improved UI consistency

---

## Requirements

- macOS 14+
- Xcode 15+
- Swift 5.9+
- CoreAudio.framework

---

## Installation:
Go to [releases](https://github.com/herrbmann/AudioDeviceControl/releases) and download the latest dmg.

## Please note:
This project started as a small hobby experiment—basically some vibe coding—because I couldn’t find any existing solution that worked the way I wanted. Since I’m not interested in paying €99 for an Apple developer certificate, the app isn’t code-signed. Because of that, macOS will block it the first time you try to open it.

If your Mac blocks the app, you can manually allow it:
System Settings → Privacy & Security → “Open Anyway
