# Fork Differences

Branched from upstream `master` at the end of February 2026 (just after Amethyst 0.24.1); not merged since.

## Why it is not mergeable

- **Silica vendored and reshaped.** Copied into `Packages/Silica`; unused API removed, return values and CoreFoundation lifetimes fixed, `SIApplication` windows cache dropped, `SISpace`, `managedSpaceID` and on-screen window-ID queries added via private `CGS*` calls.
- **Own release and update channel.** Own signing certificate, Sparkle 2 feed and EdDSA key, auto-release on every `MARKETING_VERSION` bump.
- **Core partly split.** `ApplicationMonitor`, `WindowTracker`, `FocusManager` extracted from `WindowManager`; validation layer added; windows matched by CG window ID and pid. See [Architecture](Architecture).
- **Defaults changed on purpose.** 50% main pane reset when a second window appears, destination layout reset on throw, native resize/zoom triggers reflow, mouse drags reflow on release, float toggle forces realign, layout HUD in the lower third.
- **Space Indicator.** See [Space Indicator](Space-Indicator).

Small bug fixes independent of the above (throw-to-space bounds checks, main-thread frame application, small-window and margin fixes) could still go upstream individually.

## What it adds

- Manual realign: `mod3 + r`
- Automatic proportion reset when moving a window to another space or monitor
- Automatic realign on maximize/zoom
- Menu-bar Space Indicator
- Resize of floating windows via main-pane shortcuts
- Focused window border (`focused-window-border*` keys)
- `smart-window-margins` (drop margins with a single tiled window)
