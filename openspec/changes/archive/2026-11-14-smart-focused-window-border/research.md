# Research & Technical Tradeoffs

## 1. Intent & Ground Truth
- **Problem**: Amethyst draws the focused window border even when only one tiled window is on the screen's current space or when the screen is using `FullscreenLayout`, where focus is unambiguous.
- **Verified codebase facts**:
  - `FocusedWindowBorder.isEligible(tracked:managed:spaceType:windowSpaceID:screenSpaceID:)` (`Amethyst/View/FocusedWindowBorder.swift:115-129`) already excludes macOS native fullscreen (`spaceType == CGSSpaceTypeUser` required).
  - `WindowManager.updateFocusedWindowBorder(focused:)` (`Amethyst/Managers/WindowManager.swift:1174-1213`) controls showing/hiding `focusedWindowBorder` using `userConfiguration.focusedWindowBorderEnabled()` and `FocusedWindowBorder.isEligible(...)`.
  - `WindowManager.activeWindows(on: Screen)` (`Amethyst/Managers/WindowManager.swift:1068-1071`) returns non-floating, non-hidden, managed windows on the screen's current space.
  - Precedent: `smart-window-margins` (`Amethyst/Preferences/UserConfiguration.swift:73, 739`, `Amethyst/Managers/ScreenManager.swift:325`, `Amethyst/Layout/Layouts/FullscreenLayout.swift:18, 34`) is a config-only boolean (default `false`) that drops margins for single tiled windows (ignoring floating windows) and `FullscreenLayout`.
  - All `focused-window-border*` keys (`UserConfiguration.swift:90-92`) are config-only with no Preferences UI controls.
  - `openspec/specs/` contains no existing durable specs.

## 2. Options Explored
- **Option A: Single config-only boolean `smart-focused-window-border` (default `false`) + pure eligibility extension**
  - Add `smartFocusedWindowBorder = "smart-focused-window-border"` to `UserConfiguration` (default `false`, matching `smart-window-margins` and `default.amethyst`).
  - Extend `FocusedWindowBorder.isEligible(...)` with optional/defaulted parameters (e.g., `smartBorder: Bool = false`, `isFullscreenLayout: Bool = false`, `tiledWindowCount: Int? = nil`) and pass screen layout + `activeWindows(on: screen).count` from `WindowManager.updateFocusedWindowBorder`.
  - **Pros**: Mirrors `smart-window-margins`; keeps eligibility pure and unit-testable without WindowServer; minimal diff and zero UI churn.
  - **Cons**: Cannot toggle single-window and `FullscreenLayout` hiding independently.
- **Option B: Separate config keys (`focused-window-border-hide-single`, `focused-window-border-hide-fullscreen`)**
  - Two independent booleans in `UserConfiguration` and `default.amethyst`.
  - **Pros**: Independent control per condition.
  - **Cons**: Larger config surface, breaks symmetry with `smart-window-margins`, unnecessary per user confirmation.
- **Option C: Inline check in `WindowManager.updateFocusedWindowBorder` only**
  - Gate border display directly inside `WindowManager` without updating `FocusedWindowBorder.isEligible`.
  - **Pros**: Leaves `FocusedWindowBorder.isEligible` signature untouched.
  - **Cons**: Couples pure eligibility rules to `WindowManager` state, making unit testing harder.

## 3. Tradeoff Matrix

| Criteria | Option A | Option B | Option C |
| :--- | :--- | :--- | :--- |
| **Complexity** | Low | Medium | Low |
| **New Dependencies** | None | None | None |
| **Performance & Latency** | Negligible (1 layout type check + `activeWindows(on:)` count only when `smart-focused-window-border` is `true`) | Negligible | Negligible |
| **Maintenance Burden** | Low (matches `smart-window-margins`) | Medium (2 keys + docs/tests) | Medium (logic split across `WindowManager` and `FocusedWindowBorder`) |
| **Blast Radius** | Small (`UserConfiguration`, `FocusedWindowBorder`, `WindowManager`, `default.amethyst`, docs, tests) | Small-Medium | Small |

## 4. Recommendation
Adopt **Option A** (`smart-focused-window-border`, default `false`) with eligibility evaluated in `FocusedWindowBorder.isEligible` — it matches `smart-window-margins` conventions, preserves backward compatibility, and keeps eligibility logic pure and unit-testable.

## 5. Breaking Changes & Deprecations
None. `openspec/specs/` is empty, and `smart-focused-window-border` defaults to `false`, preserving existing border behavior.

## Review Gate
- [x] **Gate 0 Decision**: Option A
