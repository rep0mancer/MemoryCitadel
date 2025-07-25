# Memory Citadel

Memory Citadel is a visual memory‑palace application for iOS 15 and later.
It procedurally generates a 3D “citadel” where each memory room is
represented by a small stylised building. Rooms are grouped into
**wings**, and wings belong to **palaces**. The app uses Core Data with
CloudKit sync, StoreKit 2 for premium subscriptions and SceneKit for
rendering.

## Build and Run

This repository does not include the `MemoryCitadel.xcodeproj` file. To
compile and run the app you can create a project yourself:

1. Launch **Xcode 15.2** (or later) and create a new *iOS App* project
   named **MemoryCitadel**.
2. Remove any boilerplate code and add the files from `Domain`, `UI`,
   `Data`, `Extensions`, `Resources` and `MemoryCitadelApp.swift` to the
   target.
3. Select a simulator running iOS 15 or later (e.g. *iPhone 15*) and
   build the **MemoryCitadel** scheme.

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

## Relationship Resolution

Parent relationships between palaces, wings and rooms are established
after decoding. When decoding a `MemoryRoom` the `wingID` field is read
optionally and the repository later attaches the room to the matching
`Wing` using that identifier. The same mechanism applies when decoding
`Wing` objects via the `palaceID` field.

## Localization

All user‑facing strings are defined in `Resources/Localizable.strings`.
English (`en`) and German (`de`) localisations are provided. Use
`NSLocalizedString` to fetch strings at runtime.

## Privacy

Memory Citadel does not include any third‑party analytics. A
`Resources/PrivacyInfo.xcprivacy` manifest file describes how data is
used. The app synchronises user data via iCloud/CloudKit in a secure
manner and no personal data is shared with third parties.
