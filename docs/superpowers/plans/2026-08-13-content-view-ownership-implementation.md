# ContentView Ownership Migration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Move application appearance orchestration from `DarkModeToggle` into `DarkModeSwitchButton`, release the component-only Package as annotated Tag `2.0.0`, and preserve verified Git history in both private repositories.

**Architecture:** The Package keeps only the reusable `DarkModeToggle` component and an architecture test that prevents an App-level `ContentView` from returning. The App owns `@AppStorage`, the demo background, the component binding, and `.preferredColorScheme`, while consuming the Package through the `2.0.0` remote release.

**Tech Stack:** Swift 6.1, SwiftUI, Swift Package Manager, Swift Testing, XCUITest, XcodeBuildMCP, Git, GitHub CLI

---

## File map

### DarkModeToggle repository

- Delete: `Sources/DarkModeSwitchDemoFeature/ContentView.swift`
- Modify: `Tests/DarkModeSwitchDemoFeatureTests/DarkModeSwitchDemoFeatureTests.swift`
- Modify: `README.md`

### DarkModeSwitchButton repository

- Create: `DarkModeSwitchDemo/DarkModeSwitchDemo/ContentView.swift`
- Modify: `DarkModeSwitchDemo/DarkModeSwitchDemo/DarkModeSwitchDemoApp.swift`
- Modify: `DarkModeSwitchDemo/DarkModeSwitchDemo.xcodeproj/project.pbxproj`
- Modify: both shared `Package.resolved` files
- Modify: `README.md`
- Modify: `DarkModeSwitchDemo/CLAUDE.md`

### Task 1: Clone and baseline the Package repository

**Files:**
- Verify: `HideOnBushTuT/DarkModeToggle` remote `main`

- [ ] **Step 1: Clone an independent working copy**

Run:

```bash
package_root="$(mktemp -d /tmp/dark-mode-toggle-v2.XXXXXX)"
gh repo clone HideOnBushTuT/DarkModeToggle "$package_root/DarkModeToggle"
git -C "$package_root/DarkModeToggle" switch main
git -C "$package_root/DarkModeToggle" pull --ff-only
```

Expected: clean `main` tracking `origin/main` at the commit referenced by Tag `1.0.0`.

- [ ] **Step 2: Run the Package baseline tests**

Run:

```bash
xcodebuildmcp swift-package test \
  --package-path "$package_root/DarkModeToggle" \
  --configuration Debug
```

Expected: 4 tests pass, 0 fail.

### Task 2: Enforce the Package boundary with TDD

**Files:**
- Modify: `Tests/DarkModeSwitchDemoFeatureTests/DarkModeSwitchDemoFeatureTests.swift`
- Delete: `Sources/DarkModeSwitchDemoFeature/ContentView.swift`

- [ ] **Step 1: Add a failing architecture test**

Add `import Foundation` and this suite to the Package test file:

```swift
@Suite("Package boundaries")
struct PackageBoundaryTests {
    @Test("keeps application ContentView out of the package")
    func excludesApplicationContentView() {
        let packageRoot = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let appContentView = packageRoot
            .appending(path: "Sources")
            .appending(path: "DarkModeSwitchDemoFeature")
            .appending(path: "ContentView.swift")

        #expect(!FileManager.default.fileExists(atPath: appContentView.path))
    }
}
```

- [ ] **Step 2: Verify the test fails for the intended reason**

Run the Package test command from Task 1.

Expected: 5 tests are discovered; the boundary test fails because
`Sources/DarkModeSwitchDemoFeature/ContentView.swift` exists, while the original
4 tests pass.

- [ ] **Step 3: Remove the App-owned source from the Package**

Run:

```bash
git rm Sources/DarkModeSwitchDemoFeature/ContentView.swift
```

- [ ] **Step 4: Verify green Package tests**

Run the Package test command from Task 1.

Expected: 5 tests pass, 0 fail.

- [ ] **Step 5: Commit the boundary refactor**

Run:

```bash
git add Tests/DarkModeSwitchDemoFeatureTests/DarkModeSwitchDemoFeatureTests.swift
git diff --cached --check
git commit -m "refactor(package): remove app-owned content view"
```

Expected: the commit contains the new boundary test and deleted source file.

### Task 3: Document and publish DarkModeToggle 2.0.0

**Files:**
- Modify: `README.md`
- Publish: remote `main` and annotated Tag `2.0.0`

- [ ] **Step 1: Update the Package README**

Make these exact documentation changes:

- public API lists only `DarkModeToggle(isDarkMode:)`
- file tree contains no `ContentView.swift`
- usage shows the consumer owning `@AppStorage` and `.preferredColorScheme`
- installation starts at `2.0.0`
- version history states that `2.0.0` moved App orchestration to consumers

