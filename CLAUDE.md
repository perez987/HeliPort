# CLAUDE.md

This file provides context and guidance for AI agents working in this repository.

## Project Overview

**HeliPort 2** is a macOS menu bar application that serves as the Wi-Fi client for Intel wireless cards using the [itlwm](https://github.com/OpenIntelWireless/itlwm) kernel extension. It is a fork of the original [OpenIntelWireless/HeliPort](https://github.com/OpenIntelWireless/HeliPort) project upgraded to version 2.0.

- **Language**: Swift 5.0 (UI/app logic) + C (kernel communication via `ClientKit`)
- **Minimum macOS**: 13.0 (Ventura)
- **Architecture**: x86_64 (Intel only)
- **Auto-update**: Sparkle framework

## Repository Structure

```
HeliPort/                  # Main application target (Swift)
  AppDelegate.swift        # App entry point
  NetworkManager.swift     # Wi-Fi network management
  CredentialsManager.swift # Keychain password management
  UpdateManager.swift      # Sparkle update logic
  LoginItemManager.swift   # Launch-at-login
  Supporting files/        # Extensions, utilities, logging
  *.lproj/                 # Localization files (20+ languages)
HeliPort Launcher/         # Launcher helper target (Swift)
ClientKit/                 # C bridge for itlwm ioctl communication
  Api.c / Api.h            # API implementation
  Common.h / IoctlId.h     # Shared types and ioctl IDs
HeliPort.xcodeproj/        # Xcode project
.swiftlint.yml             # SwiftLint configuration
```

## Build

Build with Xcode or via command line:

```bash
xcodebuild -project HeliPort.xcodeproj \
           -scheme HeliPort \
           -derivedDataPath build
```

The project has two targets: **HeliPort** (main app) and **HeliPort Launcher** (login item helper).

## Linting

[SwiftLint](https://github.com/realm/SwiftLint) is configured in `.swiftlint.yml`. Run it from the repository root:

```bash
swiftlint
```

Key SwiftLint settings:
- `SourcePackages` and `build` directories are excluded
- `function_body_length`, `type_body_length`, `file_length`, and `cyclomatic_complexity` rules are disabled
- `identifier_name` allows `_` as a symbol

## Key Conventions

- Swift files follow standard macOS/Cocoa patterns with `@NSApplicationMain` and `NSApplicationDelegate`
- License header in every Swift file: 3-Clause BSD License
- Localized strings are managed through `.lproj` directories; do not hard-code user-facing strings
- The C layer (`ClientKit`) communicates with the itlwm kext via ioctl — avoid modifying without understanding the kext API
- No GitHub Actions workflow file currently exists in the repository; CI build commands come from external infrastructure
