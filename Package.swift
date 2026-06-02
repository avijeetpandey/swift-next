// swift-tools-version:5.9
//
//  Package.swift
//  SwiftNext
//
//  Root multi-target SPM manifest for the SwiftNext framework.
//
//  ┌──────────────────────────────────────────────────────────────────┐
//  │  HOW THE PIECES FIT TOGETHER                                     │
//  ├──────────────────────────────────────────────────────────────────┤
//  │  SharedModels      → Pure-Swift Codable contract that both the   │
//  │                      server and client compile against.          │
//  │  SwiftNextServer   → Vapor + Fluent backend that emits trees of  │
//  │                      `SwiftNextComponent` to the wire.           │
//  │  SwiftNextClient   → SwiftUI engine (iOS / iPadOS / macOS) that  │
//  │                      decodes those trees into native views.      │
//  │  AppLauncher       → Convenience executable used by Xcode's      │
//  │                      "Run" action to boot server + client.       │
//  │  SwiftNextCLI      → Developer toolchain (`swiftnext-cli`) that  │
//  │                      scaffolds, runs and tests user projects.    │
//  └──────────────────────────────────────────────────────────────────┘
//
//  Build:   swift build
//  Test:    swift test
//  Dev:     swift run SwiftNextCLI dev
//
import PackageDescription

let package = Package(
    name: "SwiftNext",
    platforms: [
        .macOS(.v13),
        .iOS(.v16)
    ],
    products: [
        .library(name: "SharedModels",      targets: ["SharedModels"]),
        .library(name: "SwiftNextClient",   targets: ["SwiftNextClient"]),
        .library(name: "SwiftNextServerKit", targets: ["SwiftNextServerKit"]),
        .executable(name: "SwiftNextServer", targets: ["SwiftNextServer"]),
        .executable(name: "AppLauncher",    targets: ["AppLauncher"]),
        .executable(name: "swiftnext-cli",  targets: ["SwiftNextCLI"])
    ],
    dependencies: [
        .package(url: "https://github.com/vapor/vapor.git", from: "4.92.0"),
        .package(url: "https://github.com/vapor/fluent.git", from: "4.9.0"),
        .package(url: "https://github.com/vapor/fluent-postgres-driver.git", from: "2.8.0"),
        .package(url: "https://github.com/vapor/fluent-sqlite-driver.git", from: "4.6.0"),
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.3.0")
    ],
    targets: [
        // MARK: - SharedModels (pure Swift, no platform deps)
        .target(
            name: "SharedModels",
            path: "Sources/SharedModels"
        ),

        // MARK: - SwiftNextServerKit (Vapor + Fluent library — importable by user projects)
        .target(
            name: "SwiftNextServerKit",
            dependencies: [
                "SharedModels",
                .product(name: "Vapor", package: "vapor"),
                .product(name: "Fluent", package: "fluent"),
                .product(name: "FluentPostgresDriver", package: "fluent-postgres-driver"),
                .product(name: "FluentSQLiteDriver", package: "fluent-sqlite-driver")
            ],
            path: "Sources/SwiftNextServer"
        ),

        // MARK: - SwiftNextServer (thin executable — delegates to SwiftNextServerKit)
        .executableTarget(
            name: "SwiftNextServer",
            dependencies: ["SwiftNextServerKit"],
            path: "Sources/SwiftNextServerRun"
        ),

        // MARK: - SwiftNextClient (SwiftUI engine, Apple platforms only)
        .target(
            name: "SwiftNextClient",
            dependencies: ["SharedModels"],
            path: "Sources/SwiftNextClient"
        ),

        // MARK: - AppLauncher (Xcode "Run" entry-point)
        .executableTarget(
            name: "AppLauncher",
            dependencies: ["SwiftNextClient", "SharedModels"],
            path: "Sources/AppLauncher"
        ),

        // MARK: - SwiftNextCLI (developer toolchain)
        .executableTarget(
            name: "SwiftNextCLI",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser")
            ],
            path: "Sources/SwiftNextCLI"
        ),

        // MARK: - Tests
        .testTarget(
            name: "BackendTests",
            dependencies: [
                "SwiftNextServerKit",
                "SharedModels",
                .product(name: "XCTVapor", package: "vapor")
            ],
            path: "Tests/BackendTests"
        ),
        .testTarget(
            name: "UIComponentsTests",
            dependencies: ["SwiftNextClient", "SharedModels"],
            path: "Tests/UIComponentsTests"
        ),
        .testTarget(
            name: "SharedModelsTests",
            dependencies: ["SharedModels"],
            path: "Tests/SharedModelsTests"
        )
    ]
)
