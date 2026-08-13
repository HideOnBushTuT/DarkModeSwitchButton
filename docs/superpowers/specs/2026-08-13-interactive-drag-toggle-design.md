# DarkModeToggle 3.0 Interactive Drag Design

## Goal

Publish `DarkModeToggle 3.0.0` with a thumb and scene that follow a horizontal
drag continuously. Preserve the existing `Binding<Bool>` API, tap activation,
VoiceOver semantics, responsive geometry, and application-owned appearance
state.

The new interaction must feel like direct manipulation: visual feedback begins
as soon as a horizontal drag is recognized, every affected layer uses the same
live progress, and release motion continues toward the state implied by the
gesture's predicted endpoint.

## Confirmed approach

Keep the existing public `DarkModeToggle` control and add private interaction
state inside the Package. Do not expose drag progress to consumers and do not
replace `Binding<Bool>` with a new model type.

Alternatives rejected for this release:

- Rebuilding the control as a custom accessibility element would provide more
  gesture control but would duplicate standard button activation semantics.
- Exposing progress or gesture callbacks publicly would make internal artwork
  timing part of the Package API without a current consumer requirement.

The existing initializer remains source-compatible:

```swift
public struct DarkModeToggle: View {
    public init(isDarkMode: Binding<Bool>)
}
```

## Version strategy

The Package publishes an annotated semantic-version Tag:

```text
3.0.0
```

Although the Swift initializer remains compatible, drag changes the control's
core interaction behavior. The requested major release also keeps existing
`2.x` consumers on their tap-only behavior until they explicitly opt in.

The App changes its minimum dependency from `2.0.0` to `3.0.0`, resolves both
lock files to the tagged revision, and retains the same Product/import name:
`DarkModeSwitchDemoFeature`.

## Interaction model

The visual state is represented by one normalized progress value:

- `0` is fully light.
- `1` is fully dark.
- values between `0` and `1` are interactive transition frames.

When no drag is active, progress is derived from the binding. When a drag is
active, the component derives progress from the state at gesture start and the
horizontal translation:

```text
progress = clamp(startProgress + translationX / translationTravel, 0 ... 1)
```

`translationTravel` comes from `DarkModeToggleMetrics`, so the interaction
scales with every supported component width. Clamping prevents the artwork
from leaving its designed endpoints.

The gesture requires 10 points of movement before it claims a drag. This
hysteresis preserves ordinary taps and avoids changing state for small touch
jitter. Only horizontal-dominant movement updates progress.
The component observes the drag simultaneously with parent gestures, locks its
own interaction to the horizontal axis when `abs(x) > abs(y)`, and treats a
vertical-dominant sequence as cancelled. This lets a surrounding vertical
scroll container continue handling its own gesture and prevents that sequence
from committing a toggle.

### Release resolution

On release, calculate a predicted progress from SwiftUI's predicted horizontal
translation using the same normalized formula. Resolve the final binding with
a midpoint threshold:

```text
predictedProgress < 0.5  -> light
predictedProgress >= 0.5 -> dark
```

Using the prediction means a short intentional flick can complete the switch
without requiring the finger to cross the midpoint. A slow drag follows the
visible release position because its prediction remains nearby.

At most one binding write may result from a touch sequence. A claimed drag
suppresses the Button's ordinary touch-up action; an untouched tap, keyboard
activation, or VoiceOver activation continues through the standard Button
action. Gesture arbitration state is cleared after the sequence so the next
tap cannot be lost.

## Visual data flow

```text
Binding<Bool> -----> resting endpoint (0 or 1)
       ^                         |
       |                         v
release target <----- interactive progress <----- DragGesture
                                 |
                +----------------+----------------+
                |                |                |
                v                v                v
          celestial X      sun/moon mix     day/night mix
                                                   |
                                                   v
                                      sky, border, clouds, stars
```

All transition layers consume the same progress:

- celestial X position linearly interpolates between the existing light and
  dark translations
- sun opacity is `1 - progress`; moon opacity is `progress`
- day scene opacity is `1 - progress`; night scene opacity is `progress`
- day/night sky fills, outer borders, and inner-edge treatments crossfade with
  their corresponding scenes
- clouds and stars remain clipped to the existing rounded track

Cloud floating and star twinkling remain ambient animations. Drag does not
restart their timelines; it only changes the scene opacity through which they
are seen.

## Animation behavior

During drag, progress changes without an implicit animation so the thumb and
scene stay attached to the finger. On release, the remaining distance settles
with an interruptible spring using `response: 0.35` and
`dampingFraction: 0.82`. One shared transaction drives the thumb and every
scene layer.

