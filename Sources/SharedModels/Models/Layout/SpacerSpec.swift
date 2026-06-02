//
//  SpacerSpec.swift
//  SharedModels
//
import Foundation

public struct SpacerSpec: UIPrimitive {
    public let id: String
    public let minLength: Double?
    public var actionRoute: String? { nil }

    public init(id: String, minLength: Double? = nil) {
        self.id = id
        self.minLength = minLength
    }
}
