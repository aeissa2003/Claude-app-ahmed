# ProteinChef

A high-protein-focused iOS app for tracking the recipes you cook and the workouts you train.

> **Status:** Phase 2 complete — auth (Apple / Google / Email) + 6-step onboarding. Working on branch `claude/protein-recipe-workout-app-AcpUP`.

## What it does

- **Sign up** with Apple, Google, or email.
- **Onboard** with bodyweight, height, age, sex, goal (cut/bulk/maintain), dietary restrictions, and a daily protein target.
- **Add recipes** — title, instructions, cover photo + gallery, prep/cook time, servings, tags. Pick ingredients from a seeded database (full macros per 100g) or add custom. Optionally photograph each ingredient you used.
- **Log meals** — log a saved recipe × servings, or an ad-hoc food (auto-filling macros from the ingredient database when possible).
- **Daily dashboard** — protein, carbs, fat, calories vs goal. High-protein recipe suggestions ranked by how well they fit your remaining daily protein.
- **Log workouts** — pick from a seeded exercise library or add custom. Log each set's weight and reps individually. Save reusable workout templates and start new sessions from them.
- **Friends feed** — mutual-accept friends. Post a recipe to friends; they can like, comment, and save an editable copy (with "adapted from @friend" attribution). Push notifications for friend requests and feed activity.

## Tech stack

- **Swift 5.9 / SwiftUI**, iOS 17+
- **Firebase**: Auth, Firestore, Storage, Cloud Messaging
- **XcodeGen** for generating the Xcode project from `project.yml`
- **Swift Package Manager** for dependencies

## Setup (requires macOS + Xcode 15+)

### 1. Install toolchain

```sh
brew install xcodegen
```

### 2. Generate the Xcode project

```sh
xcodegen generate
open ProteinChef.xcodeproj
```

This produces `ProteinChef.xcodeproj` from `project.yml`. The `.xcodeproj` is git-ignored — always regenerate after pulling changes to `project.yml` or adding/removing source files.

### 3. Create the Firebase project

1. Go to <https://console.firebase.google.com/> and create a new project (e.g. `proteinchef`).
2. Add an **iOS app** with bundle ID `com.example.proteinchef` (match `project.yml`; change both if you rename).
3. Download `GoogleService-Info.plist` and drop it into `ProteinChef/App/` (git-ignored on purpose).
4. In the Firebase console, enable:
   - **Authentication** → Sign-in methods → **Apple**, **Google**, **Email/Password**
   - **Firestore Database** (production mode)
   - **Storage**
   - **Cloud Messaging** (for push notifications)

### 4. Deploy Firestore & Storage rules

```sh
npm install -g firebase-tools
firebase login
firebase use --add    # select your project, alias it "default"
firebase deploy --only firestore:rules,firestore:indexes,storage
```

See `/Firebase/firestore.rules`, `/Firebase/storage.rules`, and `/Firebase/firestore.indexes.json`.

### 5. Seed the global catalogs

The seed data lives in `/Seed/ingredients.json` and `/Seed/exercises.json`. A one-off script (coming in a later phase) will upload them to the `ingredients/` and `exercises/` collections. For now, you can manually import via the Firebase console.

### 6. Configure signing

In Xcode → project settings → **Signing & Capabilities**:
- Pick your Apple ID team (personal team is fine for simulator + device testing without a paid developer account).
- Ensure **Sign in with Apple**, **Push Notifications**, and **Background Modes → Remote notifications** capabilities are present (they're declared in `project.yml`).
- For Google Sign-In, copy the `REVERSED_CLIENT_ID` from `GoogleService-Info.plist` into the URL Types (also wired via `project.yml`).

### 7. Build & run

Pick the **ProteinChef** scheme and an iOS 17+ simulator or your personal device.

## Repo layout

```
/project.yml                     XcodeGen spec
/ProteinChef/
  App/                           App entry, RootView, DI
  Features/
    Auth/ Onboarding/ Recipes/ Ingredients/ MealLog/
    Dashboard/ Workouts/ Feed/ Friends/ Settings/
  Core/
    Models/                      Codable domain types
    Services/                    Auth, Firestore, Storage, Push
    Repositories/                Per-feature data access
    DesignSystem/                Colors, typography, components
    Utilities/                   Unit conversion, macro math, suggestions
/Seed/                           ingredient + exercise JSON
/Firebase/                       Firestore + Storage rules + indexes
```

## Phased build plan

1. **Phase 1 — Scaffold (this PR).** Project structure, models, service protocols, seeded catalogs (initial subset), security rules stubs, README.
2. **Phase 2 — Auth + Onboarding.** Sign in with Apple / Google / Email. Onboarding questionnaire. User profile persistence.
3. **Phase 3 — Recipes.** Ingredient picker, recipe CRUD, image upload, macro computation.
4. **Phase 4 — Meal log + Dashboard + Suggestions.** Meal log UI, daily dashboard, high-protein recipe suggestions.
5. **Phase 5 — Workouts.** Exercise picker, per-set weight/reps logger, templates.
6. **Phase 6 — Friends + Feed.** Friend requests, mutual accept, post-recipe-to-feed, likes, comments, save-a-copy.
7. **Phase 7 — Push notifications.** FCM registration, server-side Cloud Function triggers for friend requests + feed interactions.
8. **Phase 8 — Hardening.** Full Firestore/Storage security audit, edge cases, release checklist.

## Out of scope for v1

Progress photos, body measurements tracking, rest timers, RPE/RIR per set, supersets, public discovery feed. These can come after v1 ships.
