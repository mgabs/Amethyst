# Space Indicator

Menu-bar indicator of the current space number. Toggle options from the Amethyst menu bar icon → **Space Indicator**.

## Styles

- **Single Icon**: space number of the focused display.
- **One Icon Per Monitor**: active space number for each connected monitor.
- **One Icon Per Space**: all spaces across all monitors; active at full opacity, inactive dimmed.

## Color styles

- **Bordered**: number inside a rounded outline.
- **Solid**: number cut out of a solid rounded rectangle.
- **Solid Inverted**: white number on a solid black rounded rectangle.

Depends on private CoreGraphics space APIs wrapped by Silica (see [Architecture](Architecture)).

## Focused window border

Separate feature: an outline around the active managed window.

| Key | Default |
|---|---|
| `focused-window-border` | `true` |
| `focused-window-border-color` | `"#b38115"` (amber; keep the quotes) |
| `focused-window-border-width` | `4` (`0` disables) |

See [Configuration Files](configuration-files).
