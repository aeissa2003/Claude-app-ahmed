# Handoff: ProteinChef Redesign

## Overview

A professional, confident redesign of **ProteinChef** — a SwiftUI iOS app for tracking high-protein recipes you cook and workouts you train. This handoff covers a full-app visual refresh across 11 screens: Today (daily dashboard), Recipes (list, detail, editor), Log Meal (modal sheet), Train (list + active workout logger), Feed (magazine grid + post detail), Onboarding, and Settings.

The goal was to evolve the app from a default iOS look into an **athletic-editorial** direction — bold typography, big numeric data, calm warm-paper surfaces, and a disciplined type/color system — while keeping the feature set and information architecture identical to the existing SwiftUI implementation.

## About the Design Files

The files in `designs/` are **design references created in HTML/React** — prototypes showing intended look and behavior, not production code to ship. The task is to **recreate these designs in the existing SwiftUI codebase** using the established SwiftUI patterns already in `ProteinChef/Features/*` and the `Theme` struct in `Core/DesignSystem/Theme.swift`. Use them as a pixel-accurate visual reference, not as literal code to port.

The existing app:
- SwiftUI / iOS 17+, uses `NavigationStack`, `Form`, `List`, `Sheet`
- Feature-per-folder structure under `Features/`
- `Theme.Colors`, `Theme.Spacing`, `Theme.Radius` tokens already exist — extend them, don't replace them
- ViewModels per feature (e.g. `DayDashboardViewModel`, `WorkoutEditorViewModel`) should remain untouched in structure

## Fidelity

**High-fidelity.** Final colors, typography scale, spacing, copy, and interactions are all pinned. The developer should recreate pixel-accurately in SwiftUI, substituting system equivalents where appropriate (SF Symbols for line icons, native `ScrollView`/`List` for scroll regions, native sheets for modals).

## Design Tokens

### Colors
```
--bg:        #F5F3EE   Warm paper (primary app background)
--paper:    #FBFAF6   Card surface
--ink:       #0E1014   Primary text / dark surfaces
--ink-2:    #2A2D33   Secondary text
--ink-3:    #5A5F6B   Tertiary text (captions, metadata)
--ink-4:    #9096A0   Quaternary (placeholders, disabled)
--line:      #E6E2D8   Hairline borders
--line-2:   #D5D0C2   Stronger hairline

--indigo:    #2B2EFF   Primary brand accent (CTAs, active states)
--indigo-2:  #1A1D8F   Indigo hover/pressed
--lime:      #D4FF3A   Pop accent (PRs, "high protein" badges, success)
--lime-ink:  #1F2A00   Lime-on-lime text

Macro colors (use only inside macro-specific UI):
--protein:   #1BA66A   green
--carbs:     #E5A823   amber
--fat:        #E06A4E   coral
--kcal:      #2B2EFF   indigo (same as brand)
```

SwiftUI migration: extend `Theme.Colors` with the new tokens. Keep the existing macro RGBs but tune closer to the values above.

### Typography
- **Display:** Space Grotesk 700 (big numbers, screen titles, section headers) — letter-spacing -0.035em for big sizes, -0.02em for smaller
- **UI:** Inter 400/500/600 (body, buttons, labels)
- **Mono:** JetBrains Mono 500/600 (data micro-labels, measurements, timestamps) — always UPPERCASE with 0.08–0.12em letter-spacing at 9–11px
- **On iOS:** Substitute with **SF Pro Rounded Bold** for display (closest chunky feel without shipping custom fonts) and **SF Pro** for UI, **SF Mono** for mono. If the team is OK with custom fonts, ship Space Grotesk + Inter + JetBrains Mono as bundled resources.

Type scale used:
```
Hero numeric (dashboard "72"):     80px / Space Grotesk 700 / line 0.9
Screen title:                        34px / Space Grotesk 700
Section title:                      22px / Space Grotesk 700
Card title:                         18-20px / Space Grotesk 700
Stat number:                        22-28px / Space Grotesk 700 tabular
Body:                                15px / Inter 400
Body strong:                        14-15px / Inter 500-600
Caption:                             12-13px / Inter 400
Micro-label (mono):                 9-11px / JetBrains Mono 500 / letter 0.08-0.12em uppercase
```

