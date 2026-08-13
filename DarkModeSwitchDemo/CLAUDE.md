# Project overview

This repository contains a native iPhone application built with SwiftUI and
Swift 6.1+. The deployment target is iOS 17.0.

The application consumes the private `DarkModeToggle` Swift Package from:

```text
https://github.com/HideOnBushTuT/DarkModeToggle.git
```

The resolved release is `2.0.0`. The Swift product and import name are
`DarkModeSwitchDemoFeature`.

## Repository boundary

`DarkModeSwitchButton` owns:

- the `@main` application shell
- `ContentView`, `@AppStorage`, page layout, and preferred App appearance
- Xcode project, workspace, build configuration, and entitlements
- application UI tests
- screenshots and project documentation

`DarkModeToggle` owns:

- `DarkModeToggle` and its public `Binding<Bool>` API
- all scene drawing and animation code
- geometry and source-art data
- Package unit tests and release tags

Do not add an embedded local Package directory to this repository. Feature
changes belong in the separate Package repository and must be consumed through
a new semantic version.

## SwiftUI conventions

- Use native SwiftUI state flow (`@State`, `@Binding`, `@AppStorage`, and
  `@Environment`).
- Keep views as state expressions; do not introduce a ViewModel for local UI
  state.
- Split complex drawing into focused `View` and `Shape` types.
- Preserve Reduce Motion and VoiceOver behavior when changing the toggle.
- Keep reusable drawing inside the Package and App appearance orchestration in
  the local `ContentView`.

## Build and test

Use XcodeBuildMCP rather than raw `xcodebuild` or `simctl`.

Build the App:

```bash
xcodebuildmcp simulator build \
  --project-path DarkModeSwitchDemo.xcodeproj \
  --scheme DarkModeSwitchDemo \
  --simulator-name "iPhone Air" \
  --configuration Debug
```

Run App UI tests:

```bash
xcodebuildmcp simulator test \
  --workspace-path DarkModeSwitchDemo.xcworkspace \
  --scheme DarkModeSwitchDemo \
  --simulator-name "iPhone Air" \
  --configuration Debug
```

Package unit tests must run from a clone of the `DarkModeToggle` repository:

```bash
xcodebuildmcp swift-package test \
  --package-path /path/to/DarkModeToggle \
  --configuration Debug
```

The private Package requires an authenticated GitHub account in Xcode or
equivalent Git credentials.
