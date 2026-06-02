//
//  UserSchema.swift
//  SwiftNextServer
//
//  Fluent model. Single-responsibility: this file owns *only* the
//  database row shape. Controllers project it to/from DTOs.
//
import Fluent
import Vapor

public final class UserSchema: Model, Content, @unchecked Sendable {
    public static let schema = "users"

    @ID(key: .id) public var id: UUID?
    @Field(key: "email") public var email: String
    @Field(key: "display_name") public var displayName: String
    @Timestamp(key: "created_at", on: .create) public var createdAt: Date?

    public init() {}

    public init(id: UUID? = nil, email: String, displayName: String) {
        self.id = id
        self.email = email
        self.displayName = displayName
    }
}
