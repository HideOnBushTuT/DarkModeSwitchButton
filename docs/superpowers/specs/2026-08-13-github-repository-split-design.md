# GitHub Repository Split Design

## Goal

Publish the demo as two private GitHub repositories under the `HideOnBushTuT`
account:

- `DarkModeSwitchButton` contains the iOS application shell, screenshots,
  project documentation, UI tests, and Xcode configuration.
- `DarkModeToggle` contains the reusable local Swift package as an independent
  versioned dependency.

The split must preserve useful Git history and leave the application buildable
after cloning with authenticated GitHub access.

## Repository Boundaries

### DarkModeToggle

The package repository is created from
`DarkModeSwitchDemo/DarkModeSwitchDemoPackage` and contains:

- `Package.swift`
- `Sources/DarkModeSwitchDemoFeature`
- `Tests/DarkModeSwitchDemoFeatureTests`
- a package-focused `README.md`
- the relevant source history extracted from the current repository

The Swift product and import name remain `DarkModeSwitchDemoFeature`. Renaming
the public module is outside this publishing change and would create unrelated
source churn.

The package declares iOS 17 and macOS 14. The application remains iPhone-only;
the macOS declaration lets the independent package compile and run its pure
geometry/artwork tests through `swift package test` without an app workspace.

The first published release is tagged `1.0.0`.

### DarkModeSwitchButton

The application repository keeps:

- the Xcode project and workspace
- the minimal app entry point
- UI tests and build configuration
- screenshots, attribution, design records, and implementation plans
- a detailed Chinese `README.md`

The embedded package directory is removed after the package repository is
published. The Xcode project then references:

```text
https://github.com/HideOnBushTuT/DarkModeToggle.git
```

with an up-to-next-major dependency starting at `1.0.0`.

## Documentation

The application README explains:

1. the final visual result and project purpose
2. prerequisites and authenticated private-package access
3. build and test instructions
4. the two-repository architecture and source tree
5. SwiftUI state flow and dark-mode persistence
6. scene composition, geometry, animation timing, and Reduce Motion behavior
7. why SPM is separate, including its benefits and trade-offs
8. tests, accessibility, troubleshooting, source attribution, and license

The package README documents installation, the exported product, basic SwiftUI
usage, implementation layout, test commands, versioning, and license context.
Package unit tests run in the package repository. After the split, the
application test plan contains only the application UI test target because a
consumer project cannot run a remote dependency's internal test target.

## History and Branch Strategy

- Extract package history with `git subtree split` so the package repository is
  not published as a historyless copy.
- Publish both repositories with `main` as their default branch.
- Fast-forward the application `main` branch to the completed feature history.
- Do not add or upload the unrelated untracked `audit-dribbble-toggle/`
  directory.

## Verification

Before reporting completion:

- resolve the remote package through the application project
- build the app for an iPhone simulator
- run all four package unit tests from the `DarkModeToggle` repository
- run application UI tests through the application test plan
- verify both GitHub repositories are private
- verify both default branches are `main`
- verify the package `1.0.0` tag exists remotely
- verify the application remote dependency URL and version rule
- verify no unrelated untracked files were committed

## Operational Notes

Because `DarkModeToggle` is private, a developer cloning the app must be logged
in to GitHub in Xcode or have equivalent Git credentials. This authentication
requirement is documented rather than hidden by keeping a second local copy of
the package inside the application repository.
