# SwiftUI Dark Mode Toggle Design

## Goal

Build a single-screen iOS 17+ SwiftUI demo that reproduces the visual appearance and motion of Kristine Kolodziejski's `LightDarkModeAnimated` Power Apps component as faithfully as SwiftUI rendering permits.

The control is specifically a dark-mode switch. It is not a generic reusable boolean toggle and does not include a third “system” state.

## Source of truth

- Original repository: <https://github.com/kristinekolodziejski/LightDarkModeAnimated>
- Background SVG coordinate system: `173 × 69`
- Sun/moon SVG coordinate system: `173 × 84`
- Visual behavior and geometry come from the unpacked Power Apps component, not from an unrelated interpretation of the video.

## Scope

The demo contains:

- One centered dark-mode switch.
- A light state with blue sky, floating clouds, and a sun on the left.
- A dark state with a dark navy sky, twinkling stars, and a crescent moon on the right.
- A surrounding screen background that switches between light and dark presentation.
- Persistent dark-mode state using `@AppStorage`.
- VoiceOver state and Reduce Motion support.

The demo does not contain navigation, settings, labels beside the control, third-party packages, remote assets, or a system-theme mode.

## Fidelity requirements

### Geometry

- Preserve the original `173:69` track geometry.
- Render the moving celestial layer in the original `173:84` artboard.
- Preserve the original pill corner radius and clipping behavior.
- Preserve the original sun and moon size of approximately `45.44 × 43.63` SVG units.
- Preserve the original celestial-layer positions of `translateX(-100)` for light mode and `translateX(-25)` for dark mode, a 75-unit travel distance.
- Reconstruct the cloud groups and stars using the coordinates from the source package rather than visually guessed placement.

### Colors

- Day track: `#A2D1FD`.
- Night track: `#1F2533`.
- Sun: `#FFC187` at 96% opacity.
- Moon and stars: `#DEE5F3`.
- The source gradients, highlights, inner shadows, and soft outer shadows are recreated with native SwiftUI gradients and shadows.

### Motion

- Day and night scenes crossfade over 0.5 seconds with ease-in-out timing.
- Sun and moon crossfade over 0.5 seconds with ease-in-out timing.
- The celestial layer moves between the two source positions over 1 second.
- Four cloud groups float vertically between source-equivalent `+5` and `-10` offsets, alternating forever with durations of 3.5, 4.5, 2.5, and 5.5 seconds.
- Four star groups alternate opacity with durations of 3, 2, 1, and 5 seconds.
- State-driven motion must be interruptible when the user taps again before an animation completes.
- With Reduce Motion enabled, cloud and star loops stop and state changes occur without large positional motion.

## Architecture

The project is a minimal iOS application with a unit-test target.

`DarkModeDemoView` owns the persisted `isDarkMode` value, applies the app color scheme, and places the control in the center of the screen.

`DarkModeToggle` is a SwiftUI control receiving `@Binding var isDarkMode`. It provides the full interactive and accessibility surface and composes the visual layers.

`ToggleTrack` draws the overlapping day and night scenes inside a capsule clip. `DayScene` draws the blue track and four cloud groups. `NightScene` draws the navy track and source-positioned stars.

`CelestialThumb` draws the overlapping sun and crescent moon at their shared source coordinate, applies source-equivalent highlights and shadows, and moves the whole layer according to the bound state.

`DarkModeToggleMetrics` contains deterministic artboard scaling and thumb-position calculations. Keeping these calculations outside the view makes the source geometry unit-testable.

## State and interaction

The only functional state is `isDarkMode`.

1. The user activates the switch.
2. `isDarkMode` toggles inside a SwiftUI animation transaction.
3. The day/night layer opacities, celestial-layer position, and sun/moon opacities react to the new value.
4. `DarkModeDemoView` applies `.preferredColorScheme(.dark)` when enabled and `.preferredColorScheme(.light)` when disabled.
5. `@AppStorage` retains the choice between launches.

Unlike the Power Apps implementation, SwiftUI does not recreate an SVG data URI or generate timestamped CSS classes. Animatable view properties interpolate directly from their current presentation values.

## Accessibility

- The entire capsule is one interactive control.
- VoiceOver label: “Dark Mode”.
- VoiceOver value: “On” or “Off”.
- The control exposes button/switch-like state rather than exposing decorative clouds and stars as separate accessibility elements.
- The hit target is at least 44 points high.
- Reduce Motion stops ambient loops and removes the one-second travel animation while retaining an immediately visible state change.

## Verification

Automated unit tests cover:

- Light-mode celestial position resolves to the source `-100` coordinate.
- Dark-mode celestial position resolves to the source `-25` coordinate.
- Scaling preserves the 75-unit source travel distance.
- Track scaling preserves the `173:69` aspect ratio.

Simulator verification covers:

- Initial light-state appearance.
- Final dark-state appearance.
- Intermediate light-to-dark transition.
- Return transition.
- Persistent mode selection.
- VoiceOver metadata and Reduce Motion behavior.
- Screenshot comparison against the original source frames for geometry, colors, layering, and shadow character.

## Acceptance criteria

- The project builds and unit tests pass on an iOS 17+ simulator.
- The switch performs a real application light/dark appearance change.
- No bitmap images, web views, embedded original SVG files, or third-party dependencies are used.
- The day/night artwork uses source-derived coordinates, colors, durations, and layer ordering.
- The final simulator screenshot closely matches the source component at the same aspect ratio, with only rendering-engine-level shadow and antialiasing differences permitted.
