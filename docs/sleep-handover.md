# Chronicle - Sleep Feature Handover

## Context

This handover covers adding a Sleep tab to the existing Chronicle iOS app. The base app already tracks optical prescriptions using SwiftUI, SwiftData, Swift Charts, local notifications, and SwiftData CloudKit sync.

Sleep is a separate feature area. HealthKit is the source of truth. Do not persist sleep data to SwiftData, do not sync it through CloudKit, and do not write anything back to HealthKit.

---

## Capability And Privacy

Add the HealthKit capability to the app target and keep the app read-only:

- Entitlement: `com.apple.developer.healthkit`
- Info.plist: `NSHealthShareUsageDescription = Chronicle reads your sleep data from Apple Health to show trends over time.`
- Read types: `HKCategoryTypeIdentifier.sleepAnalysis` and `HKQuantityTypeIdentifier.heartRate`
- No write permission

Request HealthKit permission only when the user first opens Sleep, not on cold launch.

---

## HealthKit Data Rules

Sleep analysis samples must be separated into two concepts:

- `.inBed` samples define the time-in-bed window and are excluded from stage totals.
- `.asleepCore`, `.asleepDeep`, `.asleepREM`, `.awake`, and `.asleepUnspecified` are visual stages.

Build each `SleepNight` from grouped sleep analysis samples. Prefer the `.inBed` window for `inBedStart` and `inBedEnd`; only fall back to first and last stage sample when no `.inBed` sample exists. Use the latest end time as the night date because wake time is the intuitive calendar label.

For staged nights, use `.asleepCore`, `.asleepDeep`, `.asleepREM`, and `.awake`. Use `.asleepUnspecified` only when no staged sleep samples exist, so unspecified samples do not double count alongside Watch staging.

Heart-rate samples are queried only within the final in-bed window. Nights without heart-rate samples keep `avgHeartRate == nil`.

---

## Data Structures

Use local value types only:

- `SleepNight`: id, date, in-bed start/end, stage segments, heart-rate samples, total asleep, efficiency, per-stage minutes, optional average heart rate.
- `SleepStage`: id, `SleepStageType`, start, end, duration.
- `SleepStageType`: `.core`, `.deep`, `.rem`, `.awake`, `.unspecified`.
- `HeartRateSample`: timestamp and bpm.
- `SleepChartMetric`: `.duration`, `.stages`, `.efficiency`, `.heartRate`.
- `SleepRange`: `30 days`, `3 months`, `6 months`, `12 months`.

Keep colours in a small central palette using SwiftUI `Color(red:green:blue:)` or existing `AppPalette` constants. Do not depend on an undefined `Color(hex:)` helper.

---

## HealthKit Manager

Create one `@MainActor @Observable` `HealthKitManager`. All HealthKit interaction lives here.

State model:

- `isAvailable`: `HKHealthStore.isHealthDataAvailable()`
- `hasRequestedPermission`: local runtime state, initially false
- `isLoading`
- `nights`
- `errorMessage`

Do not model a definitive read-permission-denied state. HealthKit read access cannot be reliably inspected after a request; successful authorisation can still yield no visible data. Empty results should be shown as “No accessible sleep data” with copy that explains data may be missing or access may not have been granted. Only show an error state for concrete query/request failures.

The manager may wrap `HKSampleQuery` in async continuations, but every UI-observed property mutation must happen on the main actor.

---

## App Structure

Add Sleep as a fourth tab:

```
TabView
├── History
├── Charts
├── Sleep
└── Settings
```

The existing optical `History` and `Charts` tabs stay unchanged. The Sleep tab owns its own HealthKit manager and must not affect reminder scheduling or SwiftData CloudKit sync.

---

## Sleep View Behaviour

`SleepView` states:

- Unavailable: Health data unavailable, such as unsupported devices or simulator.
- Not requested: explain what Chronicle reads and provide a button to continue.
- Loading.
- Query error with retry.
- Empty: no accessible sleep data for the selected range.
- Content.

Content includes:

- Last-night summary card.
- Range picker: `30 days`, `3 months`, `6 months`, `12 months`.
- Metric picker: `Duration`, `Stages`, `Efficiency`, `Heart Rate`.
- Chart for the selected metric.
- One insight sentence.
- Recent night list with a detail sheet showing the stage timeline.

Use `UIApplication.openSettingsURLString` only from explanatory empty/error copy, not as proof that access was denied.

---

## Chart Rules

Never invent values for missing measurements.

- Duration, stages, and efficiency charts use nights with valid sleep stages.
- Heart-rate chart filters to nights where `avgHeartRate` is non-nil.
- Heart-rate trend text uses the first and last real heart-rate values only.
- Show `ContentUnavailableView` when the selected metric has insufficient real values.

Suggested insights:

- Duration: `Average 6h 42m over 30 nights`
- Stages: `Deep sleep averaged 18% of sleep time`
- Efficiency: `Above 85% efficiency on 22 of 30 nights`
- Heart rate: `Overnight heart rate changed by -3 bpm over this range`

---

## Tests

Add unit tests for:

- `.inBed` samples define the time-in-bed window and are excluded from stage totals.
- Stage grouping falls back to `.asleepUnspecified` only when staged data is absent.
- Nights without `.inBed` fall back to stage bounds.
- Heart-rate chart data filters nil average heart rate and never zero-fills.
- Heart-rate trend uses first and last real values only.
- HealthKit manager state can represent unavailable, not requested, loading, empty, and error without a fake denied state.

Add UI smoke coverage for the Sleep tab in both light and dark appearances. On simulator, the expected state is the HealthKit unavailable state.

---

## Out Of Scope

- Respiratory rate and blood oxygen.
- Correlation views between sleep quality and optical prescription data.
- Sleep goals or coaching nudges.
- Writing data to HealthKit.
- Persisting sleep data to SwiftData.
- Export or sharing.

Keep this build focused on clean trend visualisation from existing Apple Watch sleep data.
