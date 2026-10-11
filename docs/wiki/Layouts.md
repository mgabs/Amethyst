# Layouts

Cycle layouts with `mod1 + space`. Layouts can be enabled or disabled (the `layouts` key in [Configuration Files](configuration-files)) to control which appear in the cycle.

For all paned layouts the main pane ratio resets to 50% when a second window appears.

| Layout | Description |
|---|---|
| **Tall** (default) | Main pane left (full height), others stacked in a right pane. |
| **Tall-Right** | Tall mirrored: main pane on the right. |
| **Wide** | Main pane on top (full width), others in columns below. |
| **Two Pane** | Main pane pinned; one visible window in the secondary pane, swappable. Adapts to screen orientation. |
| **Two Pane Right** | Two Pane mirrored. |
| **3Column-Left** | Main pane left, two other columns. |
| **3Column-Middle** | Main pane in the middle (formerly *Middle-Wide*). |
| **3Column-Right** | Main pane right. |
| **Widescreen-Tall** | Like Tall, but multiple main windows split into columns. Suits very wide screens. |
| **Fullscreen** | Focused window fills the screen; cycle with focus shortcuts. |
| **Column** | One full-height column per window. Leftmost is "main". |
| **Row** | Column rotated: one full-width row per window. |
| **Floating** | All windows float; no tiling. |
| **BSP** | Binary space partitioning: each new window splits a pane along its longer axis. No main pane. |
| **Custom (beta)** | JavaScript layouts. See [Custom Layouts](custom-layouts). |

## Related

- [Keyboard Shortcuts](Keyboard-Shortcuts) for layout selection keys.
- [Window Limit](window-limit) to cap visible windows per screen.
