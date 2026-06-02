//
//  HStackSpec.swift
//  SharedModels
//
import Foundation

public struct HStackSpec: UIPrimitive {
    public let id: String
    public let alignment: StackAlignment
    public let spacing: Double
    public let padding: EdgePadding
    public let children: [SwiftNextComponent]
    public let actionRoute: String?

    public init(id: String,
                alignment: StackAlignment = .center,
                spacing: Double = 8,
                padding: EdgePadding = .zero,
                children: [SwiftNextComponent],
                actionRoute: String? = nil) {
        self.id = id
        self.alignment = alignment
        self.spacing = spacing
        self.padding = padding
        self.children = children
        self.actionRoute = actionRoute
    }
}
