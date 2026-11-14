# Spec Delta

## Purpose
Provide a configuration option (`smart-focused-window-border`) that suppresses the focused window border when focus is unambiguous because only one tiled window is on the screen's current space or the screen is using `FullscreenLayout`.

## ADDED Requirements

### Requirement: REQ-BORDER-1 Smart Focused Window Border Configuration
The system MUST expose a boolean configuration key `smart-focused-window-border` in `UserConfiguration` and `default.amethyst` with a default value of `false`.

#### Scenario: Default value when key is unset
- **GIVEN** `smart-focused-window-border` is not set in user configuration storage
- **WHEN** `UserConfiguration.smartFocusedWindowBorder()` is queried
- **THEN** it returns `false` and existing focused window border behavior is preserved

#### Scenario: Explicit override to true
- **GIVEN** `smart-focused-window-border` is set to `true` in user configuration storage
- **WHEN** `UserConfiguration.smartFocusedWindowBorder()` is queried
- **THEN** it returns `true`

### Requirement: REQ-BORDER-2 Single Tiled Window Suppression
When `smart-focused-window-border` is `true`, the system MUST hide the focused window border if the focused window's screen has at most one active tiled managed window on its current space, ignoring floating windows.

#### Scenario: Single tiled window on current space
- **GIVEN** `smart-focused-window-border` is `true` and `focused-window-border` is enabled
- **WHEN** the focused window's screen has 1 active tiled window on its current space (and any number of floating windows)
- **THEN** the focused window border is hidden

#### Scenario: Two or more tiled windows on current space
- **GIVEN** `smart-focused-window-border` is `true`, `focused-window-border` is enabled, and the screen is not using `FullscreenLayout`
- **WHEN** the focused window's screen has 2 or more active tiled windows on its current space
- **THEN** the focused window border is shown around the eligible focused window

#### Scenario: Smart border disabled with single tiled window
- **GIVEN** `smart-focused-window-border` is `false` and `focused-window-border` is enabled
- **WHEN** the focused window's screen has 1 active tiled window on its current space
- **THEN** the focused window border remains eligible and is shown

### Requirement: REQ-BORDER-3 Fullscreen Layout Suppression
When `smart-focused-window-border` is `true`, the system MUST hide the focused window border if the focused window's screen is currently using `FullscreenLayout`, regardless of how many tiled windows exist on the space.

#### Scenario: FullscreenLayout active with multiple tiled windows
- **GIVEN** `smart-focused-window-border` is `true` and the focused window's screen has 2 or more active tiled windows
- **WHEN** the screen's current layout is `FullscreenLayout`
- **THEN** the focused window border is hidden

#### Scenario: Leaving FullscreenLayout with multiple tiled windows
- **GIVEN** `smart-focused-window-border` is `true` and the focused window's screen has 2 or more active tiled windows
- **WHEN** the screen switches from `FullscreenLayout` to a non-fullscreen layout
- **THEN** the focused window border is shown around the eligible focused window

#### Scenario: Native macOS fullscreen space remains excluded
- **GIVEN** `smart-focused-window-border` is `false` or `true`
- **WHEN** the focused window is on a native macOS fullscreen space (`spaceType != CGSSpaceTypeUser`)
- **THEN** the focused window border remains hidden

### Requirement: NFR-BORDER-1 Zero Overhead When Disabled
When `smart-focused-window-border` is `false`, `WindowManager.updateFocusedWindowBorder(focused:)` MUST NOT enumerate active windows on the screen to compute tiled window count.

#### Scenario: Disabled smart border skips active window enumeration
- **GIVEN** `smart-focused-window-border` is `false`
- **WHEN** `WindowManager.updateFocusedWindowBorder(focused:)` evaluates border eligibility
- **THEN** `activeWindows(on:)` is not called for border suppression
