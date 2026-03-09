# Amethyst — TODO

## 🚨 SwiftLint Violations (Code Style & Quality)

- [ ] **Identifier Name Violation** (`UserConfiguration.swift`)
    - **Issue:** `focusFollowsWindowThrownBetweenSpacesDelay` is too long (42 chars > 40 limit).
    - **Fix:** Rename to `focusFollowsWindowThrownDelay` or similar.
- [ ] **Inclusive Language Violations** (`UserConfiguration.swift`)
    - **Issue:** Variables `floatingBundleIdentifiersIsBlacklist` and `useIdentifiersAsBlacklist` use the term "blacklist".
    - **Fix:** Rename variables to use "Blocklist" or "Excludelist" (e.g., `floatingBundleIdentifiersIsBlocklist`). *Note: Ensure this doesn't break the underlying configuration key if it relies on the variable name.*
- [ ] **Cyclomatic Complexity** (`LayoutType.swift`)
    - **Issue:** Function at line 169 is too complex (score 18 > 15).
    - **Fix:** Refactor the function by extracting logic into smaller helper functions.
- [ ] **Todo Violation** (`ScreenManager.swift`)
    - **Issue:** Unresolved TODOs "fix mff".
    - **Fix:** Address the TODO or convert it to a proper issue tracker reference/comment if not fixing immediately.
- [ ] **Unused Enumerated** (`RowLayoutTests.swift`, `ColumnLayoutTests.swift`)
    - **Issue:** Using `.enumerated()` when the item isn't used.
    - **Fix:** Replace `for (index, _) in something.enumerated()` with `for index in something.indices`.

## ⚠️ API Deprecations (macOS & Libraries)

- [ ] **NSValueTransformerName** (`HotKeyRegistrar.swift`)
    - **Issue:** `keyedUnarchiveFromDataTransformerName` is deprecated.
    - **Fix:** Update to `NSValueTransformerName.secureUnarchiveFromDataTransformerName`.
- [ ] **NSStatusItem** (`AppDelegate.swift`)
    - **Issue:** Direct property access `statusItem?.image` and `statusItem?.highlightMode` is deprecated.
    - **Fix:** Access via the button property: `statusItem?.button?.image = ...` and `statusItem?.button?.cell?.highlightsBy = ...`.
- [ ] **Sparkle Framework** (`AppDelegate.swift`)
    - **Issue:** `SUUpdater` is deprecated in Sparkle 2.
    - **Fix:** Migrate to `SPUStandardUpdaterController` (Standard User Driver) or `SPUUpdater`. This is a slightly larger change involving initialization.

## Release & CI/CD

- [ ] **Run `bundle install` to generate `Gemfile.lock`** — newly added Gemfile needs lock file committed
- [ ] **Set up App Store Connect API Key** — generate key in ASC > Users and Access > Keys, then set `ASC_KEY_ID`, `ASC_ISSUER_ID`, `ASC_KEY_CONTENT` as GitHub secrets for future App Store automation
- [ ] **Add version bump lane** — automate `increment_version_number` / `increment_build_number` in Fastfile

## Dependency Warnings (Silica)

- [ ] **Umbrella Header Warnings**
    - **Issue:** The `Silica` library (managed via SwiftPM) has missing headers in its umbrella header.
    - **Action:** Ignore for now as it is an external dependency.
