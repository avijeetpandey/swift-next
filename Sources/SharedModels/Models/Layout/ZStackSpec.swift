//
//  ZStackSpec.swift
//  SharedModels
//
import Foundation

public struct ZStackSpec: UIPrimitive {
    public let id: String
    public let alignment: StackAlignment
    public let padding: EdgePadding
    public let children: [SwiftNextComponent]
    public let actionRoute: String?

    public init(id: String,
                alignment: StackAlignment = .center,
                padding: EdgePadding = .zero,
                children: [SwiftNextComponent],
                actionRoute: String? = nil) {
        self.id = id
        self.alignment = alignment
        self.padding = padding
        self.children = children
        self.actionRoute = actionRoute
    }
}
