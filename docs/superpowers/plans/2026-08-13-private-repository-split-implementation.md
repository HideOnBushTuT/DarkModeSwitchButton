# Private Repository Split Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (- [ ]) syntax for tracking.

**Goal:** Publish the application and its reusable Swift package as two private GitHub repositories, with the app consuming a tagged remote package and both repositories containing accurate documentation.

**Architecture:** Extract the existing local package history into HideOnBushTuT/DarkModeToggle, publish release 1.0.0, then replace the app project's local package reference with an up-to-next-major remote dependency. Keep package unit tests in the package repository and application UI tests in HideOnBushTuT/DarkModeSwitchButton.

**Tech Stack:** Git, GitHub CLI, Swift Package Manager, Swift 6.1, SwiftUI, Xcode project files, XcodeBuildMCP, Swift Testing, XCUITest

---

## File map

### DarkModeToggle repository

- Package.swift declares the iOS 17 library product.
- Sources/DarkModeSwitchDemoFeature contains the reusable toggle.
- Tests/DarkModeSwitchDemoFeatureTests contains geometry and artwork regression tests.
- README.md explains installation, usage, implementation, testing, and versioning.
- THIRD_PARTY_NOTICES.md preserves the upstream MIT notice.

### DarkModeSwitchButton repository

- README.md is the detailed Chinese project guide.
- DarkModeSwitchDemo/README.md points readers to the root guide.
- DarkModeSwitchDemo/CLAUDE.md describes the correct iOS 17 deployment target.
- DarkModeSwitchDemo/DarkModeSwitchDemo.xcodeproj/project.pbxproj owns the remote package dependency.
- DarkModeSwitchDemo/DarkModeSwitchDemo.xcworkspace/contents.xcworkspacedata contains only the app project.
- DarkModeSwitchDemo/DarkModeSwitchDemo/DarkModeSwitchDemo.xctestplan contains only the UI test target.
- DarkModeSwitchDemo/DarkModeSwitchDemoPackage is removed after the remote release is verified.

### Task 1: Extract and document the package repository

**Files:**
- Create in extracted repository: README.md
- Create in extracted repository: THIRD_PARTY_NOTICES.md
- Preserve: Package.swift, Sources, Tests

- [ ] **Step 1: Extract package-only history**

Run:

    git subtree split \
      --prefix=DarkModeSwitchDemo/DarkModeSwitchDemoPackage \
      -b release/dark-mode-toggle-1.0.0

Expected: the branch root contains Package.swift, Sources, and Tests and excludes app-only commits.

- [ ] **Step 2: Create an independent temporary clone**

Run:

    split_root="$(mktemp -d /tmp/dark-mode-toggle-split.XXXXXX)"
    git clone \
      --branch release/dark-mode-toggle-1.0.0 \
      --single-branch \
      . \
      "$split_root/DarkModeToggle"
    git -C "$split_root/DarkModeToggle" branch -M main

Expected: the clone has an independent .git directory, preventing package remote configuration from changing the app repository.

- [ ] **Step 3: Add the package documentation**

Create README.md with these exact sections:

    # DarkModeToggle
    ## 效果与能力
    ## 安装
    ## 使用
    ## 对外 API
    ## 内部实现
    ## 动画与 Reduce Motion
    ## 测试
    ## 版本规则
    ## 来源与许可证

The installation snippet references https://github.com/HideOnBushTuT/DarkModeToggle.git from version 1.0.0. The usage snippet imports DarkModeSwitchDemoFeature and constructs DarkModeToggle(isDarkMode: $isDarkMode).

Copy the full root THIRD_PARTY_NOTICES.md into the extracted repository.

- [ ] **Step 4: Verify and commit package documentation**

Run:

    git -C "$split_root/DarkModeToggle" diff --check
    rg -n 'TBD|TODO|FIXME|DarkModeTogglePackage' \
      "$split_root/DarkModeToggle/README.md" \
      "$split_root/DarkModeToggle/THIRD_PARTY_NOTICES.md"
    git -C "$split_root/DarkModeToggle" status --short

Expected: no placeholders or old repository name; only README.md and THIRD_PARTY_NOTICES.md are new.

Commit:

    git -C "$split_root/DarkModeToggle" add README.md THIRD_PARTY_NOTICES.md
    git -C "$split_root/DarkModeToggle" commit \
      -m "docs(package): add usage and attribution"

