# Chronicle – Code Handover

## What this is

Chronicle is a personal iOS app for tracking optical prescription data over time. The sole user is the developer. There is no backend, no authentication, no API, and no multi-user requirement. Everything lives on-device.

The app has been planned and the visual prototype has been validated. You are picking up at the build stage.

---

## Tech stack

| Concern | Choice | Notes |
|---|---|---|
| Language | Swift | Latest stable |
| UI | SwiftUI | Declarative, iOS-native |
| Persistence | SwiftData | iOS 17+ only — confirmed acceptable |
| Charts | Swift Charts | Built into iOS 16+, no third-party dependency |
| Notifications | UNUserNotificationCenter | Local only, no push |
| Minimum deployment | iOS 17 | Required for SwiftData |
| Xcode | 15+ | Required for SwiftData and Swift Charts |

No CocoaPods, no Swift Package Manager dependencies, no external libraries. The entire app is first-party Apple frameworks only.

---

## Data model

One model class. Keep it flat — nested structs cause SwiftData complications.

```swift
@Model
class PrescriptionRecord {
    var id: UUID
    var testedAt: Date
    var practice: String?
    var notes: String?

    // Right eye (OD)
    var reSph: Double?
    var reCyl: Double?
    var reAxis: Int?
    var reAdd: Double?

    // Left eye (OS)
    var leSph: Double?
    var leCyl: Double?
    var leAxis: Int?
    var leAdd: Double?

    init(testedAt: Date = .now, ...) { ... }
}
```

**Field constraints:**
- SPH: range -20.00 to +10.00, step 0.25
- CYL: range -10.00 to 0.00, step 0.25
- Axis: integer 0–180
- ADD: range 0.00 to +4.00, step 0.25, nullable (not all prescriptions have one)

All Double fields are optional at the model level. The entry form should require at least one eye to have SPH before allowing save.

---

## App structure

Three tabs - keep it simple:

```
TabView
├── History (default tab)
│   ├── List of PrescriptionRecords, newest first
│   ├── Swipe to delete
│   └── Tap to edit → Entry Form (sheet)
├── Charts
│   ├── Segmented picker: SPH | CYL | Axis | ADD
│   ├── Swift Charts line chart, two series (R + L eye)
│   └── Empty state when < 2 records
└── Settings
    ├── Test interval (months, default 24)
    ├── Remind N days before (default 30)
    ├── Last test date (auto-populated from most recent record)
    └── Notification permission banner when access is denied
```

A floating "+" button on History opens the Entry Form as a sheet for new records.

---

## Entry form detail

The key UX decision: **do not use a free-text decimal keyboard for SPH, CYL, or ADD**. The iOS `.decimalPad` keyboard does not show a minus key, which breaks entry for short-sighted (negative) prescriptions.

Use explicit local form state and map that state back to the optional SwiftData model on save. Do not bind steppers directly to `Double?` properties on `PrescriptionRecord`.

Suggested shape:
- Each eye has its own section
- Each eye section has a toggle to include or exclude that eye from the saved record
- SPH is always present when an eye is included
- CYL and Axis are an optional pair controlled by a toggle
- ADD is separate per eye and controlled by its own toggle

Use a **stepper component** for SPH, CYL, and ADD:

```swift
// Example pattern for local form state
Stepper(value: $formState.rightSph, in: -20.0...10.0, step: 0.25) {
    HStack {
        Text("SPH")
        Spacer()
        Text(formState.rightSph >= 0 ? "+\(formState.rightSph, specifier: "%.2f")" : "\(formState.rightSph, specifier: "%.2f")")
            .foregroundStyle(.secondary)
    }
}
```

This is also faster than typing when standing at the optician's — which is the primary use moment.

Axis uses `.numberPad` - it's always a positive integer so the standard number keyboard is fine. Validate 0-180 before save.

Each eye should have its own "Reading addition" toggle. When the toggle is off, store `nil` for that eye's ADD value.

---

## Charts detail

Using Swift Charts (`import Charts`). One chart, metric switched by segmented picker.

Do not coalesce missing values to `0`. Build a filtered series per eye for the active metric and include only records that have a real value for that eye and metric.

```swift
Chart(rightEyePoints) { point in
    if showRightEye {
        LineMark(
            x: .value("Date", point.date),
            y: .value("Right", point.value)
        )
        .foregroundStyle(by: .value("Eye", "Right"))
        .symbol(Circle())
    }
    // repeat for left eye
}
```

Colour convention (match the validated prototype):
- Right eye: `#7dd3fc` (light blue)
- Left eye: `#fda4af` (light rose)

