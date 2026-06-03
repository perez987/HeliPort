# DIFFS WITH SOURCE REPO

Comparison target: `https://github.com/joshcalvert47/HeliPort`  
Important repo: `perez987/HeliPort`

## Fork-only differences (present in `perez987/HeliPort`, not in source)

### App startup and project structure
- Added programmatic app entrypoint via `HeliPort/main.swift`.
- Removed `HeliPort/Appearance/Base.lproj/MainMenu.xib`.
- Removed `NSMainNibFile` usage from `HeliPort/Info.plist`.
- Removed `@NSApplicationMain` usage in `HeliPort/AppDelegate.swift`.

### Preferences and runtime behavior
- Added a new preference to auto-close HeliPort after a configurable delay (`HeliPort/Appearance/Preferences/PrefsGeneralView.swift`).
- Refactored preferences window implementation with major simplification (`HeliPort/Appearance/Preferences/PrefsWindow.swift`).
- Updated preferences-related behavior in:
  - `HeliPort/Appearance/Preferences/PrefsSavedNetworksView.swift`
  - `HeliPort/Appearance/Preferences/PrefsModifyWiFiModal.swift`

### Status menu and UI internals
- Updated status menu implementation and wiring in:
  - `HeliPort/Appearance/StatusMenu/StatusMenuBase.swift`
  - `HeliPort/Appearance/StatusMenu/StatusMenuModern.swift`
  - `HeliPort/Appearance/StatusMenu/StatusMenuLegacy.swift`
  - `HeliPort/Appearance/StatusMenu/MenuItemView/WiFiMenuItemViewModern.swift`
  - `HeliPort/Appearance/StatusMenu/NetworkDetailsDashboard.swift`
- Minor UI compatibility updates in:
  - `HeliPort/Appearance/ModernWiFiConfigView.swift`
  - `HeliPort/Appearance/WiFiConfigWindow.swift`

### Localization and resources
- Large update to localized strings bundle: `HeliPort/Appearance/Localizable.xcstrings`.
- Replaced app icon asset set contents:
  - Added: `AppIcon_64.png`, `AppIcon_128.png`, `AppIcon_256.png`, `AppIcon_512.png`
  - Removed: `icon_128x128.png`, `icon_128x128@2x.png`
- Updated app icon manifest: `HeliPort/Assets.xcassets/AppIcon.appiconset/Contents.json`.

### Tooling, repo config, and project metadata
- Added SwiftLint config: `.swiftlint`.
- Added project AI guidance file: `CLAUDE.md`.
- Updated ignore rules: `.gitignore`.
- Updated Xcode project configuration:
  - `HeliPort.xcodeproj/project.pbxproj`
  - `HeliPort.xcodeproj/xcshareddata/xcschemes/HeliPort.xcscheme`
  - `HeliPort.xcodeproj/xcuserdata/yo.xcuserdatad/xcschemes/xcschememanagement.plist`

### Removed from fork vs source
- Removed GitHub issue templates:
  - `.github/ISSUE_TEMPLATE/bug_report.yml`
  - `.github/ISSUE_TEMPLATE/config.yml`
- Removed GitHub workflows:
  - `.github/workflows/main.yml`
  - `.github/workflows/jekyll-gh-pages.yml`

### Logging behavior change
- Removed prior log system usage and replaced logging calls with `print`-based output in modified Swift sources.
