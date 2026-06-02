//
//  SwiftNextActionDispatcher.swift
//  SwiftNextClient
//
//  Bridges UI events (button taps, text submissions) back to the
//  server. The dispatcher is intentionally a small protocol so tests
//  can substitute an in-memory implementation.
//
#if canImport(Foundation)
import Foundation
import SharedModels

@available(iOS 16.0, macOS 13.0, *)
public protocol SwiftNextActionDispatcher: AnyObject, Sendable {
    func dispatch(route: String, value: String?, payload: [String: String]?) async
}
#endif
