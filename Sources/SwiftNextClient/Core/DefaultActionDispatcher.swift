//
//  DefaultActionDispatcher.swift
//  SwiftNextClient
//
//  Production dispatcher: posts to the server via `NetworkEngine` and
//  publishes the new tree via an `@MainActor` callback.
//
#if canImport(SwiftUI) && (os(iOS) || os(macOS) || targetEnvironment(macCatalyst))
import Foundation
import SharedModels

@available(iOS 16.0, macOS 13.0, *)
public final class DefaultActionDispatcher: SwiftNextActionDispatcher, @unchecked Sendable {

    private let engine: NetworkEngine
    private let onPayload: @Sendable (PagePayload) -> Void

    public init(engine: NetworkEngine = .shared,
                onPayload: @escaping @Sendable (PagePayload) -> Void) {
        self.engine = engine
        self.onPayload = onPayload
    }

    public func dispatch(route: String, value: String?, payload: [String: String]? = nil) async {
        do {
            var body: [String: String] = payload ?? [:]
            if let v = value { body["value"] = v }
            let result: PagePayload = try await engine.post(route, body: body.isEmpty ? nil : body)
            onPayload(result)
        } catch {
            print("SwiftNext dispatcher error: \(error)")
        }
    }
}
#endif