### Task 2: Test and publish DarkModeToggle 1.0.0

**Files:**
- Verify: extracted package repository
- Publish: HideOnBushTuT/DarkModeToggle

- [ ] **Step 1: Run package unit tests**

Run:

    xcodebuildmcp swift-package test \
      --package-path "$split_root/DarkModeToggle" \
      --configuration Debug

Expected: all four Swift Testing tests pass with zero failures.

- [ ] **Step 2: Create the private repository**

Run:

    git -C "$split_root/DarkModeToggle" remote remove origin
    gh repo create HideOnBushTuT/DarkModeToggle \
      --private \
      --source "$split_root/DarkModeToggle" \
      --remote origin \
      --push

Expected: the private repository exists with main as its default branch.

- [ ] **Step 3: Publish and verify release 1.0.0**

Run:

    git -C "$split_root/DarkModeToggle" tag -a 1.0.0 \
      -m "DarkModeToggle 1.0.0"
    git -C "$split_root/DarkModeToggle" push origin 1.0.0
    gh repo view HideOnBushTuT/DarkModeToggle \
      --json nameWithOwner,visibility,defaultBranchRef,url
    gh api repos/HideOnBushTuT/DarkModeToggle/git/ref/tags/1.0.0
    git ls-remote https://github.com/HideOnBushTuT/DarkModeToggle.git \
      refs/heads/main refs/tags/1.0.0

Expected: visibility is PRIVATE, default branch is main, and the main and 1.0.0 refs exist.

### Task 3: Replace the embedded package with the remote release

**Files:**
- Modify: DarkModeSwitchDemo/DarkModeSwitchDemo.xcodeproj/project.pbxproj
- Modify: DarkModeSwitchDemo/DarkModeSwitchDemo.xcworkspace/contents.xcworkspacedata
- Modify: DarkModeSwitchDemo/DarkModeSwitchDemo/DarkModeSwitchDemo.xctestplan
- Delete: DarkModeSwitchDemo/DarkModeSwitchDemoPackage

- [ ] **Step 1: Remove local workspace and test-plan references**

The workspace retains only container:DarkModeSwitchDemo.xcodeproj. The test plan removes DarkModeSwitchDemoFeatureTests and retains DarkModeSwitchDemoUITests.

- [ ] **Step 2: Remove the embedded package**

Run:

    git rm -r DarkModeSwitchDemo/DarkModeSwitchDemoPackage

Expected: the source removal is staged only after the package remote and tag are verified.

- [ ] **Step 3: Verify the old configuration fails**

Run:

    xcodebuildmcp simulator build \
      --project-path DarkModeSwitchDemo/DarkModeSwitchDemo.xcodeproj \
      --scheme DarkModeSwitchDemo \
      --simulator-name "iPhone Air" \
      --configuration Debug

Expected: the build reports the missing local package, proving a remote reference is required.

- [ ] **Step 4: Add the remote package reference**

Keep UUID 8B41F6862DEEFA12001A66F9 and change it to XCRemoteSwiftPackageReference with:

    repositoryURL = "https://github.com/HideOnBushTuT/DarkModeToggle.git";
    requirement = {
        kind = upToNextMajorVersion;
        minimumVersion = 1.0.0;
    };

Both XCSwiftPackageProductDependency objects reference that UUID and keep productName = DarkModeSwitchDemoFeature.

- [ ] **Step 5: Resolve, build, and verify**

Run the XcodeBuildMCP build from Step 3 again.

Expected: Xcode resolves DarkModeToggle at 1.0.0 and the build succeeds.

Then run:

    rg -n 'DarkModeToggle|1\.0\.0|DarkModeSwitchDemoFeature' \
      DarkModeSwitchDemo/DarkModeSwitchDemo.xcodeproj \
      DarkModeSwitchDemo/DarkModeSwitchDemo.xcworkspace \
      DarkModeSwitchDemo/DarkModeSwitchDemo/DarkModeSwitchDemo.xctestplan
    git diff --check

- [ ] **Step 6: Commit the remote dependency**

Stage the project, workspace, test plan, package deletion, and generated Package.resolved. Commit:

    git commit -m "chore(spm): consume remote toggle package"

### Task 4: Write detailed application documentation

**Files:**
- Modify: README.md
- Modify: DarkModeSwitchDemo/README.md
- Modify: DarkModeSwitchDemo/CLAUDE.md