A new drag may begin while a release spring is in flight. It starts from the
currently presented progress rather than waiting for the old animation to
finish or jumping first to its logical endpoint. An internal animatable visual
container exposes its frame's interpolated presentation progress to the new
gesture start; the bound Boolean remains only the committed endpoint.

Ordinary taps continue to animate between endpoints. No timer, artificial
delay, haptic, third-party animation dependency, or bitmap asset is added.

## Reduce Motion

Reduce Motion continues to stop cloud floating and star twinkling.

Finger-controlled progress remains continuous because it is direct feedback
under the user's control. Automatic settling removes overshoot and uses a
non-elastic `easeOut(duration: 0.2)` transition. Tap and accessibility
activation change the celestial endpoint without positional interpolation and
retain a 0.2-second day/night and sun/moon crossfade so the resulting state
remains understandable.

## Accessibility

The complete capsule remains one standard Button accessibility element:

- label: `Dark Mode`
- value: `On` or `Off`
- identifier: `darkModeToggle`
- selected trait only while the binding is dark
- activation toggles the value exactly once

Decorative clouds, stars, sun, and moon remain hidden inside the single
control. The interaction does not require drag: VoiceOver users can continue
to double-tap, and tap remains the primary fallback for all users.

## Package changes

The implementation stays inside the independent `DarkModeToggle` repository:

- `DarkModeToggle.swift` owns gesture lifecycle, progress selection, binding
  commit, and button-action suppression.
- An internal animatable visual container carries the currently presented
  progress into an interrupted drag.
- A small internal interaction helper performs clamping and predicted-target
  calculations without importing application state.
- `DarkModeToggleMetrics.swift` interpolates the celestial translation for a
  normalized progress.
- `ToggleTrack` and `CelestialThumb` consume progress instead of a Boolean for
  visual interpolation.
- Package tests cover the pure interaction math and preserve existing artwork
  and repository-boundary tests.

No `ContentView`, `@AppStorage`, screen background, or preferred color scheme
returns to the Package.

## App changes

The `DarkModeSwitchButton` App continues to own `ContentView` and
`@AppStorage`. It updates only its Package requirement, resolved revisions,
UI tests, README, and project guidance required by the 3.0 release.

The user's currently uncommitted App changes to the development team and local
layout are preserved. The unrelated `audit-dribbble-toggle/` directory remains
untracked and is never committed or uploaded.

## Test strategy

### Package tests

Add red-first tests for:

- progress begins at the binding endpoint
- translation is normalized by the scaled celestial travel distance
- progress clamps below `0` and above `1`
- light-to-dark and dark-to-light drags are symmetric
- predicted progress below the midpoint resolves light
- predicted progress at or above the midpoint resolves dark
- metrics interpolate both endpoints and an intermediate translation

Run the entire Package suite after implementation so existing source geometry,
artwork data, and the absence of Package `ContentView.swift` remain protected.

### App UI tests

Keep the existing tap reversal and persistence tests, then add tests that:

- drag left-to-right and observe the accessibility value become `On`
- drag right-to-left and observe the value become `Off`
- verify one drag performs only one state commit
- tap immediately after a drag and verify the tap is not suppressed
- confirm the element is still discoverable as
  `app.buttons["darkModeToggle"]`

Build and run on an iOS 17+ iPhone simulator after both suites pass.

## Documentation and publication

Update the Package README to describe tap and drag, direct progress, Reduce
Motion, the `3.0.0` installation version, and the new tests. Update the App
README and project guidance to resolve `3.0.0` and explain that 2.x remains the
tap-only release line.

Publication order:

1. Commit and verify the Package implementation and documentation.
2. Push Package `main`.
3. Create and push annotated Tag `3.0.0`; verify that it dereferences to remote
   `main`.
4. Update the App dependency and both lock files to the tagged revision.
5. Run App build, UI tests, and a simulator launch.
6. Commit and push the App integration and documentation.

No force-push, history rewrite, replacement of `1.0.0`/`2.0.0` Tags, or public
visibility change is permitted.

## Acceptance criteria

- Dragging horizontally updates the celestial thumb and every day/night layer
  continuously at the same normalized progress.
- Slow releases choose the nearest side; flicks can select the side implied by
  the predicted endpoint.
- A drag and its overlapping Button recognition cannot toggle twice.
- Taps, rapid reversal, VoiceOver activation, persistence, and width scaling
  continue to work.
- Reduce Motion stops ambient loops and uses non-elastic automatic motion.
- The public Package initializer remains unchanged.
- All Package tests and App UI tests pass on an iPhone simulator.
- Private Package and App remote `main` branches contain the verified commits.
- The annotated `3.0.0` Tag dereferences to the verified Package `main` commit.
