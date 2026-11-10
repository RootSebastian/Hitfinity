# HITFINITY

[![Downloads](https://img.shields.io/github/downloads/RootSebastian/Hitfinity/total?label=downloads&labelColor=0A0E08&color=A6F511&style=flat-square)](https://github.com/RootSebastian/Hitfinity/releases)
[![License: MIT](https://img.shields.io/badge/license-MIT-A6F511?labelColor=0A0E08&style=flat-square)](LICENSE)
[![Platform](https://img.shields.io/badge/platform-Android%20%7C%20iOS%20(pending)-A6F511?labelColor=0A0E08&style=flat-square)](https://github.com/RootSebastian/Hitfinity/releases)

Offline-first fitness tracker — strength training, walking, body weight
and nutrition in one clean, fast app. No accounts, no cloud, no tracking:
all your data lives in a local database on your device.

![HITFINITY](site_shots/shot_mobile_full.png)

## Features

- **Strength training** — guided active-workout screen with set logging,
  rest timer, and draft recovery if the app closes mid-session
- **Plans** — weekly schedule of your workouts
- **Walking** — GPS-tracked outdoor walks with a live map and manual
  treadmill entries
- **Steps** — hardware step-counter integration with daily goals
- **Body weight & nutrition** — weight log, diet goals, food diary with
  macro breakdown
- **Summary dashboard** — calories, macros, streaks and weekly stats
- **Full theming** — Dark / AMOLED / Light modes and a runtime colour
  theme: pick any hue and the entire skin re-tints around it

## Installation

### From a release (Android, easiest)

1. Download `Hitfinity-v1.0.0-arm64.apk` from
   [Releases](https://github.com/RootSebastian/Hitfinity/releases)
   (arm64 covers virtually every modern phone; use `-arm32` on very old
   32-bit devices, `-x64` on emulators)
2. Open the file on your phone — Android will ask to allow installs from
   unknown sources for your browser/files app; allow it once
3. Install and train. No account, no setup.

Verify your download against the SHA-256 checksums in the release notes.

### From source (developers)

Requires the [Flutter SDK](https://docs.flutter.dev/get-started/install)
(3.x stable) with the Android toolchain set up:

```bash
git clone https://github.com/RootSebastian/Hitfinity.git
cd Hitfinity
flutter pub get
flutter run
```

The Drift database code (`lib/database/*.g.dart`) is committed, so no
code generation is needed for a normal build. If you change the database
schema in `app_database.dart`, regenerate with:

```bash
dart run build_runner build --delete-conflicting-outputs
```

Run the test suite:

```bash
flutter test
```

## Project structure

```
Hitfinity/
├── lib/
│   ├── main.dart                      # Entry point: loads settings, opens DB, runs app
│   ├── data/
│   │   ├── exercise_catalog.dart      # 75+ exercises with muscle groups
│   │   └── food_catalog.dart          # 160+ foods with macros
│   ├── database/
│   │   ├── app_database.dart          # Drift schema (9 tables)
│   │   ├── app_database.g.dart        # Generated Drift code
│   │   └── database_provider.dart     # Singleton DB access + queries
│   ├── models/
│   │   ├── models.dart                # Shared domain models
│   │   ├── workout_draft.dart         # In-progress workout draft (recovery)
│   │   └── walk_models.dart           # Walk session models
│   ├── screens/
│   │   ├── shell_screen.dart          # Bottom-nav shell + floating FAB dock
│   │   ├── home_screen.dart           # Train tab: greeting, resume banner
│   │   ├── plan_screen.dart           # Plan tab: weekly schedule
│   │   ├── active_workout_screen.dart # Live session: sets, rest timer
│   │   ├── summary_screen.dart        # Dashboard: calories, macros, streaks
│   │   ├── body_weight_screen.dart    # Body tab: weight log, food diary
│   │   ├── steps_screen.dart          # Steps tab: sensor, goals, history
│   │   ├── walk_screen.dart           # Walks: GPS map, treadmill entry
│   │   └── settings_screen.dart       # Theming, haptics, updates, about
│   ├── services/
│   │   ├── hit_settings.dart          # Persisted settings (ValueNotifiers)
│   │   ├── secure_launcher.dart       # HTTPS-only, allowlisted URL launcher
│   │   └── update_checker.dart        # GitHub Releases update checks
│   ├── theme/
│   │   ├── app_theme.dart             # Design tokens + full re-tint palette
│   │   ├── aurora_background.dart     # Ambient drifting glows (12 fps)
│   │   └── glass_card.dart            # Signature glass card widget
│   └── widgets/
│       ├── hit_widgets.dart           # Shared widget kit (rings, chips, tiles)
│       ├── exercise_library.dart      # Searchable exercise picker sheet
│       ├── exercise_tile.dart         # Exercise row with set counters
│       ├── primary_button.dart        # Gradient CTA button
│       ├── section_header.dart        # Section eyebrow + title
│       └── stat_card.dart             # Stat tile
├── test/
│   └── widget_test.dart               # SecureLauncher + theme tests
├── android/                           # Android platform files + launcher icons
├── ios/                               # iOS platform files (build requires macOS)
├── .github/workflows/
│   └── download-stats.yml             # Daily download-count snapshot
├── build_release.sh                   # Obfuscated release build script
├── flutter_launcher_icons.yaml        # App icon generation config
├── index.html                         # Marketing website
├── pubspec.yaml
└── LICENSE                            # MIT
```

## Tech stack

- **Flutter** (Material 3) with Space Grotesk via `google_fonts`
- **Drift** over local SQLite — all data stays on-device
- `geolocator` + `flutter_map` (OpenStreetMap tiles) for walks
- `pedometer` step sensor, `permission_handler` for runtime permissions
- `fl_chart` for charts, `shared_preferences` for settings
- `package_info_plus` + GitHub Releases API for in-app update checks

## Permissions

| Permission | Why |
|---|---|
| Activity recognition | Counting steps with the hardware sensor |
| Location (while walking only) | Measuring outdoor walk distance |
| Notifications | Walk-completion notices |
| Ignore battery optimizations | Keeps GPS tracking alive during long walks |

No permission is requested until you use the feature that needs it, and
walks work fully without location if you decline.

## Building a release

```bash
./build_release.sh
```

The script runs analysis + tests, then builds obfuscated, icon-tree-shaken
artifacts: split-ABI APKs for direct distribution and an `.aab` for the
Play Store. Back up `build/debug-symbols/` after every build — it is
required to symbolicate stack traces from obfuscated releases.

## Security & privacy

- **Offline-first** — no accounts, no analytics; the only network calls
  are OpenStreetMap map tiles on the walk screen, optional update checks
  and allowlisted external links
- **No secrets in source** — the repository contains no keys, tokens or
  credentials
- **Hardened external links** — every external URL passes an HTTPS-only,
  host-allowlisted launcher (`lib/services/secure_launcher.dart`)
- **Health data stays private** — workout, nutrition and weight data live
  in the app's private database; shared preferences holds only UI prefs

Report vulnerabilities by opening a private security advisory on GitHub
rather than a public issue.

## Download stats

A nightly GitHub Action snapshots release download counts into
`downloads/history.csv` and `downloads/snapshot.json` — the badge at the
top of this README updates automatically.

## Contributing

Issues and pull requests are welcome. Keep the codebase comment-light
and match the existing style.

## License

[MIT](LICENSE) — free to use, modify and distribute.

