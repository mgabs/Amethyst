# Amethyst — TODO

## 🚨 SwiftLint Violations (Code Style & Quality)

- [x] **Identifier Name Violation** (`UserConfiguration.swift`)
    - **Issue:** `focusFollowsWindowThrownBetweenSpacesDelay` is too long (42 chars > 40 limit).
    - **Fix:** Rename to `focusFollowsWindowThrownDelay`.
- [x] **Inclusive Language Violations** (`UserConfiguration.swift`)
    - **Issue:** Variables `floatingBundleIdentifiersIsBlacklist` and `useIdentifiersAsBlacklist` use the term "blacklist".
    - **Fix:** Rename variables to use "Blocklist" or "Excludelist" (e.g., `floatingBundleIdentifiersIsBlocklist`). *Note: Underlying configuration key 'floating-is-blacklist' was kept to maintain backward compatibility.*
- [ ] **Cyclomatic Complexity** (`LayoutType.swift`)
    - **Issue:** Function at line 169 is too complex (score 18 > 15).
    - **Fix:** Refactor the function by extracting logic into smaller helper functions. (Note: A similar violation in `LayoutTypeTests.swift` was already fixed by simplifying the `==` implementation).
- [ ] **Todo Violation** (`ScreenManager.swift`)
    - **Issue:** Unresolved TODOs "fix mff".
    - **Fix:** Address the TODO or convert it to a proper issue tracker reference/comment if not fixing immediately. (Note: This TODO could not be found in the current source code).
- [x] **Unused Enumerated** (`RowLayoutTests.swift`, `ColumnLayoutTests.swift`)
    - **Issue:** Using `.enumerated()` when the item isn't used.
    - **Fix:** Replace `for (index, _) in something.enumerated()` with `for index in something.indices`.

## ⚠️ API Deprecations (macOS & Libraries)

- [x] **NSValueTransformerName** (`HotKeyRegistrar.swift`)
    - **Issue:** `keyedUnarchiveFromDataTransformerName` is deprecated.
    - **Fix:** Update to `NSValueTransformerName.secureUnarchiveFromDataTransformerName`.
- [x] **NSStatusItem** (`AppDelegate.swift`)
    - **Issue:** Direct property access `statusItem?.image` and `statusItem?.highlightMode` is deprecated.
    - **Fix:** Access via the button property: `statusItem?.button?.image = ...` and `statusItem?.button?.cell?.highlightsBy = ...`.
- [ ] **Sparkle Framework** (`AppDelegate.swift`)
    - **Issue:** `SUUpdater` is deprecated in Sparkle 2.
    - **Fix:** Migrate to `SPUStandardUpdaterController` (Standard User Driver) or `SPUUpdater`. This is a slightly larger change involving initialization.

## Release & CI/CD

- [x] **Run `bundle install` to generate `Gemfile.lock`** — newly added Gemfile needs lock file committed
- [ ] **Set up App Store Connect API Key** — generate key in ASC > Users and Access > Keys, then set `ASC_KEY_ID`, `ASC_ISSUER_ID`, `ASC_KEY_CONTENT` as GitHub secrets for future App Store automation
- [ ] **Add version bump lane** — automate `increment_version_number` / `increment_build_number` in Fastfile

## Dependency Warnings (Silica)

- [ ] **Umbrella Header Warnings**
    - **Issue:** The `Silica` library (managed via SwiftPM) has missing headers in its umbrella header.
    - **Action:** Ignore for now as it is an external dependency.


Based on a review of the Amethyst codebase, here are 4 significant areas for improvement regarding Separation of Concerns (SoC) and Security, focusing on architectural patterns, accessibility permissions handling, and data persistence:
1. Architecture & SoC: The WindowManager "God Class"
*   The Issue: The WindowManager class (Amethyst/Managers/WindowManager.swift) is a massive "God Class" that severely violates the Single Responsibility Principle. It concurrently acts as:
    *   An NSWorkspace application lifecycle observer.
    *   A subscriber to raw Accessibility API window events (moves/resizes).
    *   The orchestrator for layout reflow algorithms.
    *   A data model (conforming to Codable for state persistence).
*   The Fix: Deconstruct WindowManager into specialized, isolated components. Create an ApplicationLifecycleObserver for workspace changes, a WindowAccessibilityTracker to abstract low-level system event streams, and a focused LayoutCoordinator to calculate frame assignments. This vastly improves modularity and testability.
2. Data Persistence: Complex State Serialization in UserDefaults
*   The Issue: When the app terminates (AppDelegate.applicationWillTerminate), the entire WindowManager state is encoded into a massive JSON payload and saved directly into UserDefaults (using the "EncodedWindowManager" key). UserDefaults is optimized for lightweight user preferences, not for storing complex, bloated serialized application state.
*   The Fix: Separate internal application state from user preferences. The encoded layout and window state should be written to a dedicated .json or .plist file within the app's Application Support directory. This prevents UserDefaults bloat, protects against potential corruption of simple user settings, and can improve application launch performance.
3. Security & UX: Accessibility Permissions as a Side-Effect
*   The Issue: Amethyst requires the macOS Accessibility API to function. Currently, the OS-level permission prompt is triggered via AXIsProcessTrustedWithOptions directly inside UserConfiguration.swift (confirmAccessibilityPermissions()). UserConfiguration should be a pure data store, yet it executes a major system-level security side-effect during AppDelegate.applicationDidBecomeActive.
*   The Fix: Decouple security actions from configuration storage. Introduce a dedicated AccessibilityPermissionCoordinator. Because this API grants the app significant control over the user's system (a major security surface), this coordinator should manage a clear onboarding flow that explains why the permission is necessary before prompting the OS dialog, rather than firing it implicitly as a byproduct of a config check.
4. Event Architecture: Global NotificationCenter Coupling
*   The Issue: Core components like WindowManager and AppDelegate rely heavily on direct subscriptions to global notifications (NotificationCenter.default and NSWorkspace.shared.notificationCenter) for inter-component communication (like the custom Space Indicator notifications we just added). This creates implicit, hard-to-trace dependencies across the app.
*   The Fix: Since the codebase already heavily utilizes RxSwift, the architecture should bridge these generic global notifications into strongly-typed Rx Observables or a dedicated central Event Bus. This ensures that UI components and background managers subscribe to explicit, mockable event streams rather than relying on untyped, global system dispatchers.
