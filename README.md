# Kindling

Kindling is a private, ADHD-friendly travel memory map for iPhone. It turns selected photos and videos into editable trips, moments, maps, notes, voice memories, searchable details, and privacy-previewed sharing cards.

The current product specification is [`spec.md`](spec.md). Documents that describe the rejected task-starter product are retained with a **Legacy** banner for historical context only.

## Repository

- `ios/` — native SwiftUI app, local `KindlingCore` and `KindlingUI` packages, and StoreKit configuration.
- `landing/` — Astro website with current support, privacy, and terms pages.
- `metadata/` — canonical English App Store metadata.
- `screenshots/` — App Store screenshot automation and outputs; task-era images must be replaced before submission.
- `prototype/`, `proxy/`, and older planning documents — legacy task-starter artifacts, not part of the current app or deployment path.

## Build and test

Generate the Xcode project from `ios/project.yml`:

```sh
cd ios
xcodegen generate
xcodebuild -project Kindling.xcodeproj -scheme Kindling \
  -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build
```

Run the fast domain suite without a simulator:

```sh
cd ios/Packages/KindlingCore
swift test
```

Debug builds use `ios/Kindling.storekit`. Release builds use the real App Store catalog.

## Privacy architecture

- No account and no cloud sync in the first memory release.
- The system picker shares only selected media; broad photo-library permission is not required.
- Kindling stores protected, optimized display copies in its private app container.
- Coordinates, media, memory text, voice recordings, tags, and search terms cannot enter the typed analytics interface.
- The previous App Group remains temporarily available only for user-directed deletion of legacy data.

## Product boundary

The first release includes manual import, deterministic clustering, editable Memory Trails, maps, Sparks, notes, voice memories, local search, static postcards/map cards, local resurfacing, and Kindling Pro. iCloud sync, automatic trip discovery, semantic search, shared trips, animated films, widgets, and AI remain post-v1.
