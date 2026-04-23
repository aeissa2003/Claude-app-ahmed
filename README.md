# ProteinChef

A high-protein-focused iOS app for tracking the recipes you cook, the meals you eat, the workouts you train, and what your friends are cooking.

> **Status:** All 8 phases complete. Phase 9 (TikTok recipe import agent) is scoped but unshipped.

## What it does

- **Sign up** with Apple, Google, or email.
- **Onboard** with bodyweight, height, age, sex, goal (cut/bulk/maintain), dietary restrictions, handle, and a daily protein target.
- **Add recipes** — title, instructions, cover photo + gallery, prep/cook time, servings, tags. Pick ingredients from a seeded database (full macros per 100g) or add custom. Optionally photograph each ingredient you used.
- **Log meals** — log a saved recipe × servings, or an ad-hoc food (auto-filling macros from the ingredient database when possible).
- **Daily dashboard** — protein, carbs, fat, calories vs goal. High-protein recipe suggestions ranked by how well they fit your remaining daily protein.
- **Log workouts** — pick from a seeded exercise library or add custom. Log each set's weight and reps individually. Save reusable workout templates and start new sessions from them.
- **Friends feed** — mutual-accept friends, exact-handle search. Share a recipe; friends can like, comment, and save an editable copy (with "adapted from @friend" attribution).
- **Notifications** — in-app inbox with badge count + APNs pushes for friend requests, accepts, new posts, likes, and comments.
- **Settings** — sign out, sign-in management, and fully-compliant account deletion that wipes your data and frees your handle.

## Tech stack

- **Swift 5.9 / SwiftUI**, iOS 17+
- **Firebase** iOS SDK: Auth, Firestore, Storage, Cloud Messaging
- **Firebase Cloud Functions** (Node 20 / TypeScript) for notification fan-out
- **XcodeGen** generates `ProteinChef.xcodeproj` from `project.yml`
- **Swift Package Manager** for iOS deps

## Repository layout

```
ProteinChef/              Swift app sources
  App/                    entry point, root view, tab shell, assets
  Core/                   models, services, repositories, catalogs
  DesignSystem/           theme, shared UI primitives
  Features/               one folder per product area (Auth, Onboarding, Dashboard, Recipes, Workouts, Feed, Notifications, Settings)
ProteinChefTests/         unit tests
Seed/                     bundled JSON catalogs (ingredients, exercises)
Firebase/
  firestore.rules         production Firestore rules
  firestore.indexes.json  composite index definitions
  storage.rules           production Storage rules
  firebase.json           deploy config
  .firebaserc             project alias
  functions/              Cloud Functions (TypeScript, Node 20)
project.yml               XcodeGen config
```

## Setup (requires macOS + Xcode 15+)

### 1. Install toolchain

```sh
brew install xcodegen node
npm install -g firebase-tools
```

### 2. Generate the Xcode project

```sh
xcodegen generate
open ProteinChef.xcodeproj
```

Regenerate after pulling changes to `project.yml` or adding/removing source files. `.xcodeproj` is git-ignored.

### 3. Create the Firebase project

