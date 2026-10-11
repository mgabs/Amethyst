# Installation

Requires macOS 12+.

## Homebrew

```bash
brew install --cask mgabs/tap/amethyst
```

Or tap first: `brew tap mgabs/tap && brew install --cask amethyst`.

> `brew install --cask amethyst` without the tap installs **upstream** Amethyst, not this fork.

The cask is updated automatically on every release by the [Release workflow](Building-and-Releasing#homebrew-tap).

## Direct download

1. Download `Amethyst-vX.Y.Z-bNNNN.zip` from the [releases page](https://github.com/mgabs/Amethyst/releases/latest).
2. Unzip and move `Amethyst.app` to `/Applications`.

## First launch (Gatekeeper)

Builds are signed but **not notarized**, so macOS blocks the first launch (malware warning or error -128):

```bash
xattr -dr com.apple.quarantine /Applications/Amethyst.app
```

Or: **System Settings → Privacy & Security → Open Anyway**. See [Troubleshooting](troubleshooting#amethyst-wont-open-after-download).

## Updates

"Check for Updates…" in the menu bar uses Sparkle against this fork's GitHub releases (since v0.24.4). Older builds still check upstream; replace them by hand once. Pre-release versions (containing `-`) are skipped.

Next: [Getting Started](Getting-Started).
