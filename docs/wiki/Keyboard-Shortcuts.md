# Keyboard Shortcuts

Shortcuts are built from up to four modifier combinations, configurable via `mod1`–`mod4` in [Configuration Files](configuration-files).

| Modifier | Default |
|---|---|
| `mod1` | `option + shift` |
| `mod2` | `ctrl + option + shift` |
| `mod3` | `option + shift + command` |
| `mod4` | not defined |

## Layouts and panes

| Shortcut | Action |
|---|---|
| `mod1 + space` | Cycle layout forward |
| `mod2 + space` | Cycle layout backwards |
| `mod1 + h` / `mod1 + l` | Shrink / expand main pane |
| `mod1 + ,` / `mod1 + .` | Increase / decrease main pane count |
| `mod1 + a` | Tall |
| `mod1 + s` | Wide |
| `mod1 + d` | Fullscreen |
| `mod1 + f` | Column |
| `none` | Tall-right, middle-wide, row, floating, widescreen-tall, bsp |
| `mod1 + i` | Display current layout |

## Focus and swap

| Shortcut | Action |
|---|---|
| `mod1 + j` / `mod1 + k` | Focus counter-clockwise / clockwise |
| `mod1 + p` / `mod1 + n` | Focus counter-clockwise / clockwise screen |
| `mod2 + j` / `mod2 + k` | Swap window counter-clockwise / clockwise |
| `mod2 + h` / `mod2 + l` | Swap window to counter-clockwise / clockwise screen |
| `mod1 + enter` | Swap focused window with main window |

## Spaces and screens

| Shortcut | Action |
|---|---|
| `mod2 + left` / `mod2 + right` | Throw window to space left / right |
| `mod2 + 1`…`9`, `0` | Throw window to space 1–9, 10 |
| `none` | Throw window to space 11–16 |
| `mod1 + w` / `e` / `r` / `q` / `g` | Focus screen 1–5 |
| `mod2 + w` / `e` / `r` / `q` / `g` | Throw window to screen 1–5 |

## Window state and app control

| Shortcut | Action |
|---|---|
| `mod1 + t` | Toggle float for focused window |
| `mod2 + t` | Toggle global tiling |
| `mod1 + z` | Force windows to be reevaluated |
| `mod3 + r` | Realign: reset all layouts to default proportions |
| `mod2 + z` | Relaunch Amethyst |

Floating windows: the shrink/expand main-pane shortcuts resize the focused window.
