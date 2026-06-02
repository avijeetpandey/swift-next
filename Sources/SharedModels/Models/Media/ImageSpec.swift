//
//  ImageSpec.swift
//  SharedModels
//
//  Remote async image. The renderer maps this to SwiftUI's `AsyncImage`.
//
import Foundation

public struct ImageSpec: UIPrimitive {
    public let id: String
    public let url: String
    public let width: Double?
    public let height: Double?
    public let accessibilityLabel: String?
    public let actionRoute: String?

    public init(id: String,
                url: String,
                width: Double? = nil,
                height: Double? = nil,
                accessibilityLabel: String? = nil,
                actionRoute: String? = nil) {
        self.id = id
        self.url = url
        self.width = width
        self.height = height
        self.accessibilityLabel = accessibilityLabel
        self.actionRoute = actionRoute
    }
}
