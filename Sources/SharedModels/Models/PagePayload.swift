//
//  PagePayload.swift
//  SharedModels
//
//  Top-level envelope returned by the server's page endpoints.
//  Wrapping the tree in an envelope lets us evolve metadata
//  (titles, navigation hints, cache tags) without breaking clients.
//
import Foundation

public struct PagePayload: Codable, Hashable, Sendable {
    public let title: String
    public let tree: [SwiftNextComponent]

    public init(title: String, tree: [SwiftNextComponent]) {
        self.title = title
        self.tree = tree
    }
}