### Spacing & radius
```
Spacing: 4, 8, 12, 16, 20, 24, 32
Radius:  small 10, medium 14, large 22, xl 32 (bottom sheets)
```
Cards default to `radius 22`, full-sheet modals to `32`, chips/pills `999` (fully round).

### Shadows
Minimal. Cards use a 1px hairline border, not shadow. Primary floating elements (FAB, sheet handle area) use:
```
0 10px 24px rgba(14,16,20,0.25), 0 2px 6px rgba(14,16,20,0.15)
```

## Screens

Detailed screen specs live in the HTML prototypes themselves (each screen is a single JSX component you can read). The high-level map:

### 1. Today (`screens/today.jsx` → `TodayScreen`)
Replaces `Features/Dashboard/DayDashboardView.swift`.
- **App bar**: eyebrow "Fri · Apr 24" + title "Today". Right: bell icon + black circular `+` to open Log Meal sheet.
- **Hero card** (ink background, radius 22): "Protein left" eyebrow, huge lime number (remaining protein), caption "128 of 200g logged · 64%", "On pace" pill top-right. Full-width horizontal lime bar below.
- **Secondary macros card** (paper, radius 22): three horizontal bars (Calories / Carbs / Fat), each with label + big number + `/goal unit` + 10px bar + remaining + %.
- **Meals section**: title + "4 LOGGED" mono label. Four cards (Breakfast, Lunch, Dinner, Snacks). Empty sections show "EMPTY" label + Add chip; filled sections list rows with name + qty (mono) + protein-green big number + kcal.
- **Suggestions section**: horizontal carousel of recipe cards (placeholder image, lime HP chip, title, `42g P · 520 kcal · 1 serv` mono footer).
- Replaces the four tiny MacroRings with horizontal bars per the user's preference.

### 2. Recipes list (`screens/recipes.jsx` → `RecipesListScreen`)
Replaces `RecipesListView.swift`.
- App bar "Recipes" + eyebrow "Kitchen · 6 saved". Right: search + black `+`.
- Filter chip row: all / high protein / breakfast / lunch / dinner / snack / batch.
- **Featured card** (full-width): large placeholder image + chips + big title + three-stat row (protein/kcal/time) separated by 1px dividers.
- **2-column grid** for remaining recipes: image on top, HP chip, title, `42g P · 25m` mono caption.

### 3. Recipe detail (`RecipeDetailScreen`)
Replaces `RecipeDetailView.swift`.
- Cover image 280h, back button + bookmark/share icons over image.
- Title + chip row + "YOUR RECIPE · UPDATED 2 DAYS AGO" mono label.
- **Macro strip card**: "Per serving" label + segmented 1× / 2× / 4× picker. 4-column stat grid. Divider. Clock/servings/heat mono row below.
- **Ingredients card**: numbered rows, green number chip, name + qty, protein gram readout on right.
- **Method**: each step its own card with big indigo step number (`01`, `02`) and body text.
- **Sticky footer**: edit icon button + primary indigo "Log this meal · +42g P" CTA.

### 4. Recipe editor (`RecipeEditorScreen`)
Replaces `RecipeEditorView.swift`.
- Top row: close + "NEW RECIPE" centered mono label + indigo Save button.
- Dashed placeholder for cover photo with camera icon.
- Large display-font title input with underline (Space Grotesk, 28px).
- 3-col quick-stats grid: servings / prep / cook.
- Ingredients section with "Add" chip; rows have drag handle, name + qty, protein readout, × remove.
- **Live ink card** at bottom showing calculated per-serving macros with HP chip if ≥25g P/serving.

### 5. Log Meal sheet (`screens/log-meal.jsx` → `LogMealSheet`)
Replaces `LogMealSheet.swift` / `LogRecipeSheet.swift` / `LogAdHocSheet.swift`.
- Bottom sheet, radius 28 top corners, drag handle, 82% max height.
- Three-tab segmented control: Saved recipe / Quick add / Scan.
- **Saved recipe**: selected recipe card, Servings card with big number + / − buttons and preset chips (0.5×/1×/1.5×/2×), Meal chip picker (Breakfast/Lunch/Dinner/Snacks), ink preview card showing "+42g protein" in lime, indigo Log CTA.
- **Quick add**: search field + ingredient rows with macros, `+` to add.
- **Scan**: placeholder empty state with camera icon + "Open camera" CTA.