- [ ] **Step 2: Validate and commit Package documentation**

Run:

```bash
rg -n 'ContentView|1\.0\.0|TBD|TODO|FIXME' README.md
git diff --check
git add README.md
git commit -m "docs(package): document component-only API"
```

Expected: `ContentView` appears only when explaining that consumers own their
own view; installation and current release references use `2.0.0`.

- [ ] **Step 3: Re-run all Package tests before publication**

Run the Package test command from Task 1.

Expected: 5 tests pass, 0 fail.

- [ ] **Step 4: Push Package main and create annotated Tag**

Run:

```bash
git push origin main
git tag -a 2.0.0 -m "DarkModeToggle 2.0.0"
git push origin 2.0.0
```

Expected: both remote operations succeed without force-push.

- [ ] **Step 5: Verify the Tag and retained history**

Run:

```bash
remote_main="$(git ls-remote origin refs/heads/main | awk '{print $1}')"
remote_v2="$(git ls-remote origin 'refs/tags/2.0.0^{}' | awk '{print $1}')"
test "$remote_main" = "$remote_v2"
git ls-remote origin refs/tags/1.0.0 refs/tags/2.0.0 'refs/tags/2.0.0^{}'
gh repo view HideOnBushTuT/DarkModeToggle \
  --json visibility,defaultBranchRef,url
```

Expected: `2.0.0` is annotated and dereferences to remote `main`; `1.0.0`
still exists; the repository remains private with default branch `main`.

### Task 4: Reproduce the App integration failure against 2.0.0

**Files:**
- Modify: `DarkModeSwitchDemo/DarkModeSwitchDemo.xcodeproj/project.pbxproj`
- Regenerate: both `Package.resolved` files

- [ ] **Step 1: Raise the App Package requirement to 2.0.0**

Change the remote requirement to:

```text
requirement = {
    kind = upToNextMajorVersion;
    minimumVersion = 2.0.0;
};
```

Remove both existing shared `Package.resolved` files so Xcode must resolve the
new major version rather than reuse the 1.0.0 lock.

- [ ] **Step 2: Verify the App build fails before local ContentView exists**

Run:

```bash
xcodebuildmcp simulator build \
  --project-path DarkModeSwitchDemo/DarkModeSwitchDemo.xcodeproj \
  --scheme DarkModeSwitchDemo \
  --simulator-name "iPhone Air" \
  --configuration Debug
```

Expected: dependency resolution selects `DarkModeToggle 2.0.0`, then compilation
fails because `DarkModeSwitchDemoApp.swift` cannot find `ContentView`.

### Task 5: Move ContentView ownership into the App

**Files:**
- Create: `DarkModeSwitchDemo/DarkModeSwitchDemo/ContentView.swift`
- Modify: `DarkModeSwitchDemo/DarkModeSwitchDemo/DarkModeSwitchDemoApp.swift`
- Verify: both generated `Package.resolved` files

- [ ] **Step 1: Add the App-local ContentView**

Create:

```swift
import DarkModeSwitchDemoFeature
import SwiftUI

struct ContentView: View {
    @AppStorage("isDarkMode") private var isDarkMode = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            screenBackground
                .ignoresSafeArea()

            DarkModeToggle(isDarkMode: $isDarkMode)
                .frame(width: 260)
                .padding(32)
        }
        .animation(
            reduceMotion ? .easeOut(duration: 0.2) : .easeInOut(duration: 0.5),
            value: isDarkMode
        )
        .preferredColorScheme(isDarkMode ? .dark : .light)
    }

    private var screenBackground: Color {
        isDarkMode
            ? Color(red: 83 / 255, green: 92 / 255, blue: 114 / 255)
            : Color(red: 205 / 255, green: 231 / 255, blue: 1)
    }
}

#Preview {
    ContentView()
}
```

Remove `import DarkModeSwitchDemoFeature` from
`DarkModeSwitchDemoApp.swift`; that file now depends only on SwiftUI and the
App-local view.

- [ ] **Step 2: Verify the App build turns green**

Run the build command from Task 4.

Expected: build succeeds and resolves `DarkModeToggle 2.0.0`.

- [ ] **Step 3: Resolve the Workspace opening path**

Run:

```bash
xcodebuildmcp simulator build \
  --workspace-path DarkModeSwitchDemo/DarkModeSwitchDemo.xcworkspace \
  --scheme DarkModeSwitchDemo \
  --simulator-name "iPhone Air" \
  --configuration Debug
```

Expected: the Workspace build succeeds and regenerates its own shared lock
file for `DarkModeToggle 2.0.0`.

- [ ] **Step 4: Verify both lock files point to the same 2.0.0 revision**

Run:

