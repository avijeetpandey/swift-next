//
//  HealthController.swift
//  SwiftNextServer
//
import Vapor

public struct HealthController: RouteCollection {

    public init() {}

    public func boot(routes: RoutesBuilder) throws {
        routes.get("health", use: health)
    }

    @Sendable
    func health(_ req: Request) async throws -> [String: String] {
        ["status": "ok", "service": "SwiftNextServer"]
    }
}
