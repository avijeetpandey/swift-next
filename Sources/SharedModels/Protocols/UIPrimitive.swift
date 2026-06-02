//
//  UIPrimitive.swift
//  SharedModels
//
//  The root contract that every server-emitted UI node conforms to.
//  Implementations live alongside `SwiftNextComponent` cases and provide
//  identity, action-routing, and Codable round-tripping over the wire.
//
//  Server  ──emits──▶  UIPrimitive (JSON)  ──▶  SwiftNextRenderer  ──▶  SwiftUI
//
import Foundation

/// Marker protocol implemented by every payload type that participates
/// in the Server-Driven UI tree. Anything that travels between the
/// Vapor backend and an Apple-platform client must conform to this.
public protocol UIPrimitive: Codable, Hashable, Sendable {
    /// Stable identity used by SwiftUI's diffing engine.
    var id: String { get }

    /// Optional server-action endpoint. When non-nil the renderer will
    /// dispatch a network call to this route on user interaction,
    /// emulating Next.js Server Actions.
    var actionRoute: String? { get }
}
