# ContentView Ownership Migration Design

## Goal

Move the demo page and application appearance state out of the reusable
`DarkModeToggle` Swift Package and into the `DarkModeSwitchButton` application
repository. Preserve the visible behavior, tests, and Git history in both
repositories.

## Confirmed version strategy

Removing the Package's public `ContentView` is an incompatible API change.
`DarkModeToggle` will therefore publish an annotated semantic-version Tag:

```text
2.0.0
```

The Tag is created only after the Package source, architecture test, README,
and existing unit tests are committed and verified. The annotated Tag must
dereference to the same commit as remote `main`.

The App then changes its minimum Package version from `1.0.0` to `2.0.0` and
commits the resolved revision for both `.xcodeproj` and `.xcworkspace` opening
paths.

## Repository responsibilities

### DarkModeToggle 2.0.0

The Package exposes only the reusable component:

```swift
public struct DarkModeToggle: View {
    public init(isDarkMode: Binding<Bool>)
}
```

It owns:

- track, day/night scenes, celestial thumb, stars, clouds, and shapes
- source geometry and artwork data
- Reduce Motion behavior inside the component
- component accessibility semantics
- geometry, artwork, and source-boundary tests

`Sources/DarkModeSwitchDemoFeature/ContentView.swift` is removed. The Package
does not decide how an application stores appearance state, lays out a demo
screen, colors its screen background, or applies a preferred color scheme.

### DarkModeSwitchButton App

The App adds `DarkModeSwitchDemo/DarkModeSwitchDemo/ContentView.swift`. That
view owns:

- `@AppStorage("isDarkMode")`
- the full-screen light/dark demo background
- the `DarkModeToggle` layout and binding
- `.preferredColorScheme(isDarkMode ? .dark : .light)`
- the screen-level Reduce Motion transition

`DarkModeSwitchDemoApp` remains the `@main` entry point and constructs this
App-local `ContentView`.

## State flow

```text
App repository
UserDefaults
    ⇅ @AppStorage("isDarkMode")
ContentView
    ├── Binding<Bool> ──→ Package DarkModeToggle
    ├── preferredColorScheme ──→ App appearance
    └── screenBackground ──→ Demo page background

Package repository
DarkModeToggle
    └── Button tap ──→ Binding<Bool>.toggle()
```

The state key and default value remain unchanged, so an existing App install
keeps its stored appearance after upgrading from Package 1.0.0 to 2.0.0.

## Test strategy

### Package red-green check

Add a Package architecture test that resolves the Package root relative to
the test source and asserts that
`Sources/DarkModeSwitchDemoFeature/ContentView.swift` does not exist.

1. Add the test while the file still exists and run it to observe the expected
   failure.
2. Delete Package `ContentView.swift`.
3. Re-run all Package tests and require zero failures.

This protects the repository boundary from a future demo screen accidentally
being added back to the reusable Package.

### App red-green check

After `DarkModeToggle 2.0.0` exists, update the App dependency before adding
the App-local view and build once. The build must fail because
`DarkModeSwitchDemoApp` can no longer resolve `ContentView` from the Package.
Then add the App-local `ContentView.swift` and require the same build to pass.

Run the two existing UI tests to verify:

- rapid reversal while the transition is in flight
- `@AppStorage` persistence across termination and relaunch

Finally build and launch the App on an iPhone simulator.

## Documentation changes

The Package README removes `ContentView` from its public API, usage examples,
and file tree. It identifies `2.0.0` as the release where App integration moved
to consumers.

The App README moves `ContentView.swift` into the App tree and explains that
the Package exports only `DarkModeToggle`. All version, revision, dependency,
and troubleshooting references are updated from `1.0.0` to `2.0.0`.

The App's `CLAUDE.md` is updated to state that App appearance orchestration is
owned locally while reusable drawing remains in the remote Package.

## Commit and publication sequence

1. App repository: commit this design and its implementation plan on
   `feat/move-content-view-to-app`.
2. Package repository: commit the tested source-boundary refactor and README.
3. Package repository: push `main`, create annotated Tag `2.0.0`, push the Tag,
   and verify it dereferences to remote `main`.
4. App repository: add App-local `ContentView`, update Package requirement and
   lock files, update docs, and commit the migration.
5. App repository: verify build, UI tests, launch, and source ownership; merge
   to `main` with a fast-forward and push.

No force-push, history rewrite, or replacement of the existing `1.0.0` Tag is
allowed. The unrelated local `audit-dribbble-toggle/` directory remains
untracked and is never copied into either repository.

## Completion checks

- `DarkModeToggle` remote `main` contains no Package `ContentView.swift`.
- `DarkModeToggle` has an annotated `2.0.0` Tag that dereferences to remote
  `main`; the existing `1.0.0` Tag is unchanged.
- all Package tests pass independently
- the App contains its own `ContentView.swift`
- both App lock files resolve `DarkModeToggle 2.0.0` to the tagged revision
- the App builds directly from `.xcodeproj`
- both App UI tests pass through `.xcworkspace`
- the App installs and launches on an iPhone simulator
- both repositories are private and their default branches remain `main`
- local and remote `main` SHAs match after publication
