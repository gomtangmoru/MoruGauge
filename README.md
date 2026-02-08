# ⚡ MoruGauge

A lightweight macOS menu bar app that monitors your charger and battery in real time.

![macOS 13+](https://img.shields.io/badge/macOS-13%2B-blue)
![Swift](https://img.shields.io/badge/Swift-5.9-orange)
![License](https://img.shields.io/badge/license-MIT-green)

> 🇰🇷 [한국어 README](README-ko.md)

---

## Features

### 🔌 Charger Detection & Notifications
- Instant notification when a charger is connected or disconnected
- Detailed follow-up notification with **Wattage / Voltage / Amperage** (after USB-PD negotiation)
- Configurable: enable/disable connect/disconnect/detailed notifications independently
- Silent mode option

### 📊 Real-Time Menu Bar Monitoring
- Current charging wattage displayed next to the menu bar icon
- Click to see detailed power information:

**When Charging:**
| Item | Example |
|------|---------|
| Charger Status | ⚡ Charging / ⏸️ Not Charging / ✅ Fully Charged |
| Adapter Max | 96W |
| Charging Power | 45.2W |
| Voltage | 20.15V |
| Amperage | 2.24A |
| Adapter Details | USB-C 20.0V 3.0A |
| System Power | ~12.5W (estimated) |

**On Battery:**
| Item | Example |
|------|---------|
| Battery Level | 78% |
| Battery Health | 87% |
| Cycle Count | 446 |
| Temperature | 30.8°C |
| Time Remaining | 7h 11m |
| System Power | 8.3W |

- Values update in real time **even while the menu is open**
- Unavailable values display `--`

### ⚙️ Customizable Settings
- **Update interval**: 1–30 seconds
- **Toggle each menu item** independently (charging info / battery info sections)
- **Notification controls**: connect, disconnect, detailed info, silent mode

### 🌐 Localization (JSON-based)
- Built-in: **English**, **한국어**, **한국어 (냥냥체)**
- Add your own language by dropping a `.json` file into the Locales folder
- Existing translations are preserved on update — only missing keys are merged

---

## Installation

### Build from Source

**Requirements:** macOS 13+ and Xcode Command Line Tools

```bash
git clone https://github.com/YOUR_USERNAME/morugauge.git
cd morugauge
chmod +x build.sh
bash build.sh
```

The built app will be at `build/morugauge.app`.

### Run

```bash
open build/morugauge.app
```

Or drag `morugauge.app` to your Applications folder.

> The app runs in the menu bar only (no Dock icon).

---

## How It Works

MoruGauge reads power data directly from macOS's **IOKit** framework (`AppleSmartBattery` service), which provides:

- Battery voltage, amperage, capacity, health, cycle count, temperature
- Charger details via `AppleRawAdapterDetails` (wattage, voltage, amperage)
- Power source change events via `IOPSNotificationCreateRunLoopSource`

**System Power Estimation:**
- On battery: calculated from `Voltage × Amperage` (accurate when > 2W)
- While charging: estimated as `Adapter Output − Battery Charging Power`

---

## Adding a Translation

1. Open **Settings → Translations → Open Translations Folder**
   - Or navigate to `~/Library/Application Support/morugauge/Locales/`
2. Copy an existing `.json` file (e.g., `en-us.json`) and rename it (e.g., `ja-jp.json`)
3. Translate the values (keep the keys unchanged)
4. Restart the app — the new language appears in Settings

Example structure:
```json
{
    "language.name": "日本語",
    "menu.charger_connected": "🔌 充電器接続済み",
    "menu.charging": "⚡ 充電中",
    ...
}
```

---

## Project Structure

```
morugauge/
├── Sources/
│   ├── main.swift                 # App entry point
│   ├── AppDelegate.swift          # Lifecycle & notification permissions
│   ├── Settings.swift             # UserDefaults-backed settings model
│   ├── LocalizationManager.swift  # JSON-based i18n system
│   ├── PowerMonitor.swift         # IOKit power monitoring + notifications
│   ├── StatusBarController.swift  # Menu bar UI management
│   └── SettingsWindow.swift       # SwiftUI settings window
├── Resources/
│   ├── Info.plist                 # App bundle configuration
│   └── Locales/
│       ├── en-us.json             # English
│       ├── ko-kr.json             # Korean
│       └── ko-nyang.json          # Korean (Nyang style 🐱)
├── Package.swift                  # Swift Package Manager config
└── build.sh                       # Build & bundle script
```

---

## License

MIT License — feel free to use, modify, and distribute.

---

## Acknowledgments

This project was built entirely through **vibe coding** with AI (Claude) — from architecture to implementation.

Built with Swift, AppKit, SwiftUI, and IOKit on macOS.

