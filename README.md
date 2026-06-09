# HeliPort
![image](Heliport/AppIcon-128.png)

Intel WiFi Client for [itlwm](https://github.com/OpenIntelWireless/itlwm)

## Status

HeliPort has been upgraded to **Version 3.0**, providing a state-of-the-art premium experience for Intel-based Macs. The app requires **macOS 13.0 (Ventura)** or newer and features a completely redesigned, high-fidelity user interface.

### New Features

- **📊 Advanced Telemetry**: Real-time signal strength history with high-frequency sampling (30 data points) and smoothed interpolation.
- **🔧 Technical Deep-Dive**: The dashboard now always displays critical technical metrics including PHY Mode, Channel/Bandwidth, BSSID, and Noise levels.
- **⚡️ Performance Optimized**: Rewritten UI components using modern SwiftUI patterns for minimal CPU impact while providing rich animations.
- **🪄 macOS Native**: Seamlessly integrated with the macOS menu bar, supporting all accessibility features and system-wide themes.

### 🏁 Development Status

- [x] Redesigned Dashboard
- [x] Implement always-available technical telemetry (Noise, PHY, Channel)
- [x] Enhance Signal Strength Charting (30 data points)
- [x] Update project version to 2.0
- [x] Optimized Intel-only (x86_64) Architecture

Visit [OpenIntelWireless project](https://github.com/OpenIntelWireless/HeliPort/projects) for more information.

## Issues

Issues for this project are for bug tracking only, please carefully fill in all the blanks in the correct Issue Template.

### Known harmless warning

When App Intents support is enabled, macOS may log `com.apple.linkd.autoShortcut` messages in Console.
These warnings are currently not fully avoidable and can be safely ignored.

### Invalid issues

The following types of "Issues" will be considered as invalid and will be closed and locked immediately:

- Personal help request
- Duplicated issues
- Urging updates
- Spam
- Non-English or non-Chinese content
- Easy "Googleable" questions
  > How to build etc.
- Off-topic discussion
  > Including mentioning and distributing closed-source, non-official Intel Wi-Fi Projects.

## Contributing

We desperately need contributors to help us improve this project, any help will be highly appreciated.

- User interface and password management is implemented with `Swift 5`
- Communication with [itlwm](https://github.com/OpenIntelWireless/itlwm) is implemented with `C`

## Credits

- [@1Revenger1](https://github.com/1Revenger1) for Keychain password management improvements
- [@Bat.bat](https://github.com/williambj1) for repository management and Sparkle integration
- [@diepeterpan](https://github.com/diepeterpan) for fixing UI artifacts on macOS Sonoma and performance optimizations
- [@DogAndPot](https://github.com/DogAndPot) for initial UI implementation
- [@ErrorErrorError](https://github.com/ErrorErrorError) for UI improvement, Preference Window implementation and more
- [@Goshin](https://github.com/Goshin) for API implementation, Status Menu improvements and more
- [@igorkulman](https://github.com/igorkulman) for code refactoring, password management and more
- [@zxystd](https://github.com/zxystd) for writing [itlwm](https://github.com/OpenIntelWireless/itlwm) and APIs
- [Everyone](https://github.com/OpenIntelWireless/HeliPort/pulls?q=is%3Apr+label%3Adocumentation+is%3Aclosed) who contributed to localization files
- Primary UI icons use Apple's **SF Symbols** (Native macOS 13+ interface)
- Legacy WiFi icons are from <https://icons8.com/> (No longer used by default)
- Modern WiFi icons are from <https://github.com/framework7io/framework7-icons> (MIT License) (No longer used by default)