- [ ] **Step 1: Replace the root README**

Keep the light/dark screenshot table and add these sections:

    # Dark Mode Switch Button
    ## 项目简介
    ## 运行环境
    ## 获取与运行
    ## 两仓库架构
    ## 目录结构
    ## SwiftUI 状态流
    ## 动画组件拆解
    ## 关键尺寸与动画参数
    ## 云层、星星、太阳和月亮如何绘制
    ## Reduce Motion 与无障碍
    ## 为什么使用独立 SPM
    ## 测试策略与命令
    ## 常见编译问题
    ## 设计来源与许可证

Explain @AppStorage("isDarkMode"), @Binding, preferredColorScheme, scene crossfades, celestial translation, masks, source-art data, exact timings, private-package authentication, and that SPM is an architecture choice rather than an animation requirement.

- [ ] **Step 2: Remove stale scaffold documentation**

Replace DarkModeSwitchDemo/README.md with a short Chinese pointer to ../README.md. Change the opening deployment-target statement in DarkModeSwitchDemo/CLAUDE.md from iOS 18+ to iOS 17+.

- [ ] **Step 3: Validate and commit documentation**

Run:

    rg -n 'iOS 18|local package|DarkModeTogglePackage|TBD|TODO|FIXME' \
      README.md DarkModeSwitchDemo/README.md DarkModeSwitchDemo/CLAUDE.md
    git diff --check

Expected: no stale deployment target, local-package instructions, old repository name, placeholders, or whitespace errors.

Commit:

    git add README.md DarkModeSwitchDemo/README.md DarkModeSwitchDemo/CLAUDE.md
    git commit -m "docs(readme): explain implementation and repository split"

### Task 5: Run final application verification

**Files:**
- Verify: app project and UI tests

- [ ] **Step 1: Build the app from the direct project**

Run:

    xcodebuildmcp simulator build \
      --project-path DarkModeSwitchDemo/DarkModeSwitchDemo.xcodeproj \
      --scheme DarkModeSwitchDemo \
      --simulator-name "iPhone Air" \
      --configuration Debug

Expected: build succeeds using DarkModeToggle 1.0.0.

- [ ] **Step 2: Run app UI tests**

Run:

    xcodebuildmcp simulator test \
      --workspace-path DarkModeSwitchDemo/DarkModeSwitchDemo.xcworkspace \
      --scheme DarkModeSwitchDemo \
      --simulator-name "iPhone Air" \
      --configuration Debug

Expected: both UI tests pass with zero failures.

- [ ] **Step 3: Build and launch once**

Run:

    xcodebuildmcp simulator build-and-run \
      --project-path DarkModeSwitchDemo/DarkModeSwitchDemo.xcodeproj \
      --scheme DarkModeSwitchDemo \
      --simulator-name "iPhone Air" \
      --configuration Debug

Expected: the app installs and launches on the simulator.

- [ ] **Step 4: Audit repository contents**

Run:

    git diff --check
    git status --short --branch
    git ls-files | rg 'audit-dribbble-toggle|DarkModeSwitchDemoPackage'
    rg -n 'XCLocalSwiftPackageReference|group:DarkModeSwitchDemoPackage' \
      DarkModeSwitchDemo || true

Expected: no uncommitted project changes, audit-dribbble-toggle remains untracked, the embedded package is absent, and no local package reference remains.

### Task 6: Publish the application repository

**Files:**
- Publish: HideOnBushTuT/DarkModeSwitchButton

- [ ] **Step 1: Fast-forward main**

Run:

    git switch main
    git merge --ff-only feat/dark-mode-toggle-demo

Expected: main contains the complete history without a merge commit.

- [ ] **Step 2: Create and push the private app repository**

Run:

    gh repo create HideOnBushTuT/DarkModeSwitchButton \
      --private \
      --source . \
      --remote origin \
      --push

Expected: GitHub creates the private app repository and pushes main.

- [ ] **Step 3: Verify the app remote**

Run:

    gh repo view HideOnBushTuT/DarkModeSwitchButton \
      --json nameWithOwner,visibility,defaultBranchRef,url
    git remote -v
    git status --short --branch
    git ls-remote origin refs/heads/main

Expected: visibility is PRIVATE, default branch is main, local main tracks origin/main, and audit-dribbble-toggle remains untracked and unpushed.
