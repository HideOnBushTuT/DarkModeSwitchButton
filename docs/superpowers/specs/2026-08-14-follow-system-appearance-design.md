# Follow System Appearance Design

## Goal

Add a System/Light/Dark appearance preference to the app while keeping the
`DarkModeToggle` package unchanged. A new install follows the iOS appearance,
manual toggle changes remain persistent, and the user can return to following
the system at any time.

This design implements GitHub Issue #6. The issue text and the instruction to
begin development are the approved product scope.

## Constraints

- Appearance orchestration stays in the `DarkModeSwitchButton` app repository.
- `DarkModeToggle` keeps its public `Binding<Bool>` API and package version.
- The app continues to use native SwiftUI state flow; no view model is added.
- Existing toggle interaction, Reduce Motion, and VoiceOver behavior remain
  intact.
- Existing persisted `isDarkMode` values must not be silently lost.

## Considered approaches

### 1. App-owned tri-state preference with a Boolean binding bridge

Store `system`, `light`, or `dark` in the app. Resolve `system` against the
SwiftUI `colorScheme` environment and expose the resolved result to the package
through a computed `Binding<Bool>`. A manual toggle writes `light` or `dark`; a
separate app-level button writes `system`.

This is the selected approach. It satisfies all three modes without widening
the package API and keeps the app/package ownership boundary explicit.

### 2. Always mirror the system appearance

Remove persistence and make the package display the current system appearance
only. This is smaller, but the toggle can no longer act as a meaningful manual
app appearance control and does not satisfy the Light/Dark persistence
requirements.

### 3. Add a third state to the package

Change `DarkModeToggle` to accept a tri-state binding. This makes the visual
component own app policy, breaks the current public API, and directly violates
the repository boundary and Issue #6.

## Architecture

### `AppAppearancePreference`

Create an app-owned `String`-backed enum with `system`, `light`, and `dark`
cases. It owns four deterministic responsibilities:

1. Decode a stored raw value, falling back to `system` for missing or invalid
   values.
2. Return `nil`, `.light`, or `.dark` for SwiftUI's
   `preferredColorScheme` modifier.
3. Resolve whether the binary toggle should be on for a supplied system
   `ColorScheme`.
4. Migrate the legacy `isDarkMode` Boolean once when the new preference key is
   absent, then remove the legacy key so it cannot override a later return to
   System mode.

The type lives in the app target rather than the package.

### `ContentView`

`ContentView` stores the preference raw value with `@AppStorage` and reads the
current `@Environment(\.colorScheme)`. It derives the effective Boolean state:

```text
stored preference + current system color scheme
                    ↓
          effective isDarkMode Bool
                    ↓
     DarkModeToggle Binding<Bool> + page colors
```

The binding getter returns the resolved Boolean. Its setter records an explicit
`.light` or `.dark` preference, so any manual tap or drag exits System mode.
The view passes the preference's optional scheme to `.preferredColorScheme`;
`nil` allows iOS to remain the source of truth.

### App launch and migration

`DarkModeSwitchDemoApp.init` runs the legacy migration before `ContentView`
constructs its `@AppStorage`. UI-test launch arguments explicitly select a
clean Light or System starting state without introducing a production-only
appearance override.

## User interface

The existing animated toggle remains the primary Light/Dark control. A small
app-owned button below it displays:

- `Following System` with a selected icon while System mode is active.
- `Use System Setting` while an explicit Light or Dark preference is active.

Selecting the button returns to System mode immediately. The button exposes the
accessibility identifier `followSystemAppearanceButton`, label
`Follow System Appearance`, and value `On` or `Off`. Decorative styling uses a
system material and a capsule shape so it remains legible in both appearances.

## State transitions

| Current preference | Event | New preference | Effective appearance |
| --- | --- | --- | --- |
| System | iOS changes appearance | System | New iOS appearance |
| System | Toggle becomes On | Dark | Dark |
| System | Toggle becomes Off | Light | Light |
| Light | Toggle becomes On | Dark | Dark |
| Dark | Toggle becomes Off | Light | Light |
| Light or Dark | Follow System button | System | Current iOS appearance |

Unknown stored values degrade to System rather than forcing an arbitrary
appearance. There are no asynchronous operations or recoverable runtime errors.

## Testing

Add an app unit-test target for deterministic preference behavior. Unit tests
cover raw-value fallback, system resolution, manual override resolution, legacy
migration, and preservation of an already stored new preference.

Extend the UI tests to cover:

- a fresh System-mode launch in Light and Dark interface styles;
- a manual toggle leaving System mode;
- returning to System mode through the new button;
- persistence of an explicit manual choice across relaunch;
- accessibility state for the toggle and Follow System button.

Final simulator verification changes the simulator appearance while the app is
running in System mode and confirms the visible toggle state updates without a
relaunch. The full test plan and a separate compile-only build must pass on the
configured iPhone Air simulator.

## Acceptance criteria

- A fresh install follows the current iOS appearance.
- System-mode changes are reflected without relaunching the app.
- Manual Light/Dark choices persist across relaunch.
- The user can return to System mode from the app UI.
- Existing Boolean package API, package source, and package version remain
  unchanged.
- App unit tests, UI tests, and the simulator build pass.
