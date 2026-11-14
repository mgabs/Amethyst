# Proposal

## Intent
Add a `smart-focused-window-border` configuration option (default `false`) that hides the focused window border when only a single tiled window is present on a screen's current space or when the screen is using `FullscreenLayout`.

## Problem Statement
Amethyst currently draws the focused window border around any eligible focused managed window, even when only one tiled window is on the screen's current space or when `FullscreenLayout` is active. In both cases focus is already unambiguous, so the border adds unnecessary visual noise.

## Capabilities

### New Capabilities
- `smart-focused-window-border`: Config-driven suppression of the focused window border when `smart-focused-window-border` is `true` and either the focused window's screen has at most one active tiled window on its current space (floating windows ignored) or the screen's current layout is `FullscreenLayout`.

### Modified Capabilities
- None (`openspec/specs/` has no existing specs).

## Scope

### In-Scope
- Add `smart-focused-window-border` boolean configuration key to `UserConfiguration` and `default.amethyst` (default `false`).
- Extend `FocusedWindowBorder.isEligible(...)` with pure eligibility parameters for smart border suppression (`FullscreenLayout` and tiled window count <= 1).
- Pass the focused window's screen `FullscreenLayout` state and `activeWindows(on: screen).count` from `WindowManager.updateFocusedWindowBorder(focused:)` when `smart-focused-window-border` is enabled.
- Update configuration documentation (`docs/configuration-files.md`, `docs/wiki/Space-Indicator.md`, `docs/wiki/Fork-Differences.md`) and unit tests (`UserConfigurationTests`, `FocusedWindowBorderTests`).

### Out-of-Scope (YAGNI)
- Preferences window UI checkbox or controls (all `focused-window-border*` and `smart-window-margins` settings are config-only).
- Separate toggles for single-window suppression vs. `FullscreenLayout` suppression.
- Counting floating windows toward the single-window threshold.
- Hiding borders on manually resized/maximized floating windows outside `FullscreenLayout`.

## Assumptions
- **ASM-GEN-1**: `WindowManager.activeWindows(on: screen)` accurately reflects tiled, non-hidden, managed windows on the screen's current space (excluding floating windows), matching `smart-window-margins` semantics.
- **ASM-GEN-2**: `WindowManager.updateFocusedWindowBorder(focused:)` is already invoked on layout changes, window open/close/float/hide events, and focus transitions, so no new WindowServer hooks are required.
- **ASM-GEN-3**: Native macOS fullscreen (`CGSSpaceTypeFullscreen`) continues to be excluded regardless of `smart-focused-window-border` via `spaceType == CGSSpaceTypeUser`.

## Success Metrics
- With `smart-focused-window-border: false` (or unset), border behavior is unchanged for all existing cases.
- With `smart-focused-window-border: true`, border hides when tiled window count on the focused screen's current space is `<= 1` (even if floating windows exist) or when the screen's layout is `FullscreenLayout`, and reappears when a second tiled window appears or layout leaves `FullscreenLayout`.
- Unit tests cover config default/override and all eligibility combinations.

## Review Gate
- [x] **Gate 1 Approval**: Proposal reviewed and approved by human before drafting specs.
