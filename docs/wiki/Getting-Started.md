# Getting Started

## 1. Grant Accessibility permission

Amethyst needs the Accessibility API: **System Settings → Privacy & Security → Accessibility**, enable Amethyst.

<img src="images/accessibility-permission.png" width="500" alt="Accessibility permission">

## 2. Stop Spaces from reordering

Disable **Automatically rearrange Spaces based on most recent use** (System Settings → Desktop & Dock / Mission Control). Otherwise Spaces swap places and keyboard navigation between them becomes unpredictable.

<img src="images/auto-rearranage.png" width="500" alt="Mission Control setting">

Or from a terminal:

```bash
defaults write com.apple.dock workspaces-auto-swoosh -bool NO
killall Dock
```

## 3. Learn the basics

- [Keyboard Shortcuts](Keyboard-Shortcuts): `mod1` = option+shift.
- [Layouts](Layouts): cycle with `mod1 + space`.
- Float a window: `mod1 + t`.
- Customize: [Configuration Files](configuration-files).

Stuck? See [Troubleshooting](troubleshooting).