```bash
find DarkModeSwitchDemo -path '*/Package.resolved' -print
diff -u \
  DarkModeSwitchDemo/DarkModeSwitchDemo.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved \
  DarkModeSwitchDemo/DarkModeSwitchDemo.xcworkspace/xcshareddata/swiftpm/Package.resolved
rg -n '2\.0\.0|darkmodetoggle' \
  DarkModeSwitchDemo/DarkModeSwitchDemo.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved
```

Expected: both lock files exist, are identical, and resolve version `2.0.0` to
the Package Tag's dereferenced commit.

- [ ] **Step 5: Commit the App migration**

Run:

```bash
git add DarkModeSwitchDemo/DarkModeSwitchDemo/ContentView.swift \
  DarkModeSwitchDemo/DarkModeSwitchDemo/DarkModeSwitchDemoApp.swift \
  DarkModeSwitchDemo/DarkModeSwitchDemo.xcodeproj/project.pbxproj \
  DarkModeSwitchDemo/DarkModeSwitchDemo.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved \
  DarkModeSwitchDemo/DarkModeSwitchDemo.xcworkspace/xcshareddata/swiftpm/Package.resolved
git diff --cached --check
git commit -m "refactor(app): own appearance content view"
```

### Task 6: Update App documentation

**Files:**
- Modify: `README.md`
- Modify: `DarkModeSwitchDemo/CLAUDE.md`

- [ ] **Step 1: Correct the App architecture guide**

Update all relevant sections so that:

- App tree contains `ContentView.swift`
- Package tree does not contain `ContentView.swift`
- Package public API is only `DarkModeToggle`
- state-flow text explicitly locates `ContentView` in the App repository
- current Package version and minimum requirement are `2.0.0`
- lock-file revision is the verified dereferenced `2.0.0` commit

Update `CLAUDE.md` so App appearance state and page layout are local, while
component drawing and component accessibility remain in the Package.

- [ ] **Step 2: Validate and commit App documentation**

Run:

```bash
rg -n '1\.0\.0|Package.*ContentView|TBD|TODO|FIXME' README.md DarkModeSwitchDemo/CLAUDE.md
git diff --check
git add README.md DarkModeSwitchDemo/CLAUDE.md
git commit -m "docs(architecture): document app-owned content view"
```

Expected: no stale 1.0.0 dependency or claim that the Package owns
`ContentView` remains.

### Task 7: Verify and publish the App repository

**Files:**
- Verify: complete App repository
- Publish: `HideOnBushTuT/DarkModeSwitchButton` remote `main`

- [ ] **Step 1: Run the App UI tests**

Run:

```bash
xcodebuildmcp simulator test \
  --workspace-path DarkModeSwitchDemo/DarkModeSwitchDemo.xcworkspace \
  --scheme DarkModeSwitchDemo \
  --simulator-name "iPhone Air" \
  --configuration Debug
```

Expected: both UI tests pass, 0 fail.

- [ ] **Step 2: Build and launch the App**

Run:

```bash
xcodebuildmcp simulator build-and-run \
  --project-path DarkModeSwitchDemo/DarkModeSwitchDemo.xcodeproj \
  --scheme DarkModeSwitchDemo \
  --simulator-name "iPhone Air" \
  --configuration Debug
```

Expected: build, install, and launch succeed on `iPhone Air`.

- [ ] **Step 3: Audit source ownership and Git state**

Run:

```bash
test -f DarkModeSwitchDemo/DarkModeSwitchDemo/ContentView.swift
test "$(git ls-files '*ContentView.swift' | wc -l | tr -d ' ')" = "1"
git diff --check
git status --short --branch
```

Expected: the App contains exactly one tracked `ContentView.swift` and the
feature worktree is clean.

- [ ] **Step 4: Fast-forward App main and push**

From the primary App checkout:

```bash
git switch main
git merge --ff-only feat/move-content-view-to-app
git push origin main
```

Expected: remote `main` receives the design, plan, migration, and documentation
commits without a merge commit.

- [ ] **Step 5: Verify both private repositories**

Run:

```bash
test "$(git rev-parse main)" = "$(git ls-remote origin refs/heads/main | awk '{print $1}')"
gh repo view HideOnBushTuT/DarkModeSwitchButton \
  --json visibility,defaultBranchRef,url
gh repo view HideOnBushTuT/DarkModeToggle \
  --json visibility,defaultBranchRef,url
git ls-remote https://github.com/HideOnBushTuT/DarkModeToggle.git \
  refs/tags/1.0.0 refs/tags/2.0.0 'refs/tags/2.0.0^{}'
```

Expected: both repositories remain private with default branch `main`; local
and remote App `main` match; Package Tags `1.0.0` and annotated `2.0.0` exist.