1. Go to the [Firebase console](https://console.firebase.google.com/) → **Add project**.
2. Add an **iOS app** with bundle id `com.example.proteinchef` (or whatever you set in `project.yml`).
3. Download `GoogleService-Info.plist` and drop it into `ProteinChef/App/` in Xcode (check "Copy items if needed", target: ProteinChef).
4. In the plist, copy the value of `REVERSED_CLIENT_ID`. Open `ProteinChef/App/Info.plist` and replace `REPLACE_WITH_REVERSED_CLIENT_ID` in the URL Schemes array.
5. Enable these services in the console:
   - **Authentication** → Sign-in method → enable Email/Password, Google, Apple.
   - **Authentication** → Settings → User actions → disable **Email enumeration protection** (lets the app show "create account" vs "wrong password" correctly).
   - **Firestore Database** → Create database → production mode → same region as you plan to host Functions (e.g. `europe-west1`, `us-central1`).
   - **Storage** → Get started → production mode → same region as Firestore.
   - **Cloud Messaging** — needs an APNs key:
     - Apple Developer account → Certificates, Identifiers & Profiles → Keys → create a new key with APNs enabled → download the `.p8`.
     - Firebase Console → Project settings → Cloud Messaging → Apple app configuration → upload the `.p8`, key ID, team ID.

### 4. Deploy rules, indexes, and Cloud Functions

From the repo root:

```sh
cd Firebase
firebase login
firebase use proteinchef-fd457   # or your project id; update .firebaserc to match

# Rules + indexes (free tier)
firebase deploy --only firestore:rules,firestore:indexes,storage

# Cloud Functions (Blaze plan required)
cd functions
npm install
npm run build
firebase deploy --only functions
```

Composite indexes take 1–3 minutes to build. Watch progress in the Firebase console → Firestore → Indexes.

### 5. Build and run

Pick an iPhone simulator (iOS 17+) in Xcode and press ⌘R.

#### Testing on a physical device

Sideloading is free but has constraints:

1. Plug your iPhone in. Enable Developer Mode (iPhone Settings → Privacy & Security → Developer Mode → On, restart).
2. Xcode → ProteinChef target → Signing & Capabilities → enable "Automatically manage signing" and pick a Team (your Personal Team works).
3. If signing fails on `com.example.proteinchef`, change the bundle id to something unique (e.g. `com.yourname.proteinchef`) in `project.yml`, `xcodegen`, and register a new iOS app in Firebase with the new id. Download a fresh `GoogleService-Info.plist`.
4. First launch on-device: iPhone Settings → General → VPN & Device Management → trust your developer profile.

Free-tier limits: provisioning profile expires every 7 days (re-run from Xcode to refresh); Sign in with Apple and real push delivery need a paid Apple Developer Program membership.

## Architecture notes

- **`AppEnvironment`** is the dependency-injection root. Services/repos are protocol-first so tests can swap implementations.
- **Repositories** wrap Firestore and return `AsyncThrowingStream` for live data. Views subscribe with `.task { for try await … }`.
- **No ViewModel framework** — SwiftUI's `@Observable` + `@State`. Feature-local state lives in the view; cross-feature state (auth, profile) lives in `RootView`'s environment objects.
- **Firestore schema** is documented inline in `firestore.rules` — anything with a path there is authoritative.
- **Account deletion** (`AccountDeletionService`) wipes user-owned subcollections best-effort from the client. Data the client can't reach (feed posts fan-out, friendships on other users' docs) can be cleaned by a scheduled Cloud Function — not yet shipped; document a manual admin runbook if it matters.

## Cloud Functions

Five Firestore-triggered functions in `Firebase/functions/src/index.ts`:

| Trigger | Action |
| --- | --- |
| `users/{uid}/friendRequests/{fromUid}` create | Notify recipient of new friend request |
| `users/{uid}/friends/{friendUid}` create | Notify the original requester that their request was accepted |
| `feedPosts/{postId}` create | Fan out "new post" notification to all of the author's friends |
| `feedPosts/{postId}/likes/{likerUid}` create | Notify post author of a like |
| `feedPosts/{postId}/comments/{commentId}` create | Notify post author of a comment |

Each function writes a notification doc at `users/{recipient}/notifications/{id}` (showing up in the in-app inbox immediately) and, if an `fcmToken` is present on the recipient's profile, sends an APNs push. Stale tokens are pruned on unregistered errors.

## Privacy and App Store notes

- `PrivacyInfo.xcprivacy` declares the data types the app collects (email, name, user id, photos, health/fitness), all for app functionality, none for tracking.
- `NSCameraUsageDescription`, `NSPhotoLibraryUsageDescription`, `NSPhotoLibraryAddUsageDescription` set in `Info.plist`.
- `ITSAppUsesNonExemptEncryption = false` — we only use standard TLS from Apple's frameworks.
- Account deletion is reachable from Settings → "Delete account", as required by Guideline 5.1.1(v).
- Replace the placeholder privacy/terms URLs in `SettingsView` before submission.

## Phases

1. Auth + onboarding — ✅
2. Theme + design system — ✅
3. Recipes + ingredients + photos — ✅
4. Meal logging + dashboard — ✅
5. Workouts + templates + history — ✅
6. Friends + recipe feed — ✅
7. Push notifications — ✅
8. Security, account deletion, privacy, deploy runbook — ✅
9. TikTok recipe import agent — planned (oEmbed + Claude API via Cloud Function)

## License

Private — not for redistribution.
