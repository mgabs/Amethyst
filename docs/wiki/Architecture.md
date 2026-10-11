# Architecture

Window management is split into focused, single-responsibility components.

## Core components

| Component | Responsibility |
|---|---|
| **WindowManager** | Top-level orchestrator; coordinates managers, handles hot-key dispatch, owns the window registry |
| **ApplicationMonitor** | Tracks running applications and lifecycle events (launch, terminate, hide) |
| **WindowTracker** | Window registry, floating state, window list mutations |
| **FocusManager** | Focus transitions, focus-follows-mouse, focus history |
| **ScreenManager** | Per-screen layout state, space assignment, reflow |
| **LayoutType** | Enumerates and instantiates tiling layout algorithms |
| **Silica** (`Packages/Silica`) | Objective-C wrapper over Accessibility and private CoreGraphics APIs: `SIWindow`, `SIApplication`, `SISpace`, `NSScreen` space queries. All CGS parsing lives here; Swift sees typed objects and window IDs |

Windows are matched by CoreGraphics window ID and pid, not frame and title.

## Validation layer

- **ConfigurationValidator**: numeric bounds (ratios, counts, indices)
- **FrameValidator**: window frames against screen geometry
- **LayoutValidator**: layout index bounds and cycling

## Silica

Vendored as a local package so it builds and is tested with the app. Edit it in `Packages/Silica`. Rationale in [Fork Differences](Fork-Differences).
