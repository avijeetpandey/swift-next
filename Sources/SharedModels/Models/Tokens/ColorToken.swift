//
//  ColorToken.swift
//  SharedModels
//
//  Wire-safe color expressed as a hex string ("#RRGGBB" or "#RRGGBBAA")
//  or a named semantic role. The client renderer is responsible for
//  resolving these to platform-appropriate colours.
//
import Foundation

public struct ColorToken: Codable, Hashable, Sendable {
    public let hex: String?
    public let semantic: Semantic?

    public enum Semantic: String, Codable, Hashable, Sendable {
        case primary, secondary, accent, background, foreground, destructive
    }

    public init(hex: String? = nil, semantic: Semantic? = nil) {
        self.hex = hex
        self.semantic = semantic
    }
}
