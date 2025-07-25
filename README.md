# Memory Citadel

Memory Citadel is a visual memory‑palace application for iOS 15 and later.
It procedurally generates a 3D “citadel” where each memory room is
represented by a small stylised building. Rooms are grouped into
**wings**, and wings belong to **palaces**. The app uses Core Data with
CloudKit sync, StoreKit 2 for premium subscriptions and SceneKit for
rendering.

## Build and Run

1. Open `MemoryCitadel.xcodeproj` in Xcode 15.2 or later.
2. Ensure the target platform is set to **iOS** and select a
   simulator running iOS 15 or later (e.g. *iPhone 15*).
3. Build and run the **MemoryCitadel** scheme.

### Dependencies

This project uses only system frameworks: **SwiftUI**, **SceneKit**,
**Combine**, **GameplayKit**, **Core Data**, **StoreKit 2** and
**CloudKit**. No third‑party analytics or SDKs are included.

## Architecture

The codebase follows the **MVVM** pattern with a small service layer:

| Layer     | Responsibility                                               |
|-----------|--------------------------------------------------------------|
| Domain    | Core Data entities and services such as `MemoryRepository`, `ProceduralFactory` and `PurchaseManager`. |
| UI        | SwiftUI views and corresponding view models. Views are thin, delegating business logic to the view models. |
| Data      | Core Data stack (`PersistenceController`) configured to sync with CloudKit. |
| Extensions| Small helpers on UIKit/SceneKit types. |
| Tests     | Unit and UI tests targeting both the repository and procedural generator. |

### Diagram

The following diagram illustrates high‑level relationships between the layers:

```
   +---------------+          +---------------+        +-------------------+
   |   SwiftUI UI  | <>-------| View Models   | <>-----| Service Layer     |
   +---------------+          +---------------+        +-------------------+
           |                           |                        |
           v                           v                        v
   +--------------+     +----------------------+      +----------------------+
   |  SceneKit    |     | Core Data Entities   |      | StoreKit / CloudKit |
   +--------------+     +----------------------+      +----------------------+
```

## Testing

Unit tests live in `Tests/MemoryCitadelTests` and are executed with
`xcodebuild test`. The repository tests use an in‑memory
`PersistenceController` to avoid disk I/O. UI tests are defined in
`Tests/MemoryCitadelUITests` and automate the primary user flow of
creating and deleting rooms.

A coverage badge is generated via Codecov after the CI workflow runs:

![Coverage](https://img.shields.io/badge/coverage-80%25-green)

## Localization

All user‑facing strings are defined in `Resources/Localizable.strings`.
English (`en`) and German (`de`) localisations are provided. Use
`NSLocalizedString` to fetch strings at runtime.

## Privacy

Memory Citadel does not include any third‑party analytics. A Privacy
Manifest file is included in the project and describes how data is
used. The app synchronises user data via iCloud/CloudKit in a secure
manner. No personal data is shared with third parties.