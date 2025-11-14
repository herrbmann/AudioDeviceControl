# AudioDeviceControl

AudioDeviceControl is a lightweight macOS menu-bar app that automatically switches your audio input & output devices based on a user-defined priority list.  
It keeps your preferred microphone and speakers active — no matter what you plug in.

---

## 🎧 Features

- **Drag & Drop Priority Lists**  
  Order both input and output devices simply by dragging them into your preferred priority.

- **Automatic Device Switching**  
  When a higher-priority device becomes available, AudioDeviceControl selects it instantly.

- **Smart Device Detection**  
  Shows connected, active, and offline devices with clear status colors:
  - 🟢 Active device  
  - 🔵 Connected but inactive  
  - ⚪ Offline / not available  

- **Menu Bar Interface**  
  Clean popup UI — no dock icon, no clutter.

- **Persistent Preferences**  
  Priority lists are saved and restored across app launches.

---

## 🛠 Requirements

- macOS 13.0+
- Xcode 15+
- Swift 5.9+
- CoreAudio.framework

---

## 🚀 Installation (Development)

Clone the repository:

```sh
git clone https://github.com/DEINUSERNAME/AudioDeviceControl.git
cd AudioDeviceControl
open AudioDeviceControl.xcodeproj
