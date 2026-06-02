//
//  ButtonSpec.swift
//  SharedModels
//
//  When tapped the button POSTs to `actionRoute`. The server response
//  may itself be a fresh `[SwiftNextComponent]` tree, allowing full
//  Server-Action style mutations.
//
import Foundation

public struct ButtonSpec: UIPrimitive {
    public let id: String
    public let title: String
    public let style: Style
    public let actionRoute: String?
    public let actionPayload: [String: String]?

    public enum Style: String, Codable, Hashable, Sendable {
        case primary, secondary, plain, destructive
    }

    public init(id: String,
                title: String,
                style: Style = .primary,
                actionRoute: String? = nil,
                actionPayload: [String: String]? = nil) {
        self.id = id
        self.title = title
        self.style = style
        self.actionRoute = actionRoute
        self.actionPayload = actionPayload
    }
}
