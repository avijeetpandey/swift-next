//
//  TextSpec.swift
//  SharedModels
//
import Foundation

public struct TextSpec: UIPrimitive {
    public let id: String
    public let content: String
    public let size: FontSizeToken
    public let weight: FontWeightToken
    public let alignment: TextAlignmentToken
    public let color: ColorToken?
    public let actionRoute: String?

    public init(id: String,
                content: String,
                size: FontSizeToken = .body,
                weight: FontWeightToken = .regular,
                alignment: TextAlignmentToken = .leading,
                color: ColorToken? = nil,
                actionRoute: String? = nil) {
        self.id = id
        self.content = content
        self.size = size
        self.weight = weight
        self.alignment = alignment
        self.color = color
        self.actionRoute = actionRoute
    }
}
