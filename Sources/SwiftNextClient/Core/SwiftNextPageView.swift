//
//  SwiftNextPageView.swift
//  SwiftNextClient
//
//  Fetches and renders a server-driven page.
//  Hot-reload: listens for `.swiftNextServerReloaded` notification (posted by
//  InProcessServer/DevServer after a source-change rebuild).
//  Also auto-retries on connection failure so the UI reconnects the moment
//  the server comes back up after a recompile.
//
#if canImport(SwiftUI) && (os(iOS) || os(macOS) || targetEnvironment(macCatalyst))
import SwiftUI
import SharedModels

public extension Notification.Name {
    /// Posted by InProcessServer / DevServer after a hot-reload rebuild finishes.
    static let swiftNextServerReloaded = Notification.Name("SwiftNextServerReloaded")
}

@available(iOS 16.0, macOS 13.0, *)
public struct SwiftNextPageView: View {

    public let path: String

    @State private var payload: PagePayload?
    @State private var isReconnecting = false
    @State private var reloadID = UUID()

    public init(path: String) {
        self.path = path
    }

    public var body: some View {
        Group {
            if let payload {
                ZStack(alignment: .topTrailing) {
                    ScrollView {
                        SwiftNextTree(
                            components: payload.tree,
                            actionDispatcher: DefaultActionDispatcher { newPayload in
                                Task { @MainActor in self.payload = newPayload }
                            }
                        )
                    }
                    .navigationTitle(payload.title)
                    if isReconnecting {
                        Label("Reloading…", systemImage: "arrow.clockwise")
                            .font(.caption)
                            .padding(6)
                            .background(.regularMaterial, in: Capsule())
                            .padding(8)
                    }
                }
            } else {
                VStack(spacing: 12) {
                    ProgressView()
                    if isReconnecting {
                        Text("Waiting for server…")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .task(id: reloadID) { await loadWithRetry() }
            }
        }
        // Hot-reload trigger: server posts this after a source-change rebuild
        .onReceive(NotificationCenter.default.publisher(for: .swiftNextServerReloaded)) { _ in
            payload = nil
            isReconnecting = true
            reloadID = UUID()
        }
        .task(id: path) {
            reloadID = UUID()
            await loadWithRetry()
        }
    }

    // Retries indefinitely with 1.5s backoff until the server responds.
    // This means the UI automatically reconnects after a hot-reload rebuild.
    private func loadWithRetry() async {
        while !Task.isCancelled {
            do {
                let fetched = try await NetworkEngine.shared.fetchPage(path)
                await MainActor.run {
                    self.payload = fetched
                    self.isReconnecting = false
                }
                return
            } catch {
                await MainActor.run { self.isReconnecting = true }
                try? await Task.sleep(nanoseconds: 1_500_000_000) // 1.5s backoff
            }
        }
    }
}
#endif