### 6. Train list (`screens/other.jsx` → `WorkoutsListScreen`)
Replaces `WorkoutsListView.swift`.
- App bar "Train" + eyebrow "Week 16 · 3 of 4 done".
- **Next-up card** (indigo bg, white text): "Next up" eyebrow, display title, mono meta, lime "Start workout" button with play icon.
- 3-col weekly stats (workouts / volume / PRs).
- **Templates carousel**: cards with indigo-tinted icon tile + name + exercise count.
- **History list**: rows with title + optional lime PR chip + date/duration/sets mono + volume big number on right.

### 7. Active workout (`ActiveWorkoutScreen`) — DARK
Replaces `ActiveWorkoutView.swift`.
- Full dark surface `#0A0B10`.
- Top row: × (cancel), centered "PUSH DAY · ELAPSED" + big timer, lime Finish button.
- **Rest timer pill** (lime-tinted): "REST TIMER" label + huge lime `0:62` timer + −15 / +15 / pause controls.
- **Exercise cards** (low-opacity white surface): exercise title, muscle + set count. Column headers (SET / PREV / KG / REPS). Set rows with numbered chip (lime "PR" if beats previous), grayed "prev" mono, big input numbers, checkbox button. Each row's opacity dims when completed. Add set dashed row below, Add exercise dashed row at bottom.

### 8. Feed (magazine grid) (`FeedScreen`)
Replaces `FeedView.swift`.
- App bar "Feed" + eyebrow "12 friends · cooking this week". Right: friends + search icons.
- **Hero post** (full width): big image, avatar + name/handle row, lime HP chip, display title, body caption, like/comment/save mono row.
- **Mixed grid row**: ink quote tile (white pull quote + "3 FRIENDS SAVED" mono) next to a narrow photo post.
- **2-column grid row**: two equal photo posts.
- **Wide horizontal row**: small square thumb + "adapted from you" context + macro mono + chevron.

### 9. Feed post detail (`FeedPostScreen`)
Replaces `FeedPostDetailView.swift`.
- Full-bleed cover image, back button overlay.
- Author row with Following button.
- Display title + body.
- **Recipe attachment card** (ink bg): thumb + title + macros + lime "Save copy" CTA.
- Like/comment/share action row.
- Comments section with avatar + name + handle + body per row.

### 10. Onboarding (`OnboardingScreen`)
Replaces `Features/Onboarding/OnboardingFlow.swift`.
- Top: back chevron + 6-segment progress bar + SKIP.
- "STEP 3 OF 6" indigo mono eyebrow.
- Multi-line display title (38px, letter-spacing -0.035em).
- Explanation body.
- **Ink numeric card**: "Daily target" label, massive lime number `180`, unit `g / day`, contextual mono meta, lime slider with white thumb, scale ticks.
- 3-col preset buttons (maintain / build / cut) — selected one uses ink background.
- Footer indigo "Continue" button with arrow.

### 11. Settings (`SettingsScreen`)
Replaces `Features/Settings/SettingsPlaceholderView.swift` (expanded from placeholder).
- App bar "Me" + eyebrow "Account · settings".
- Profile card: large indigo avatar tile + name + handle.
- 3-col stats (recipes / workouts / streak).
- **Daily targets card**: "EDIT" link, 4 rows (Protein, Calories, Bodyweight, Goal) with big numeric values.
- Menu list card: Notifications / Units (Metric) / Friends / Share.
- Red "Sign out" text button at bottom.

### Tab bar (all tabbed screens)
5 tabs: Today, Recipes, Train, Feed, Me. Mono uppercase labels at 9px / 0.1em. Active tab: ink icon + ink label + indigo dot below. Background: `rgba(251,250,246,0.92)` with 16px backdrop-blur.

## Interactions & Behavior

