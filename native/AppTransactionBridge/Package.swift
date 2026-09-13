// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "AppTransactionBridge",
    // Deliberately the ecosystem's actual iOS floor (matches Button.Maui's
    // SupportedOSPlatformVersion), not AppTransaction's real iOS 16.0 requirement - the
    // #unavailable(iOS 16.0, ...) runtime check in AppTransactionBridge.swift is what actually
    // gates that API, so the compiled library shouldn't force every consumer's minimum deployment
    // target higher than they actually need.
    platforms: [.iOS(.v15)],
    products: [
        .library(name: "AppTransactionBridge", targets: ["AppTransactionBridge"]),
    ],
    targets: [
        .target(name: "AppTransactionBridge"),
    ]
)
