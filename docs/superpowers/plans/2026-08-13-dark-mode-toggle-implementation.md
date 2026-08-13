# SwiftUI Dark Mode Toggle Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build an iOS 17+ SwiftUI demo that faithfully reproduces the source light/dark toggle's geometry, layered artwork, and transition timing, and use it as the app's dark-mode control.

**Architecture:** Keep the source artwork in its original 173-point coordinate space and derive all rendered geometry from the Power Apps component's 130×80 frame. Separate deterministic geometry and art data from SwiftUI rendering so unit tests can lock down fidelity. Compose the control from a clipped track scene, an independently scaled celestial layer, and a transparent interaction/accessibility layer.

**Tech Stack:** Swift 6, SwiftUI, XCTest/XCUITest, XcodeGen-backed XcodeBuildMCP iOS template, XcodeBuildMCP simulator workflows.

---

## Task 1: Scaffold and configure the iOS project

**Files:**

- Create: `.xcodebuildmcp/config.yaml`
- Create: `DarkModeSwitchDemo/` using XcodeBuildMCP project scaffolding
- Modify: `DarkModeSwitchDemo/DarkModeSwitchDemoPackage/Package.swift`

- [x] **Step 1: Scaffold an iPhone-only iOS 17 project**

Run:

```bash
xcodebuildmcp project-scaffolding scaffold-ios --json '{"projectName":"DarkModeSwitchDemo","outputPath":"./DarkModeSwitchDemo","bundleIdentifier":"com.example.DarkModeSwitchDemo","displayName":"Dark Mode Switch","deploymentTarget":"17.0","targetedDeviceFamily":["iphone"],"supportedOrientations":["portrait"],"customizeNames":true}'
```

Expected: `DarkModeSwitchDemo/DarkModeSwitchDemo.xcworkspace` and package source/test targets are created.

- [x] **Step 2: Add repeatable XcodeBuildMCP defaults**

Create `.xcodebuildmcp/config.yaml` with the workspace, `DarkModeSwitchDemo` scheme, Debug configuration, and `iPhone Air` simulator defaults.

- [x] **Step 3: Confirm the generated project builds before modification**

Run:

```bash
xcodebuildmcp simulator build --workspace-path DarkModeSwitchDemo/DarkModeSwitchDemo.xcworkspace --scheme DarkModeSwitchDemo --simulator-name "iPhone Air" --configuration Debug
```

Expected: build succeeds.

- [x] **Step 4: Commit the scaffold**

```bash
git add .xcodebuildmcp DarkModeSwitchDemo
git commit -m "chore(ios): scaffold SwiftUI demo"
```

## Task 2: Lock down source geometry with tests

**Files:**

- Create: `DarkModeSwitchDemo/DarkModeSwitchDemoPackage/Sources/DarkModeSwitchDemoFeature/DarkModeToggleMetrics.swift`
- Modify: `DarkModeSwitchDemo/DarkModeSwitchDemoPackage/Tests/DarkModeSwitchDemoFeatureTests/DarkModeSwitchDemoFeatureTests.swift`

- [x] **Step 1: Write failing metric tests**

Test a 130-point-wide control and assert:

```swift
XCTAssertEqual(metrics.componentHeight, 80, accuracy: 0.0001)
XCTAssertEqual(metrics.trackHeight, 51.84971098, accuracy: 0.0001)
XCTAssertEqual(metrics.celestialScale, 156.0 / 173.0, accuracy: 0.0001)
XCTAssertEqual(metrics.translationX(isDarkMode: false), -90.17341040, accuracy: 0.0001)
XCTAssertEqual(metrics.translationX(isDarkMode: true), -22.54335260, accuracy: 0.0001)
```

- [x] **Step 2: Run tests and confirm the expected failure**

Run:

```bash
xcodebuildmcp simulator test --workspace-path DarkModeSwitchDemo/DarkModeSwitchDemo.xcworkspace --scheme DarkModeSwitchDemo --simulator-name "iPhone Air" --configuration Debug
```

Expected: compilation fails because `DarkModeToggleMetrics` does not exist.

- [x] **Step 3: Implement deterministic source-to-SwiftUI geometry**

Define the 173×69 track artboard, 173×84 celestial artboard, 130×80 reference component, 1.2 celestial width multiplier, and source translations of −100/−25.

- [x] **Step 4: Run tests and confirm they pass**

Expected: all metric tests pass.

- [x] **Step 5: Commit**

```bash
git add DarkModeSwitchDemo
git commit -m "test(toggle): lock down source geometry"
```

## Task 3: Lock down clouds and stars with tests

**Files:**

- Create: `DarkModeSwitchDemo/DarkModeSwitchDemoPackage/Sources/DarkModeSwitchDemoFeature/DarkModeToggleArt.swift`
- Modify: `DarkModeSwitchDemo/DarkModeSwitchDemoPackage/Tests/DarkModeSwitchDemoFeatureTests/DarkModeSwitchDemoFeatureTests.swift`

- [x] **Step 1: Write failing source-art tests**

Assert four cloud groups, six circles per group, 21 stars, cloud durations `[3.5, 4.5, 2.5, 5.5]`, star-group durations `[3, 2, 1, 5]`, and representative exact coordinates/opacities from the source SVG.

- [x] **Step 2: Run tests and confirm the expected failure**

Expected: compilation fails because `DarkModeToggleArt` does not exist.

