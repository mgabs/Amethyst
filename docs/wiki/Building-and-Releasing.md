# Building and Releasing

Requires Xcode. Swift packages resolve automatically.

## Local build (Makefile)

| Command | Action |
|---|---|
| `make build` | Debug build |
| `make test` | Run tests |
| `make archive` | Release archive, zips app and dSYMs into `build/artifacts/` |
| `make tap` | Write `Casks/amethyst.rb` into `TAP_DIR` (default `../homebrew-tap`) |
| `make clean` | Remove `build/` |

Or open `Amethyst.xcworkspace` in Xcode.

## CI/CD

Workflows in `.github/workflows/`:

- **CI** (`ci.yml`): `xcodebuild test` on pushes to `master` and PRs.
- **Release** (`release.yml`): on every push to `master`, reads `MARKETING_VERSION`. If no release for it exists, it archives with `xcodebuild`, zips the app and dSYMs, generates the Sparkle `appcast.xml`, tags `vX.Y.Z`, publishes a GitHub Release, and updates the Homebrew tap. A version containing `-` is a pre-release (skipped by the updater and the tap).
- **Sync Wiki** (`wiki-sync.yml`): publishes `docs/` to this wiki on pushes to `master` that touch `docs/`.

### Cutting a release

1. Bump `MARKETING_VERSION` (Xcode → Amethyst target → General, or edit `project.pbxproj`).
2. Merge to `master`.

`CURRENT_PROJECT_VERSION` (what Sparkle compares) is the commit count; no manual build bump needed.

### Homebrew tap

The release job clones `mgabs/homebrew-tap` and commits `Casks/amethyst.rb` with the new version and SHA256. Skipped if `TAP_GITHUB_TOKEN` is unset.

### Secrets

| Secret | Purpose |
|---|---|
| `CERTIFICATES_P12` / `CERTIFICATES_P12_PASSWORD` | Base64 `.p12` signing certificate. Without it the build is ad-hoc signed. |
| `SPARKLE_PRIVATE_KEY` | EdDSA key signing the appcast. Public half is `SUPublicEDKey` in `Amethyst-Info.plist`; regenerating it breaks updates for existing installs. Without it, no appcast and no in-app updates. |
| `TAP_GITHUB_TOKEN` | PAT with write access to `mgabs/homebrew-tap`. |

Updater feed: `https://github.com/mgabs/Amethyst/releases/latest/download/appcast.xml`.

## Contributing

`master` is the only long-lived branch. Branch off it, open PRs against it; CI runs on every PR. Match the existing code style.
