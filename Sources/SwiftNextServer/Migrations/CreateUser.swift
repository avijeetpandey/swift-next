//
//  CreateUser.swift
//  SwiftNextServer
//
import Fluent

public struct CreateUser: AsyncMigration {

    public init() {}

    public func prepare(on database: Database) async throws {
        try await database.schema(UserSchema.schema)
            .id()
            .field("email", .string, .required)
            .field("display_name", .string, .required)
            .field("created_at", .datetime)
            .unique(on: "email")
            .create()
    }

    public func revert(on database: Database) async throws {
        try await database.schema(UserSchema.schema).delete()
    }
}
