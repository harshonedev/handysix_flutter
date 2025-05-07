# 🏏 Hand Cricket Game MVP Development Plan

# HandySix (App Name)

## 🔰 Phase 1: Project Setup

### Step 1: Initialize Flutter Project

* Create a new Flutter project: `flutter create hand_cricket_game`
* Set up best-practice folder structure (see below).

### Step 2: Configure Firebase

* Create Firebase project on [Firebase Console](https://console.firebase.google.com)
* Add Android/iOS apps to Firebase project
* Configure `google-services.json` / `GoogleService-Info.plist`
* Enable Firebase Authentication (Google Sign-In)
* Set up Firestore and enable rules for development

### Step 3: Add Dependencies

Update `pubspec.yaml` with:

```yaml
firebase_core:
firebase_auth:
cloud_firestore:
flutter_riverpod:
flutter_google_sign_in:
go_router:
flutter_animate:
lottie:
uuid:
```

---

## 🧩 Phase 2: Authentication

### Step 4: Implement Google Sign-In

* Use `firebase_auth` + `google_sign_in` package
* Create `auth_service.dart` to handle login/logout
* Create `auth_provider.dart` using `flutter_riverpod` to manage auth state
* Redirect users to Home if authenticated, else to login screen

---

## 🎮 Phase 3: Game Modes

### Step 5: Single Player (vs Bot)

* Create `vs_bot_game_screen.dart`
* Implement basic hand cricket logic:

  * Player chooses number (1–6)
  * Bot randomly selects number
  * If same -> out; else -> runs += selected number
* Add basic score and out animations
* Show match summary (runs scored)

### Step 6: Multiplayer (Head-to-Head)

* Create `multiplayer_game_screen.dart`
* Implement matchmaking system:

  * Use Firestore queue collection
  * Pair players when two are waiting
  * Store match data in Firestore
* Create turn-based gameplay system using Firestore updates

---

## 📈 Phase 4: Stats & Leaderboard

### Step 7: Player Stats

* Create `stats_model.dart` to store:

  * Total Matches
  * Matches Won
  * Matches Lost
  * Total Runs
* Update stats after each match
* Display on `stats_screen.dart`

### Step 8: Global Leaderboard

* Create `leaderboard_service.dart`
* Fetch top players based on Total Runs / Wins
* Display using `leaderboard_screen.dart`

---

## 🤖 Phase 5: Bot Matchmaking

### Step 9: Auto-Bot Matchmaking

* When no players found in matchmaking queue:

  * Assign a bot as the second player
  * Proceed with AI-based gameplay
* Track these matches as part of stats

---

## ✨ Phase 6: Animations & UX

### Step 10: Add Animations

* Use `flutter_animate` or `lottie` for:

  * Run scored
  * Player out
  * Match won/lost
  * Loading/match found
* Add transitions between screens

---

## 🚀 Phase 7: Polish & Deployment

### Step 11: Finalize UI/UX

* Add consistent theming
* Make game responsive on different screens
* Polish all screens

### Step 12: Testing & Bug Fixes

* Test single player, multiplayer, leaderboard, stats
* Fix edge cases and sync issues

### Step 13: Build & Release

* Build APK / iOS build
* Test on real devices
* Release on Google Play Store / TestFlight

---

## ✅ Bonus (Post-MVP)

* Difficulty levels for bots
* Emojis / reactions during match
* Chat / Rematch options
* Weekly or country-wise leaderboard

---

## 🗂️ Best Flutter Project Structure

```bash
hand_cricket_game/
│
├── lib/
│   ├── main.dart                    # Entry point
│   ├── app.dart                     # Root widget and routing
│   ├── core/                        # Constants, themes, utilities
│   │   ├── constants.dart
│   │   ├── theme.dart
│   │   └── utils.dart
│   │
│   ├── services/                    # Firebase & game logic
│   │   ├── auth_service.dart
│   │   ├── firestore_service.dart
│   │   ├── game_service.dart
│   │   └── leaderboard_service.dart
│   │
│   ├── models/                      # Data models
│   │   ├── user_model.dart
│   │   ├── match_model.dart
│   │   ├── bot_model.dart
│   │   └── stats_model.dart
│   │
│   ├── providers/                   # Riverpod providers
│   │   ├── auth_provider.dart
│   │   ├── game_provider.dart
│   │   ├── bot_provider.dart
│   │   └── leaderboard_provider.dart
│   │
│   ├── screens/                     # UI screens
│   │   ├── auth/
│   │   │   └── login_screen.dart
│   │   ├── home/
│   │   │   └── home_screen.dart
│   │   ├── game/
│   │   │   ├── multiplayer_game_screen.dart
│   │   │   └── vs_bot_game_screen.dart
│   │   ├── leaderboard/
│   │   │   └── leaderboard_screen.dart
│   │   └── profile/
│   │       └── stats_screen.dart
│   │
│   ├── widgets/                     # Reusable UI components
│   │   ├── run_display.dart
│   │   ├── hand_button.dart
│   │   └── game_card.dart
│   │
│   ├── animations/                  # Lottie/Rive animations
│   │   ├── match_found_animation.dart
│   │   └── run_scored_animation.dart
│   │
│   └── routes/                      # go_router config
│       └── app_routes.dart
│
├── assets/
│   ├── images/
│   ├── animations/
│   └── sounds/
│
├── pubspec.yaml
├── firebase.json
├── .firebaserc
└── README.md
```
