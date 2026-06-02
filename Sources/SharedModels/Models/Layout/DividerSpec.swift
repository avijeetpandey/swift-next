//
//  DividerSpec.swift
//  SharedModels
//
import Foundation

public struct DividerSpec: UIPrimitive {
    public let id: String
    public var actionRoute: String? { nil }

    public init(id: String) {
        self.id = id
    }
}