Show an insight line below the chart - a plain text sentence summarising the trend. Compute each sentence from the first and last real values in the plotted series for the active metric. If a visible eye has fewer than two real values, omit its trend sentence.

Empty state: use `ContentUnavailableView` when neither visible eye has at least two data points for the active metric. If there are no records at all, use a "No records yet" message. If records exist but not enough values exist for the selected metric, use a "Not enough data" message.

---

## Notifications

Use `UNUserNotificationCenter`. Request permission on first launch. Store reminder settings in `AppStorage` using explicit keys for interval months and remind-days-before. Schedule a single local notification based on:

```
fireDate = lastTestedAt + intervalMonths - remindDaysBefore
```

Re-schedule on every app launch and whenever Settings are changed. Cancel and re-schedule rather than checking if one already exists - simpler and safe.

If there are no prescription records, cancel any pending reminder and do not schedule a new one.

If the user has denied notification permission, show a banner in Settings with a link to `UIApplication.openSettingsURLString`.

---

## Preview data

Create a `PrescriptionRecord.previews` static array with 10 records spanning 2015–2024. Use realistic values consistent with mild myopia and presbyopia onset (ADD appearing from 2021):

```
2015: R -1.75/-0.50×90  L -2.00/-0.75×85
2016: R -2.00/-0.50×90  L -2.25/-0.75×85
2017: R -2.00/-0.50×92  L -2.25/-0.75×87
2018: R -2.25/-0.50×90  L -2.50/-0.75×85
2019: R -2.25/-0.75×90  L -2.50/-1.00×85
2020: R -2.25/-0.75×92  L -2.75/-1.00×85
2021: R -2.50/-0.75×90  L -2.75/-1.00×87  ADD +0.75
2022: R -2.50/-0.75×90  L -3.00/-1.00×85  ADD +1.00
2023: R -2.50/-0.75×90  L -3.00/-1.25×85  ADD +1.25
2024: R -2.50/-0.75×92  L -3.00/-1.25×87  ADD +1.50
```

Use these in `#Preview` blocks and in a dedicated PreviewContainer using an in-memory `ModelConfiguration`.

---

## Visual design

The prototype established the aesthetic - restrained typography, dark-leaning surfaces, and the two eye colours. Carry this through into SwiftUI without hard-locking the app to dark mode:

- Appearance: follow the system appearance setting, but use the dark prototype as the visual reference
- Backgrounds: use semantic system backgrounds so the app works in both light and dark appearance
- Accent: avoid the default system blue; use the light blue `#7dd3fc` as the app tint
- Palette: keep a small shared palette for right eye, left eye, and card/background variants rather than scattering colour literals
- Typography: use the system SF Pro - no custom fonts needed in SwiftUI native; rely on `.title`, `.headline`, `.caption` semantic styles
- Right eye indicator: `#7dd3fc`
- Left eye indicator: `#fda4af`

The app should look like it belongs in iOS - no skeuomorphic elements, no heavy custom chrome. Let SwiftUI's native components do the work.

---

## Build order

Follow this sequence — each step is testable in isolation before moving on:

1. **Xcode project** — new SwiftUI app, iOS 17 target, SwiftData enabled at project creation
2. **PrescriptionRecord model** — `@Model` class, preview data, verify Xcode canvas renders
3. **History list** — `List` with `@Query`, swipe to delete, "+" button scaffold
4. **Entry form** — steppers, date picker, notes, save to `modelContext`, edit mode
5. **Charts view** — segmented picker, Swift Charts line marks, empty state, insight text
6. **Settings + notifications** — interval config, UNUserNotificationCenter scheduling
7. **Polish** — empty states, error handling, haptics on save, app icon

---

## What is explicitly out of scope for this build

- Camera capture or OCR (post-MVP)
- Hearing, blood panel, or any other test type (post-MVP)
- iCloud sync or any backend (post-MVP)
- Sharing or export (post-MVP)
- App Store submission (personal device install via Xcode is sufficient)
- Authentication (single user, no login)
- iPad layout (iPhone only)

Do not design for any of these. Keep the code simple enough that adding them later is straightforward, but do not over-engineer for flexibility that isn't needed yet.

---

## ClickUp reference

Project tracking is in the Chronicle folder in the Projects space. The active epics are:

- Xcode Project & SwiftData Model → `86c9g16p7`
- Optical Entry Form → `86c9g16z1`
- Trend Visualisation (Swift Charts) → `86c9fk2td`
- Local Notification Reminders → `86c9g17aq`