- **Today → +**: opens Log Meal bottom sheet.
- **Recipes list → card tap**: push to Recipe detail.
- **Recipes list → +**: push to Recipe editor.
- **Recipe detail → Log this meal**: opens Log Meal sheet pre-populated with this recipe.
- **Train list → Start workout**: push full-screen dark Active workout.
- **Active workout → Finish**: confirm alert → save + pop.
- **Active workout → set check**: marks set done (opacity drop), starts rest timer if not running.
- **Feed card tap**: push post detail.
- **Onboarding Continue**: advance step (1 → 6).
- Macro bars animate width with `.6s cubic-bezier(.2,.8,.2,1)` on mount/update — in SwiftUI use `.animation(.easeOut(duration: 0.6), value: current)`.

## State Management

Keep the existing SwiftUI ViewModels (`DayDashboardViewModel`, `WorkoutEditorViewModel`, `RecipeEditorViewModel`, etc.) untouched. They're well-structured. The redesign is purely presentational — swap view bodies, not logic.

New UI-only state to introduce:
- Today: the hero card derives "remaining protein" from `profile.proteinGoalG - vm.consumed.proteinG`.
- Log Meal sheet: tab selection (`recipe` | `quick` | `scan`), servings, meal type.
- Onboarding: per-step preset selection (maintain/build/cut is a UI affordance on top of the existing `proteinGoalG` value).

## Assets

- **No images in the prototype** — all photo slots are diagonal-stripe placeholders with a monospace label. Use real user photos (existing `Storage` pipeline) in production.
- **Icons**: 20+ custom line icons used. In SwiftUI, replace with SF Symbols:
  - `home` → `house.fill`
  - `fork` → `fork.knife`
  - `dumb` → `dumbbell.fill`
  - `users` → `person.2.fill`
  - `gear` → `gearshape.fill`
  - `bell` → `bell.fill`
  - `plus`, `close` → `plus` / `xmark`
  - `heart`, `comment`, `bookmark`, `share`, `clock`, `flame` → equivalent SF Symbols
  - `check` → `checkmark`
  - `play`, `pause` → `play.fill`, `pause.fill`
  - `chevronLeft/Right/Down` → `chevron.left/right/down`
  - `camera` → `camera.fill`
  - `trash` → `trash`
  - `edit` → `pencil`
  - `trend` → `chart.line.uptrend.xyaxis`
  - `target` → `scope`
  - `bolt` → `bolt.fill`
  - `sparkle` → `sparkles`

## Files

In `designs/`:
- `index.html` — main canvas that renders all 11 phones
- `styles.css` — design tokens + reusable UI utility classes
- `components.jsx` — shared primitives (`AppBar`, `TabBar`, `MacroBar`, `Icon`, `Phone`, `Placeholder`, `StatusBar`)
- `screens/today.jsx` — `TodayScreen`
- `screens/recipes.jsx` — `RecipesListScreen`, `RecipeDetailScreen`
- `screens/log-meal.jsx` — `LogMealSheet`, `RecipeEditorScreen`
- `screens/other.jsx` — `WorkoutsListScreen`, `ActiveWorkoutScreen`, `FeedScreen`, `FeedPostScreen`, `OnboardingScreen`, `SettingsScreen`

Open `designs/index.html` in a browser to see all screens side-by-side.

In `screenshots/`:
- `00-all-screens.png` — full canvas overview of all 11 screens
- `01-today.png` through `11-settings.png` — one image per screen, in the order listed above

## Implementation Order (suggested)

1. Extend `Theme.swift` with the new color tokens, font helpers, new radii.
2. Build a `PCMacroBar`, `PCCard`, `PCChip`, `PCTabBar`, `PCStatTile` set of reusable SwiftUI views matching the prototype primitives.
3. Rebuild `DayDashboardView` — it's the most visible + most-used screen.
4. Rebuild `RecipesListView` + `RecipeDetailView` + `RecipeEditorView`.
5. Rebuild `LogMealSheet` trio (unify the three sheets into one tabbed sheet if your PM agrees).
6. Rebuild `WorkoutsListView` + `ActiveWorkoutView` (the dark theme is a meaningful shift — verify with design).
7. Rebuild `FeedView` + `FeedPostDetailView`.
8. Rebuild `OnboardingFlow` steps to match the template in the mock.
9. Expand `SettingsPlaceholderView` to the real Settings.
