# SyntaxCircus.Maui.StoreKit

[![Build](https://github.com/Syntax-Circus/SyntaxCircus.Maui.StoreKit/actions/workflows/build.yml/badge.svg)](https://github.com/Syntax-Circus/SyntaxCircus.Maui.StoreKit/actions/workflows/build.yml)
[![NuGet](https://img.shields.io/nuget/v/SyntaxCircus.Maui.StoreKit.svg)](https://www.nuget.org/packages/SyntaxCircus.Maui.StoreKit)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE.txt)

iOS-only: implements [`SyntaxCircus.Maui.Environments`](https://github.com/Syntax-Circus/SyntaxCircus.Maui.Environments)'s `IAppTransactionEnvironmentProvider` via a small native Swift shim around StoreKit 2's `AppTransaction.shared`, so `IosDistributionChannelService` can actually detect TestFlight vs. App Store vs. Xcode-run installs instead of always reporting `Unknown`.

> **No support guaranteed.** Published as-is and maintained on a best-effort basis. Issues and PRs are welcome, but there's no SLA — fork it or vendor what you need if that's not enough.

## Why this needs a native shim at all

Apple's StoreKit 2 `AppTransaction` API is **Swift-only** — unlike Objective-C-compatible StoreKit APIs, it isn't bound for direct C# calls by dotnet/macios out of the box. Reading `AppTransaction.shared.environment` from .NET requires a small native Swift binary exposing an Objective-C-compatible surface, which is what this package builds and ships as a `net10.0-ios`-only NuGet package with an embedded `.xcframework`.

## Setup

```csharp
#if IOS
builder.Services.AddSingleton<IAppTransactionEnvironmentProvider, IosAppTransactionEnvironmentProvider>();
#endif
```

Register this alongside `SyntaxCircus.Maui.Environments`' `AddAppEnvironments(...)` — `IosDistributionChannelService` (from that package) picks it up automatically once registered; with nothing registered, it always reports `DistributionChannel.Unknown` rather than guessing.

## Targets

`net10.0-ios` only — StoreKit 2's `AppTransaction` is an Apple-platform concept, so there's nothing to ship for Android or the plain `net10.0` TFM. `SupportedOSPlatformVersion` is 15.0, matching a typical MAUI app's iOS floor — the *library's* minimum deployment target is deliberately lower than `AppTransaction`'s real iOS 16.0 requirement, so referencing this package doesn't force your app's deployment target up. The Swift code itself guards with `#unavailable(iOS 16.0, ...)` and returns `nil` safely below that OS version.

## How this works

1. `native/AppTransactionBridge` is a small Swift Package Manager package. Its one type, `AppTransactionBridge`, is `@objc`-visible with a completion-handler-based static method — Swift automatically generates an Objective-C-compatible completion-handler variant of an `async` function when it's `@objc` and uses only ObjC-bridgeable types (here, `String?`).
2. `scripts/build-xcframework.sh` (run by CI, and runnable locally on a Mac with Xcode) archives that Swift package for iOS device and iOS Simulator, links each into a static library, and combines them into `AppTransactionBridge.xcframework` via `xcodebuild -create-xcframework`.
3. `src/SyntaxCircus.Maui.StoreKit`'s `ApiDefinitions.cs` is a .NET-for-iOS binding project definition (`[BaseType(typeof(NSObject))]`) binding that native surface; `<NativeReference>` in the `.csproj` embeds the `.xcframework`.
4. `IosAppTransactionEnvironmentProvider` wraps the generated binding's completion-handler call in a `TaskCompletionSource<string?>`, implementing `IAppTransactionEnvironmentProvider` from `SyntaxCircus.Maui.Environments`.

The raw native binding (`AppTransactionBridge`, generated from `ApiDefinitions.cs`) is marked `[Internal]` — it's an implementation detail. `IosAppTransactionEnvironmentProvider` is the only public surface you need.

## Building locally

Requires a Mac with Xcode. From the repo root:

```bash
./scripts/build-xcframework.sh   # produces native/AppTransactionBridge/build/AppTransactionBridge.xcframework
dotnet workload restore SyntaxCircus.Maui.StoreKit.slnx
dotnet build SyntaxCircus.Maui.StoreKit.slnx
```

## Verification note

`AppTransaction.shared` genuinely resolving to `"Sandbox"`/`"Production"` (rather than `nil`) requires running inside a real, StoreKit-aware app context — a bare test harness or unsigned tool has no verified transaction to read, and correctly returns `nil`. Xcode's local "StoreKit Testing" configuration (a `.storekit` config file) can exercise the plumbing in a Simulator, but only ever reports the `.xcode` case; exercising `.sandbox`/`.production` for real needs an actual TestFlight build and/or a released App Store build.

## Contributing

Issues and pull requests are welcome:
- Keep changes focused, with a clear description of the behavior change.
- Match the existing code style (see `.editorconfig`).
- Call out any breaking changes to the public API in your PR description.

## License

MIT — see [LICENSE.txt](LICENSE.txt).