- [x] **Step 3: Add exact data models and source values**

Store cloud circles and stars in the original coordinate system. Keep group `0` stars static and assign animated groups `1...4` to their matching opacity durations.

- [x] **Step 4: Run tests and confirm they pass**

- [x] **Step 5: Commit**

```bash
git add DarkModeSwitchDemo
git commit -m "feat(toggle): encode source artwork data"
```

## Task 4: Render the animated toggle

**Files:**

- Create: `DarkModeSwitchDemo/DarkModeSwitchDemoPackage/Sources/DarkModeSwitchDemoFeature/FourPointStar.swift`
- Create: `DarkModeSwitchDemo/DarkModeSwitchDemoPackage/Sources/DarkModeSwitchDemoFeature/DayScene.swift`
- Create: `DarkModeSwitchDemo/DarkModeSwitchDemoPackage/Sources/DarkModeSwitchDemoFeature/NightScene.swift`
- Create: `DarkModeSwitchDemo/DarkModeSwitchDemoPackage/Sources/DarkModeSwitchDemoFeature/CelestialThumb.swift`
- Create: `DarkModeSwitchDemo/DarkModeSwitchDemoPackage/Sources/DarkModeSwitchDemoFeature/DarkModeToggle.swift`

- [x] **Step 1: Render the two clipped track scenes**

Use `#A2D1FD` for day and `#1F2533` for night. Crossfade the two scenes over 0.5 seconds. Animate each cloud group from source Y offset `+5` to `−10` with its source duration, repeating autoreversing. Animate the four star groups between transparent and opaque with 3/2/1/5-second durations.

- [x] **Step 2: Render the sun and moon in the shared celestial layer**

Reproduce the source rounded celestial dimensions, glow/drop shadows, moon occlusion path, and pale moon fill. Crossfade sun/moon over 0.5 seconds while translating the shared layer from source X `−100` to `−25` over 1 second.

- [x] **Step 3: Compose a dedicated dark-mode control**

Expose `DarkModeToggle(isDarkMode:)`, preserve the source 130:80 component aspect, center the 173:69 track inside it, and render the celestial layer at 1.2× the track width. Add hit testing, accessibility label/value, identifier `darkModeToggle`, and Reduce Motion handling.

- [x] **Step 4: Build and fix compile issues**

Run:

```bash
xcodebuildmcp simulator build --workspace-path DarkModeSwitchDemo/DarkModeSwitchDemo.xcworkspace --scheme DarkModeSwitchDemo --simulator-name "iPhone Air" --configuration Debug
```

Expected: build succeeds.

- [x] **Step 5: Commit**

```bash
git add DarkModeSwitchDemo
git commit -m "feat(toggle): recreate animated day night control"
```

## Task 5: Integrate the demo screen and persistence

**Files:**

- Modify: `DarkModeSwitchDemo/DarkModeSwitchDemoPackage/Sources/DarkModeSwitchDemoFeature/ContentView.swift`
- Modify: `DarkModeSwitchDemo/DarkModeSwitchDemo/DarkModeSwitchDemoApp.swift`
- Modify: `DarkModeSwitchDemo/DarkModeSwitchDemoUITests/DarkModeSwitchDemoUITests.swift`

- [x] **Step 1: Write a failing UI state-change test**

Launch with `-isDarkMode false`, locate `darkModeToggle`, verify its value is light, tap it, then verify its value is dark.

- [x] **Step 2: Run UI tests and confirm the expected failure**

Expected: the template screen does not expose `darkModeToggle`.

- [x] **Step 3: Build the demo screen**

Use `@AppStorage("isDarkMode")`. Place the toggle in a minimal centered screen whose source background transitions from `RGBA(205,231,255,1)` to `RGBA(83,92,114,1)`. Apply `.preferredColorScheme` so the control genuinely changes app appearance.

- [x] **Step 4: Run the full test suite**

Expected: unit and UI tests pass.

- [x] **Step 5: Commit**

```bash
git add DarkModeSwitchDemo
git commit -m "feat(app): integrate persistent dark mode demo"
```

## Task 6: Visual verification and handoff

**Files:**

- Create: `artifacts/light-mode.png`
- Create: `artifacts/dark-mode.png`
- Modify: `README.md`

- [x] **Step 1: Build and run on the configured simulator**

```bash
xcodebuildmcp simulator build-and-run --workspace-path DarkModeSwitchDemo/DarkModeSwitchDemo.xcworkspace --scheme DarkModeSwitchDemo --simulator-name "iPhone Air" --configuration Debug
```

- [x] **Step 2: Capture both states**

Use XcodeBuildMCP UI automation to inspect the accessibility tree, capture the light state, tap `darkModeToggle`, wait for the one-second motion to settle, and capture the dark state.

- [x] **Step 3: Compare against source geometry**

Verify the track ratio, cloud/star placement, sun/moon centers, 0.5-second crossfades, 1-second translation, clipping, and screen colors against the source SVG/video. Correct material discrepancies and rerun tests.

- [x] **Step 4: Document how to open and run the demo**

Add a concise README with the workspace path, iOS requirement, implementation notes, and screenshots.

- [x] **Step 5: Run final verification**

Run the complete simulator test suite and a clean build through XcodeBuildMCP. Record the commands and results.

- [x] **Step 6: Commit**

```bash
git add README.md artifacts DarkModeSwitchDemo
git commit -m "docs(demo): add run guide and visual proof"
```
