
# Hitfinity 🔥

A cross-platform fitness tracker built with **Flutter**, running natively on
**Android** and **Linux desktop** from a single codebase.

Hitfinity is a complete training companion: log every set of every workout,
plan your training week, track walks with live GPS mapping, monitor your
diet and hydration, watch your body-weight trend, and see it all summarized
on one dashboard.

![Platform](https://img.shields.io/badge/platform-Android%20%7C%20Linux-blue)
![Framework](https://img.shields.io/badge/framework-Flutter-orange)
![Database](https://img.shields.io/badge/storage-Drift%20%2F%20SQLite-green)

---

## ✨ Features

### 🏋️ Workout Tracking
- **Live session mode** — a running timer, then tap-to-log sets from a
  75+ exercise catalog with smart defaults (your last weight/reps
  pre-filled)
- **Per-exercise cards** — sets grouped by exercise, expandable rows,
  tap any set to edit its reps/weight mid-workout
- **Sessions survive restarts** — log a set, switch apps, even force-kill
  Hitfinity: a "Session in progress" card is waiting on Home, timer intact
- **Edit past sessions** — tap any session in history to add missed sets
  or fix mistakes; original date and duration are preserved
- **Weight, reps, or bodyweight** — barbell/dumbbell/machine/cable/
  kettlebell equipment types, weighted bodyweight (weighted pull-ups),
  and pure bodyweight exercises are all first-class
- **Weekly activity strip** — Mon–Sun dots showing which days you trained

### 📅 Weekly Planner
- Assign exercises to days of the week ("Monday = chest day") once, and
  every week your list is ready
- On a scheduled day, the workout screen shows **Today's Plan** as
  tap-to-log chips — your whole session is one tap per exercise away
- Chips check off with set counts as you complete each planned exercise

### 🚶 Walks & Steps
- **GPS mode** — live route drawn on an OpenStreetMap map, real-time
  distance from actual GPS points, auto-follow with a re-center button
- **Background-safe tracking** — a foreground service keeps the route
  recording while you use other apps or lock the screen
- **Treadmill mode** — GPS can't see you indoors; enter what the treadmill
  displays (more accurate than any sensor)
- **Step counting** — hardware pedometer with a daily goal ring, persisted
  baseline so your count survives app restarts and day rollovers
- **Custom step goals** — slider + presets (5k / 8k / 10k / 12k / 15k)

### ⚖️ Body
- **Weight tracking** — quick-add bar, animated current-weight hero,
  delta pills on every entry, and a trend line chart over time
- **Diet tracking** — 160+ food catalog (including Indian staples:
  roti, dal, paneer, momos, biryani…) with per-100g macros, smart
  serving presets ("1 large egg (50g)", "1 scoop (30g)"), live macro
  preview before you log, and a quick-add mode for unknown foods
- **Macro goals** — customizable calorie / protein / carb / fat targets
  with progress bars
- **Water intake** — one-tap glass/bottle/large logging, custom amounts,
  daily goal with progress bar and per-entry history

### 📊 Summary Dashboard
- **Day and Week views** with an editorial verdict headline
  ("Full house." / "Killing it." / "Clean slate.")
- Training, movement, nutrition, and body cards — all live-updating
- Weekly calorie bar chart with a dashed goal line, today highlighted

### 🎨 Design
- Dark-first design system: one accent color, flat surfaces, hairline
  borders, editorial typography (Sora + Inter), tabular numerals
- Haptic feedback on key actions
- Adaptive navigation: bottom bar on phones, side rail on desktop

---

## 🚀 Getting Started

### Prerequisites

| Tool | Why | Install |
|---|---|---|
| Flutter SDK (3.x stable) | The framework | [flutter.dev/docs/get-started/install/linux](https://docs.flutter.dev/get-started/install/linux) |
| Android Studio | Android SDK + device tooling | [developer.android.com/studio](https://developer.android.com/studio) |
| Linux build tools | Compiling the desktop target | see below |
| A physical Android phone | GPS/step features only work on-device | — |

Install the Linux desktop build dependencies:

```bash
sudo apt install clang cmake ninja-build pkg-config libgtk-3-dev \
  curl git unzip xz-utils zip libglu1-mesa
```

### Installation

```bash
# 1. Clone
git clone git@github.com:RootSebastian/Hitfinity.git
cd Hitfinity

# 2. Install Dart/Flutter packages
flutter pub get

# 3. Generate the database code (Drift codegen)
dart run build_runner build

# 4. Check your setup
flutter doctor
```

### Running

**On Linux desktop:**

```bash
flutter run -d linux
```

**On an Android phone:**

1. Enable **Developer options** on your phone
   (Settings → About phone → tap "Build number" 7 times)
2. Enable **USB debugging** (Settings → Developer options)
3. Connect via USB and authorize the computer
4. Verify: `flutter devices` — your phone should be listed
5. Run:

```bash
flutter run
```

**First-run permissions on Android** (each appears when first needed):

- **Location** (while using the app) → GPS walks
- **Physical activity** → step counting
- **Notifications** → the background-walk tracking notification
- **Battery optimization exemption** → keeps long GPS walks recording

### Building a release APK

```bash
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```

Install it directly: `flutter install`

---

## 🗂 Project Structure

```
lib/
├── main.dart                      # App entry point, theme + dark mode setup
│
├── database/
│   ├── app_database.dart          # Drift database: tables, migrations,
│   │                              #   and all queries (streams & futures)
│   └── database_provider.dart     # Singleton access to the DB instance
│
├── models/
│   ├── models.dart                # Exercise / SetLog / WorkoutSession
│   │                              #   (workout-domain classes)
│   ├── walk_models.dart           # WalkSession / GeoPoint / walk modes
│   └── workout_draft.dart         # In-progress session persistence model
│
├── data/
│   ├── exercise_catalog.dart      # 75+ exercises: muscle groups, equipment
│   │                              #   types, icons, muscle-group colors
│   └── food_catalog.dart          # 160+ foods: macros per 100g,
│                                  #   categories, serving presets
│
├── screens/
│   ├── shell_screen.dart          # App shell: adaptive nav (bottom bar /
│   │                              #   side rail) + tab switching
│   ├── home_screen.dart           # Train tab: hero, week strip, session
│   │                              #   cards, resume/discard banner
│   ├── active_workout_screen.dart # Live workout: timer, today's plan
│   │                              #   chips, set logging, edit mode
│   ├── plan_screen.dart           # Weekly planner: day selector,
│   │                              #   scheduled exercise lists
│   ├── steps_screen.dart          # Steps: goal hero, pedometer,
│   │                              #   walk history
│   ├── walk_screen.dart           # GPS/treadmill tracking: live map,
│   │                              #   route polyline, foreground service
│   ├── body_weight_screen.dart    # Body tab: Weight | Diet | Water
│   │                              #   segmented views
│   └── summary_screen.dart        # Day/Week dashboard across all domains
│
├── theme/
│   ├── app_theme.dart             # Design system: colors, typography
│   │                              #   (Sora/Inter), component themes
│   ├── glass_card.dart            # Card primitive: flat surface +
│   │                              #   hairline border
│   └── aurora_background.dart     # Subtle ambient-light hero background
│
└── widgets/
    ├── exercise_library.dart      # Searchable/filterable exercise list
    │                              #   (embedded in workout + planner)
    └── exercise_tile.dart         # Single exercise row with muscle-
                                   #   colored icon + done badge
```

**Layering:** `screens/` (UI) → `database/` + `data/` (state & queries) →
`models/` (domain types). All data flows through **Drift streams** — every
screen auto-refreshes when its underlying tables change, with no manual
`setState` wiring between screens.

**Database:** 9 tables (exercises, workout sessions, set logs, walk
sessions, body weights, food entries, water entries, scheduled exercises,
settings) with versioned migrations — schema updates never wipe user data.

---

## 🛠 Built With

| Package | Role |
|---|---|
| [Flutter](https://flutter.dev) | UI framework, Android + Linux from one codebase |
| [Drift](https://drift.simonbinder.eu) | Type-safe reactive SQLite layer |
| [flutter_map](https://docs.fleaflet.dev) + OpenStreetMap | Free, keyless live mapping |
| [Geolocator](https://pub.dev/packages/geolocator) | GPS streams + foreground service |
| [Pedometer](https://pub.dev/packages/pedometer) | Hardware step counting |
| [fl_chart](https://pub.dev/packages/fl_chart) | Weight trend & calorie bar charts |
| [google_fonts](https://pub.dev/packages/google_fonts) | Sora + Inter typography |

---

## 📝 License

All rights reserved (for now).

---

*Built as a personal project. PRs and issues welcome once it stabilizes.*




