# ReadKeeper

A cozy bookshelf that tracks your reading. Native iOS app (Swift 6 + SwiftUI, iOS 18+).

**Promise:** no ads, no AI art, your books stay on your devices.

## Status

Milestone **M0: Foundation**: project setup, automatic builds, first shelf screen with generated book spines.

## See the app without a Mac

Every push to `main` runs the [CI workflow](.github/workflows/ci.yml) on a GitHub-hosted Mac. It:

1. builds the app and runs the unit tests,
2. launches it in an iPhone simulator and takes screenshots (light and dark mode) plus a short screen recording,
3. publishes them to the [`ci-screenshots`](../../tree/ci-screenshots) branch, so they open in the browser,
4. uploads a build to [Appetize.io](https://appetize.io), if configured, so you can tap through the app in your browser.

### Enable the Appetize browser preview (optional)

1. Create a free account at appetize.io and copy your **API token**.
2. In this repo: **Settings → Secrets and variables → Actions → New repository secret**
   - `APPETIZE_API_TOKEN` = your token
3. After the first upload, the workflow summary shows the app's public key. Save it as a second secret,
   `APPETIZE_PUBLIC_KEY`, so later builds update the same app instead of creating new ones.

## Build on a Mac

```bash
brew install xcodegen
xcodegen generate
open ReadKeeper.xcodeproj
```

The `.xcodeproj` is generated from [`project.yml`](project.yml) and isn't committed.

## Project layout

```
ReadKeeper/
  App/          App entry point and tab bar
  Core/
    Design/     Colors (RGB, Theme)
    Models/     Data models
    Shelf/      Spine generator, shelf layout, stable hash
  Features/     Shelf, Library, Stats, Settings screens
  Support/      Launch options for CI, demo data (Debug only)
  Resources/    Asset catalog (placeholder icon)
ReadKeeperTests/  Unit tests (Swift Testing)
scripts/ci/       Simulator selection and screenshot scripts
```

## Launch arguments (Debug)

| Argument | Effect |
|---|---|
| `-RKStartTab shelf\|library\|stats\|settings` | Opens a specific tab |
| `-RKDemoShelf YES` | Fills the shelf with public-domain demo books (screenshots only) |
