# AudioDeviceControl

AudioDeviceControl is a lightweight macOS menu bar app that automatically selects your preferred audio input and output device — based on a priority list you define. No more AirPods chaos, wrong microphones, or constant switching.

> Tip: Add your own images in the "Screenshots" section below when you’re ready.

---

## Screenshots

<!-- Replace these placeholders with your real images/links -->

- Main Window (Prioritization & Status)

![Main Window](https://github.com/user-attachments/assets/625a015b-da24-4d80-ac8a-d1aec87fd185)

- Menu Bar Status

![Menu Bar](https://placehold.co/600x200?text=Menu+Bar+Status)

---

## Overview

macOS tends to change the default microphone or default speakers when new devices are connected — even if you don’t want it to. AudioDeviceControl fixes this for good:

- Sort your input and output devices by priority via drag & drop.
- The app persistently saves your order.
- As soon as the top-priority device is available, it’s activated automatically.
- The app runs cleanly in the menu bar and updates live.

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

---

## New in this version

- More reliable detection of input/output capabilities per device (CoreAudio-based)
- More robust retrieval of default devices (input & output) and faster switching
- Improved logs for easier debugging of rare CoreAudio errors
- Clean singleton architecture for device management

> Technical note: The app uses `CoreAudio` and `AudioObjectGetPropertyData`/`AudioObjectSetPropertyData` to efficiently query/set device lists, default devices, and stream capabilities.

---

## Requirements

- macOS 13+
- Xcode 15+
- Swift 5.9+
- CoreAudio.framework

---

## Installation (Development)

```bash
git clone https://github.com/YOURNAME/AudioDeviceControl.git
cd AudioDeviceControl
open AudioDeviceControl.xcodeproj
