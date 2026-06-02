//
//  AppLauncher.swift
//  AppLauncher
//
//  ┌──────────────────────────────────────────────────────────────────┐
//  │  XCODE / CLI SINGLE-CLICK BOOT                                   │
//  ├──────────────────────────────────────────────────────────────────┤
//  │  When a developer presses the native "Run" button in Xcode for   │
//  │  the AppLauncher scheme — or executes `swift run AppLauncher` — │
//  │  this entry point:                                               │
//  │    1. Spawns SwiftNextServer detached in the background.         │
//  │    2. Waits for /health to become reachable.                     │
//  │    3. On macOS / iOS, opens the SwiftUI window pointing at       │
//  │       http://localhost:8080.                                     │
//  │  On non-Apple platforms we keep the server in the foreground so  │
//  │  CI smoke-tests still work.                                      │
//  └──────────────────────────────────────────────────────────────────┘
//
import Foundation

#if os(macOS) || os(iOS)
import SwiftUI
import SwiftNextClient

@available(macOS 13.0, iOS 16.0, *)
@main
struct SwiftNextAppLauncher: App {

    init() {
        BackgroundServer.shared.start()
    }

    var body: some Scene {
        WindowGroup {
            NavigationStack {
                SwiftNextPageView(path: "/pages/home")
            }
            .onDisappear { BackgroundServer.shared.stop() }
        }
    }
}
#else
// Headless fallback (Linux CI etc.) — just run the server.
@main
struct HeadlessLauncher {
    static func main() {
        BackgroundServer.shared.startBlocking()
    }
}
#endif
