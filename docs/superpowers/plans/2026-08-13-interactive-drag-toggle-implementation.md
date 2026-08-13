# DarkModeToggle 3.0 Interactive Drag Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Publish `DarkModeToggle 3.0.0` with continuous horizontal drag, predicted-endpoint snapping, retained tap/VoiceOver behavior, and a verified App integration.

**Architecture:** The Package keeps `Binding<Bool>` as the committed state and adds a private normalized progress for presentation. A pure interaction helper owns clamping, axis selection, and predicted-target math; an animatable visual container distributes the current presentation progress to the track and celestial layers and allows a new drag to interrupt a settling spring without jumping. The App remains the owner of `ContentView`, persistence, and color-scheme changes.

**Tech Stack:** Swift 6.1, SwiftUI, Swift Testing, XCTest/XCUITest, Swift Package Manager, XcodeBuildMCP, Git, GitHub CLI.

**Tracking:** [DarkModeSwitchButton Issue #1](https://github.com/HideOnBushTuT/DarkModeSwitchButton/issues/1), branch `issue-1-dark-mode-toggle-v3-drag`, App worktree `.worktrees/issue-1-dark-mode-toggle-v3-drag`.

---

## File map

### DarkModeToggle Package repository

- Create `Sources/DarkModeSwitchDemoFeature/DarkModeToggleInteraction.swift`: pure drag-axis, progress, clamping, and predicted-target calculations.
- Modify `Sources/DarkModeSwitchDemoFeature/DarkModeToggleMetrics.swift`: interpolate celestial translation for normalized progress.
- Modify `Sources/DarkModeSwitchDemoFeature/DarkModeToggle.swift`: committed/display progress state, primitive Button tap handling, drag lifecycle, animatable visual container, and progress-driven track rendering.
- Modify `Sources/DarkModeSwitchDemoFeature/CelestialThumb.swift`: replace Boolean-driven animations with progress-driven position and crossfade.
- Modify `Tests/DarkModeSwitchDemoFeatureTests/DarkModeSwitchDemoFeatureTests.swift`: interaction and interpolation regression tests.
- Modify `README.md`: 3.0 installation, drag behavior, Reduce Motion, tests, and release history.

### DarkModeSwitchButton App repository

- Modify `DarkModeSwitchDemo/DarkModeSwitchDemoUITests/DarkModeSwitchDemoUITests.swift`: end-to-end horizontal drag, reverse drag, vertical cancellation, one-commit, and post-drag tap tests.
- Modify `DarkModeSwitchDemo/DarkModeSwitchDemo.xcodeproj/project.pbxproj`: raise the remote Package minimum version to `3.0.0` only; preserve unrelated local signing changes in the user's original worktree.
- Modify both `Package.resolved` files: lock the `3.0.0` Tag revision.
- Modify `README.md`: describe 3.0 drag behavior and verification.
- Modify `DarkModeSwitchDemo/CLAUDE.md`: update the resolved Package release and interaction ownership guidance.

## Task 1: Isolate execution and record the App-level red test

**Files:**
- Modify: `DarkModeSwitchDemo/DarkModeSwitchDemoUITests/DarkModeSwitchDemoUITests.swift`

- [ ] **Step 1: Create the Issue-linked branch, isolated App worktree, and Package clone**

Issue #1 already records the cross-repository requirement. Use
`superpowers:using-git-worktrees`, create its GitHub Development branch from
remote `main`, and then bring the approved design and plan commits into the
clean worktree. Clone the Package independently and use the same Issue-based
branch name:

```bash
gh issue develop 1 \
  --repo HideOnBushTuT/DarkModeSwitchButton \
  --name issue-1-dark-mode-toggle-v3-drag \
  --base main
git fetch origin
git worktree add --track \
  -b issue-1-dark-mode-toggle-v3-drag \
  .worktrees/issue-1-dark-mode-toggle-v3-drag \
  origin/issue-1-dark-mode-toggle-v3-drag
git -C .worktrees/issue-1-dark-mode-toggle-v3-drag \
  cherry-pick 43a8503..feat/interactive-drag-v3
gh repo clone HideOnBushTuT/DarkModeToggle /tmp/DarkModeToggle-issue-1
git -C /tmp/DarkModeToggle-issue-1 \
  switch -c issue-1-dark-mode-toggle-v3-drag
```

Expected: `gh issue develop --list 1` reports the linked branch, the App
worktree is clean and contains the spec and this plan, and Package `HEAD`
begins at tagged `2.0.0`. The original App worktree still shows only the
user's `DEVELOPMENT_TEAM`, `HStack`, and untracked audit changes.

- [ ] **Step 2: Add failing App UI tests before Package implementation**

Add these tests and helper to `DarkModeSwitchDemoUITests.swift`:

```swift
@MainActor
func testHorizontalDragCommitsOnceAndNextTapStillWorks() throws {
    let app = launchInLightMode()
    let toggle = app.buttons["darkModeToggle"]
    XCTAssertTrue(toggle.waitForExistence(timeout: 3))

    drag(
        toggle,
        from: CGVector(dx: 0.15, dy: 0.5),
        to: CGVector(dx: 1.1, dy: 0.5)
    )
    waitForValue("On", on: app.buttons["darkModeToggle"])

    app.buttons["darkModeToggle"].tap()
    waitForValue("Off", on: app.buttons["darkModeToggle"])
}

@MainActor
func testHorizontalDragReversesAndVerticalDragDoesNotToggle() throws {
    let app = launchInLightMode()
    let toggle = app.buttons["darkModeToggle"]
    XCTAssertTrue(toggle.waitForExistence(timeout: 3))

    drag(
        toggle,
        from: CGVector(dx: 0.15, dy: 0.5),
        to: CGVector(dx: 1.1, dy: 0.5)
    )
    waitForValue("On", on: app.buttons["darkModeToggle"])

    drag(
        app.buttons["darkModeToggle"],
        from: CGVector(dx: 0.85, dy: 0.5),
        to: CGVector(dx: -0.1, dy: 0.5)
    )
    waitForValue("Off", on: app.buttons["darkModeToggle"])

    drag(
        app.buttons["darkModeToggle"],
        from: CGVector(dx: 0.5, dy: 0.5),
        to: CGVector(dx: 0.5, dy: 1.2)
    )
    XCTAssertEqual(app.buttons["darkModeToggle"].value as? String, "Off")
}

@MainActor
private func drag(
    _ element: XCUIElement,
    from startOffset: CGVector,
    to endOffset: CGVector
) {
    let start = element.coordinate(withNormalizedOffset: startOffset)
    let end = element.coordinate(withNormalizedOffset: endOffset)
    start.press(forDuration: 0.05, thenDragTo: end)
}
```

Ending outside the old `Button` makes the 2.0 control cancel its touch-up action, while the 3.0 drag recognizer must continue tracking the sequence.

- [ ] **Step 3: Run the UI suite and observe the expected red result**

Run from the isolated App worktree:

```bash
xcodebuildmcp simulator test \
  --workspace-path DarkModeSwitchDemo/DarkModeSwitchDemo.xcworkspace \
  --scheme DarkModeSwitchDemo \
  --simulator-name "iPhone Air" \
  --configuration Debug
```

Expected: the existing two tests pass; at least the first new horizontal-drag assertion fails because Package `2.0.0` is tap-only and the accessibility value remains `Off`.

- [ ] **Step 4: Commit only the red App test**

```bash
git add DarkModeSwitchDemo/DarkModeSwitchDemoUITests/DarkModeSwitchDemoUITests.swift
git commit -m "test(app): specify interactive toggle drag"
```

Expected: the commit contains only the UI-test file.

## Task 2: Specify and implement pure Package interaction math

**Files:**
- Create: `Sources/DarkModeSwitchDemoFeature/DarkModeToggleInteraction.swift`
- Modify: `Sources/DarkModeSwitchDemoFeature/DarkModeToggleMetrics.swift`
- Modify: `Tests/DarkModeSwitchDemoFeatureTests/DarkModeSwitchDemoFeatureTests.swift`

- [ ] **Step 1: Add failing interaction and interpolation tests**

Append the following suites to the Package test file, and add the midpoint expectation to the existing metrics suite:

```swift
@Suite("Dark mode toggle interaction")
struct DarkModeToggleInteractionTests {
    @Test("maps binding endpoints to normalized progress")
    func restingProgress() {
        #expect(DarkModeToggleInteraction.restingProgress(isDarkMode: false) == 0)
        #expect(DarkModeToggleInteraction.restingProgress(isDarkMode: true) == 1)
    }

    @Test("normalizes symmetric translations and clamps both bounds")
    func translatedProgress() {
        #expect(DarkModeToggleInteraction.progress(
            startingAt: 0,
            translation: 25,
            travel: 100
        ) == 0.25)
        #expect(DarkModeToggleInteraction.progress(
            startingAt: 1,
            translation: -25,
            travel: 100
        ) == 0.75)
        #expect(DarkModeToggleInteraction.progress(
            startingAt: 0,
            translation: -20,
            travel: 100
        ) == 0)
        #expect(DarkModeToggleInteraction.progress(
            startingAt: 1,
            translation: 20,
            travel: 100
        ) == 1)
    }

    @Test("selects an axis only after comparing the full translation")
    func dragAxis() {
        #expect(DarkModeToggleInteraction.axis(
            for: CGSize(width: 12, height: 4)
        ) == .horizontal)
        #expect(DarkModeToggleInteraction.axis(
            for: CGSize(width: 4, height: 12)
        ) == .vertical)
        #expect(DarkModeToggleInteraction.axis(
            for: CGSize(width: 8, height: 8)
        ) == .vertical)
    }

    @Test("uses predicted progress and a dark-inclusive midpoint")
    func predictedTarget() {
        #expect(!DarkModeToggleInteraction.targetIsDark(
            startingAt: 0,
            predictedTranslation: 49,
            travel: 100
        ))
        #expect(DarkModeToggleInteraction.targetIsDark(
            startingAt: 0,
            predictedTranslation: 50,
            travel: 100
        ))
        #expect(!DarkModeToggleInteraction.targetIsDark(
            startingAt: 1,
            predictedTranslation: -51,
            travel: 100
        ))
    }
}
```

Add inside `sourceTranslations()`:

```swift
#expect(abs(metrics.translationX(progress: 0.5) - (-56.35838150)) < 0.0001)
```

- [ ] **Step 2: Run Package tests and verify compilation fails**

```bash
xcodebuildmcp swift-package test \
  --package-path /tmp/DarkModeToggle-issue-1 \
  --configuration Debug
```

Expected: FAIL because `DarkModeToggleInteraction` and `translationX(progress:)` do not exist.

- [ ] **Step 3: Implement the pure helper**

Create `DarkModeToggleInteraction.swift`:

```swift
import CoreGraphics

enum DarkModeToggleDragAxis: Sendable, Equatable {
    case horizontal
    case vertical
}

struct DarkModeToggleInteraction: Sendable {
    static let dragThreshold: CGFloat = 10

    static func restingProgress(isDarkMode: Bool) -> CGFloat {
        isDarkMode ? 1 : 0
    }

    static func progress(
        startingAt startProgress: CGFloat,
        translation: CGFloat,
        travel: CGFloat
    ) -> CGFloat {
        guard travel > 0 else {
            return clamped(startProgress)
        }

        return clamped(startProgress + translation / travel)
    }

    static func axis(for translation: CGSize) -> DarkModeToggleDragAxis {
        abs(translation.width) > abs(translation.height) ? .horizontal : .vertical
    }

    static func targetIsDark(
        startingAt startProgress: CGFloat,
        predictedTranslation: CGFloat,
        travel: CGFloat
    ) -> Bool {
        progress(
            startingAt: startProgress,
            translation: predictedTranslation,
            travel: travel
        ) >= 0.5
    }

    private static func clamped(_ progress: CGFloat) -> CGFloat {
        min(max(progress, 0), 1)
    }
}
```

- [ ] **Step 4: Implement normalized celestial interpolation**

Add to `DarkModeToggleMetrics` and keep the Boolean overload as a compatibility wrapper for existing internal tests:

```swift
func translationX(progress: CGFloat) -> CGFloat {
    let clampedProgress = min(max(progress, 0), 1)
    let sourceTranslation = Self.lightTranslationX
        + (Self.darkTranslationX - Self.lightTranslationX) * clampedProgress
    return sourceTranslation * celestialScale
}

func translationX(isDarkMode: Bool) -> CGFloat {
    translationX(
        progress: DarkModeToggleInteraction.restingProgress(
            isDarkMode: isDarkMode
        )
    )
}
```

- [ ] **Step 5: Run Package tests and verify green**

Run the same Package command.

Expected: all existing tests plus the new interaction tests pass with zero failures.

- [ ] **Step 6: Commit the tested interaction model**

```bash
git add Sources/DarkModeSwitchDemoFeature/DarkModeToggleInteraction.swift \
  Sources/DarkModeSwitchDemoFeature/DarkModeToggleMetrics.swift \
  Tests/DarkModeSwitchDemoFeatureTests/DarkModeSwitchDemoFeatureTests.swift
git commit -m "feat(toggle): add drag progress model"
```

## Task 3: Drive all Package visuals from presentation progress

**Files:**
- Modify: `Sources/DarkModeSwitchDemoFeature/DarkModeToggle.swift`
- Modify: `Sources/DarkModeSwitchDemoFeature/CelestialThumb.swift`

- [ ] **Step 1: Replace Boolean celestial inputs with progress inputs**

Change `CelestialThumb` to accept separate appearance and position progress so Reduce Motion can snap position while preserving a short crossfade:

```swift
struct CelestialThumb: View {
    let appearanceProgress: CGFloat
    let positionProgress: CGFloat
    let metrics: DarkModeToggleMetrics

    var body: some View {
        let scale = metrics.celestialScale

        ZStack(alignment: .topLeading) {
            SunDisc(scale: scale)
                .opacity(1 - appearanceProgress)

            MoonDisc(scale: scale)
                .opacity(appearanceProgress)
        }
        .frame(
            width: DarkModeToggleMetrics.celestialArtboard.width * scale,
            height: DarkModeToggleMetrics.celestialArtboard.height * scale,
            alignment: .topLeading
        )
        .offset(
            x: metrics.translationX(progress: positionProgress),
            y: metrics.celestialVerticalInset
        )
        .allowsHitTesting(false)
    }
}
```

Delete the old Boolean-specific crossfade and translation animation properties. Leave `SunDisc`, `MoonDisc`, and `MoonOcclusionShape` artwork unchanged.

- [ ] **Step 2: Convert `ToggleTrack` to progress crossfades**

Change its input to `let progress: CGFloat`. Replace each Boolean scene opacity with:

```swift
DayScene(reduceMotion: reduceMotion)
    .opacity(1 - progress)

NightScene(reduceMotion: reduceMotion)
    .opacity(progress)
```

Render the day and night base, border, and inner edge as two stacked treatments with opacities `1 - progress` and `progress`. Define fixed `dayBorderGradient`, `nightBorderGradient`, `dayInnerEdgeGradient`, and `nightInnerEdgeGradient` values; remove `crossfadeAnimation` and every view-local `.animation(..., value: isDarkMode)` from `ToggleTrack`.

- [ ] **Step 3: Add the animatable visual container**

Place this private view beside `ToggleTrack` in `DarkModeToggle.swift`:

```swift
private struct DarkModeToggleVisuals: View, Animatable {
    var appearanceProgress: CGFloat
    var positionProgress: CGFloat
    let metrics: DarkModeToggleMetrics
    let reduceMotion: Bool
    let onDragChanged: (DragGesture.Value, CGFloat) -> Void
    let onDragEnded: (DragGesture.Value) -> Void

    var animatableData: AnimatablePair<CGFloat, CGFloat> {
        get { AnimatablePair(appearanceProgress, positionProgress) }
        set {
            appearanceProgress = newValue.first
            positionProgress = newValue.second
        }
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            ToggleTrack(
                progress: appearanceProgress,
                metrics: metrics,
                reduceMotion: reduceMotion
            )
            .offset(y: (metrics.componentHeight - metrics.trackHeight) / 2)

            CelestialThumb(
                appearanceProgress: appearanceProgress,
                positionProgress: positionProgress,
                metrics: metrics
            )
        }
        .frame(
            width: metrics.width,
            height: metrics.componentHeight,
            alignment: .topLeading
        )
        .contentShape(Rectangle())
        .simultaneousGesture(
            DragGesture(
                minimumDistance: DarkModeToggleInteraction.dragThreshold,
                coordinateSpace: .local
            )
            .onChanged { value in
                onDragChanged(value, positionProgress)
            }
            .onEnded(onDragEnded)
        )
    }
}
```

The closure receives the animatable container's current presented position progress, not the Boolean endpoint.

- [ ] **Step 4: Implement component state and gesture lifecycle**

Add these private state values to `DarkModeToggle`:

```swift
@State private var committedProgress: CGFloat
@State private var dragProgress: CGFloat?
@State private var dragStartProgress: CGFloat?
@State private var dragOriginTranslationX: CGFloat?
@State private var dragAxis: DarkModeToggleDragAxis?
```

Initialize committed progress from the binding:

```swift
public init(isDarkMode: Binding<Bool>) {
    _isDarkMode = isDarkMode
    _committedProgress = State(
        initialValue: DarkModeToggleInteraction.restingProgress(
            isDarkMode: isDarkMode.wrappedValue
        )
    )
}
```

Use these display properties:

```swift
private var endpointProgress: CGFloat {
    DarkModeToggleInteraction.restingProgress(isDarkMode: isDarkMode)
}

private var appearanceProgress: CGFloat {
    dragProgress ?? committedProgress
}

private var positionProgress: CGFloat {
    if let dragProgress {
        return dragProgress
    }
    return reduceMotion ? endpointProgress : committedProgress
}
```

Construct `DarkModeToggleVisuals` inside the existing `GeometryReader` and route its callbacks to methods with `metrics.translationTravel`.

Implement gesture change with a no-animation transaction and a translation origin captured at the 10-point recognition threshold:

```swift
private func dragChanged(
    _ value: DragGesture.Value,
    presentedProgress: CGFloat,
    travel: CGFloat
) {
    if dragAxis == nil {
        dragAxis = DarkModeToggleInteraction.axis(for: value.translation)
        dragStartProgress = presentedProgress
        dragOriginTranslationX = value.translation.width
    }

    guard dragAxis == .horizontal,
          let dragStartProgress,
          let dragOriginTranslationX else {
        return
    }

    var transaction = Transaction()
    transaction.animation = nil
    withTransaction(transaction) {
        dragProgress = DarkModeToggleInteraction.progress(
            startingAt: dragStartProgress,
            translation: value.translation.width - dragOriginTranslationX,
            travel: travel
        )
    }
}
```

Implement release resolution using predicted translation minus the same recognition origin. A vertical sequence clears gesture state without committing. A horizontal sequence writes the binding only if its value changes, updates `committedProgress`, clears `dragProgress`, and uses:

```swift
Animation.spring(response: 0.35, dampingFraction: 0.82)
```

or, under Reduce Motion:

```swift
Animation.easeOut(duration: 0.2)
```

For Reduce Motion tap/VoiceOver activation, write the Boolean outside an animation so `positionProgress` snaps to the endpoint, then animate only `committedProgress` for the 0.2-second appearance crossfade.

- [ ] **Step 5: Keep real Button semantics without duplicate drag activation**

Use a private `PrimitiveButtonStyle` so a physical tap calls `configuration.trigger()` once while the label's 10-point `DragGesture` owns claimed drags:

```swift
private struct DarkModeToggleButtonStyle: PrimitiveButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .contentShape(Rectangle())
            .gesture(
                TapGesture()
                    .onEnded { configuration.trigger() }
            )
    }
}
```

Apply `.buttonStyle(DarkModeToggleButtonStyle())` and preserve the existing label, value, hint, identifier, and selected trait. Standard Button activation remains available to VoiceOver and automation, while a movement that invalidates the tap cannot also call the action.

- [ ] **Step 6: Synchronize external binding changes**

Add `.onChange(of: isDarkMode)` to update `committedProgress` when a consumer writes the binding outside this control. Ignore synchronization while a drag is active. Use the same spring normally and the same 0.2-second appearance-only transition under Reduce Motion.

- [ ] **Step 7: Run Package tests**

```bash
xcodebuildmcp swift-package test \
  --package-path /tmp/DarkModeToggle-issue-1 \
  --configuration Debug
```

Expected: every Package test passes. Compiler warnings introduced by the new gesture closures or animation state are treated as failures to resolve before committing.

- [ ] **Step 8: Commit the progress-driven visuals**

```bash
git add Sources/DarkModeSwitchDemoFeature/DarkModeToggle.swift \
  Sources/DarkModeSwitchDemoFeature/CelestialThumb.swift
git commit -m "feat(toggle): follow horizontal drag progress"
```

## Task 4: Document, review, verify, and publish Package 3.0.0

**Files:**
- Modify: `README.md`

- [ ] **Step 1: Update Package documentation**

Change installation examples from `2.0.0` to `3.0.0`, describe tap plus horizontal drag, document predicted-endpoint snapping and the 10-point threshold, explain Reduce Motion direct manipulation versus non-elastic settling, list the new interaction tests, and add this release-history item:

```markdown
- `3.0.0`: adds continuous horizontal drag, predicted-endpoint snapping, and
  one shared progress for the thumb and day/night artwork; the public
  `Binding<Bool>` initializer is unchanged.
```

Retain the 2.0 and 1.0 history and repository-boundary explanation.

- [ ] **Step 2: Commit Package documentation**

```bash
git add README.md
git commit -m "docs(package): document interactive drag release"
```

- [ ] **Step 3: Run final Package verification and inspect the diff**

Run the full Package suite again, then:

```bash
git diff 2.0.0...HEAD --check
git diff 2.0.0...HEAD --stat
git status --short --branch
```

Expected: tests pass, no whitespace errors, only intended source/test/README files changed, and the Package worktree is clean.

- [ ] **Step 4: Review against the approved specification**

Use `superpowers:requesting-code-review`. Resolve every High or Medium correctness issue, rerun relevant tests after any fix, and commit fixes with narrow `fix(toggle): ...` messages.

- [ ] **Step 5: Push Package main and create the annotated release Tag**

After `superpowers:verification-before-completion` confirms fresh evidence:

```bash
git push origin HEAD:main
git tag -a 3.0.0 -m "DarkModeToggle 3.0.0"
git push origin 3.0.0
```

Verify local Tag type and remote dereference:

```bash
git cat-file -t 3.0.0
git rev-parse 3.0.0^{}
git ls-remote origin refs/heads/main refs/tags/3.0.0 refs/tags/3.0.0^{}
```

Expected: Tag type is `tag`; local dereference, remote `main`, and remote peeled Tag all identify the same Package commit. Existing `1.0.0` and `2.0.0` Tags remain unchanged.

## Task 5: Upgrade the App and turn the UI suite green

**Files:**
- Modify: `DarkModeSwitchDemo/DarkModeSwitchDemo.xcodeproj/project.pbxproj`
- Modify: `DarkModeSwitchDemo/DarkModeSwitchDemo.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved`
- Modify: `DarkModeSwitchDemo/DarkModeSwitchDemo.xcworkspace/xcshareddata/swiftpm/Package.resolved`

- [ ] **Step 1: Raise the remote dependency minimum**

In the isolated App worktree, change only:

```text
minimumVersion = 2.0.0;
```

to:

```text
minimumVersion = 3.0.0;
```

Do not add a local Package reference and do not touch signing configuration.

- [ ] **Step 2: Resolve and build against remote 3.0.0**

```bash
xcodebuildmcp simulator build \
  --project-path DarkModeSwitchDemo/DarkModeSwitchDemo.xcodeproj \
  --scheme DarkModeSwitchDemo \
  --simulator-name "iPhone Air" \
  --configuration Debug
```

Expected: build succeeds and the project lock file resolves `version: 3.0.0` at the Package Tag commit. Copy the exact same resolved file content to the workspace lock-file path using `apply_patch`, not a shell overwrite.

- [ ] **Step 3: Run all App UI tests**

```bash
xcodebuildmcp simulator test \
  --workspace-path DarkModeSwitchDemo/DarkModeSwitchDemo.xcworkspace \
  --scheme DarkModeSwitchDemo \
  --simulator-name "iPhone Air" \
  --configuration Debug
```

Expected: the original tap reversal and persistence tests plus all new drag tests pass. The element remains `app.buttons["darkModeToggle"]`, the first drag ends `On`, reverse drag ends `Off`, vertical drag remains `Off`, and the immediate post-drag tap works.

- [ ] **Step 4: Diagnose any failure before changing code**

If build or tests fail, invoke `superpowers:systematic-debugging`, capture the exact failure, reproduce it with the smallest relevant test, and change only the proven cause. Rerun the failing test first, then both full suites.

- [ ] **Step 5: Commit App dependency integration**

```bash
git add DarkModeSwitchDemo/DarkModeSwitchDemo.xcodeproj/project.pbxproj \
  DarkModeSwitchDemo/DarkModeSwitchDemo.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved \
  DarkModeSwitchDemo/DarkModeSwitchDemo.xcworkspace/xcshareddata/swiftpm/Package.resolved
git commit -m "chore(spm): upgrade toggle to 3.0.0"
```

The earlier UI-test commit remains separate.

## Task 6: Update App documentation and complete two-repository verification

**Files:**
- Modify: `README.md`
- Modify: `DarkModeSwitchDemo/CLAUDE.md`

- [ ] **Step 1: Update App documentation**

Update every current-version reference from 2.0.0 to 3.0.0, add drag to the state-flow diagram, document progress/predicted snapping and Reduce Motion behavior, update the test count and release explanation, and retain the rule that `ContentView` belongs to the App.

In `CLAUDE.md`, change the resolved release to 3.0.0 and state that reusable gesture/progress behavior belongs to the Package while App appearance orchestration remains local.

- [ ] **Step 2: Commit App documentation**

```bash
git add README.md DarkModeSwitchDemo/CLAUDE.md
git commit -m "docs(app): explain interactive toggle release"
```

- [ ] **Step 3: Run fresh final verification**

Invoke `superpowers:verification-before-completion`, then run:

```bash
xcodebuildmcp swift-package test --package-path /tmp/DarkModeToggle-issue-1 --configuration Debug
xcodebuildmcp simulator test --workspace-path DarkModeSwitchDemo/DarkModeSwitchDemo.xcworkspace --scheme DarkModeSwitchDemo --simulator-name "iPhone Air" --configuration Debug
xcodebuildmcp simulator build --project-path DarkModeSwitchDemo/DarkModeSwitchDemo.xcodeproj --scheme DarkModeSwitchDemo --simulator-name "iPhone Air" --configuration Debug
```

Install and launch the built App on the same simulator with XcodeBuildMCP. Confirm it reaches the foreground without a crash.

- [ ] **Step 4: Inspect App history and preserve the user's working tree**

```bash
git diff 43a8503...HEAD --check
git status --short --branch
git log --oneline --decorate 43a8503..HEAD
```

Expected: isolated App worktree is clean, history includes the design, plan, red UI test, dependency integration, and docs. In the original worktree, the user's signing/layout diffs and untracked audit directory are still present and uncommitted.

- [ ] **Step 5: Review and publish the App**

Use `superpowers:requesting-code-review`, resolve correctness findings, rerun the affected verification, then push the verified implementation branch to remote `main` without force:

```bash
git push origin HEAD:main
```

Verify:

```bash
git ls-remote origin refs/heads/main
gh repo view HideOnBushTuT/DarkModeSwitchButton --json isPrivate,defaultBranchRef
gh repo view HideOnBushTuT/DarkModeToggle --json isPrivate,defaultBranchRef
```

Expected: both repositories remain private with default branch `main`; App remote `main` matches the verified App commit; Package remote `main` and annotated `3.0.0` resolve to the verified Package commit.

- [ ] **Step 6: Clean only temporary worktrees and report completion**

Post the verified Package/App commit IDs, test results, and `3.0.0` Tag
dereference to Issue #1, then close it as completed:

```bash
gh issue comment 1 \
  --repo HideOnBushTuT/DarkModeSwitchButton \
  --body "DarkModeToggle 3.0.0 published and App integration verified."
gh issue close 1 \
  --repo HideOnBushTuT/DarkModeSwitchButton \
  --reason completed
```

Use Git worktree removal for the clean isolated App worktree and delete only
the exact `/tmp/DarkModeToggle-issue-1` clone. Never remove the user's original
worktree or `audit-dribbble-toggle/` directory. Report Issue/branch status,
Package/App commit IDs, Tag object and peeled commit, test counts, build/launch
result, and the preserved uncommitted user files.
