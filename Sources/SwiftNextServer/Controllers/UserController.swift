//
//  UserController.swift
//  SwiftNextServer
//
import Vapor
import Fluent

public struct UserController: RouteCollection {

    public init() {}

    public func boot(routes: RoutesBuilder) throws {
        let users = routes.grouped("users")
        users.get(use: list)
        users.post(use: create)
    }

    @Sendable
    func list(_ req: Request) async throws -> [UserSchema] {
        try await UserSchema.query(on: req.db).all()
    }

    private struct CreateInput: Content {
        let email: String
        let displayName: String
    }

    @Sendable
    func create(_ req: Request) async throws -> UserSchema {
        let input = try req.content.decode(CreateInput.self)
        let user = UserSchema(email: input.email, displayName: input.displayName)
        try await user.save(on: req.db)
        return user
    }
}
