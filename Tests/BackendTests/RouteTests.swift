//
//  RouteTests.swift
//  BackendTests
//
//  Vapor route + Server Action integration tests.
//
import XCTVapor
import SharedModels
@testable import SwiftNextServerKit

final class RouteTests: XCTestCase {

    private func makeApp() async throws -> Application {
        let app = try await Application.make(.testing)
        // Per-test isolated SQLite file so `--parallel` runs don't collide.
        let dbPath = NSTemporaryDirectory()
            + "swiftnext-test-\(UUID().uuidString).sqlite"
        setenv("DB_DRIVER", "sqlite", 1)
        setenv("SQLITE_PATH", dbPath, 1)
        try ServerConfiguration.configure(app)
        try await app.autoMigrate()
        return app
    }

    func testHealth() async throws {
        let app = try await makeApp()
        defer { Task { try? await app.asyncShutdown() } }
        try await app.test(.GET, "/health") { res in
            XCTAssertEqual(res.status, .ok)
            XCTAssertTrue(res.body.string.contains("SwiftNextServer"))
        }
    }

    func testHomePageReturnsTree() async throws {
        let app = try await makeApp()
        defer { Task { try? await app.asyncShutdown() } }
        try await app.test(.GET, "/pages/home") { res in
            XCTAssertEqual(res.status, .ok)
            let payload = try res.content.decode(PagePayload.self)
            XCTAssertEqual(payload.title, "Home")
            XCTAssertFalse(payload.tree.isEmpty)
        }
    }

    func testGreetServerAction() async throws {
        let app = try await makeApp()
        defer { Task { try? await app.asyncShutdown() } }
        try await app.test(.POST, "/actions/greet",
                           beforeRequest: { req in
            try req.content.encode(["value": "Avijeet"])
        }) { res in
            XCTAssertEqual(res.status, .ok)
            let payload = try res.content.decode(PagePayload.self)
            XCTAssertEqual(payload.title, "Greeting")
        }
    }

    func testCreateAndListUser() async throws {
        let app = try await makeApp()
        defer { Task { try? await app.asyncShutdown() } }
        try await app.test(.POST, "/users",
                           beforeRequest: { req in
            try req.content.encode(["email": "a@b.com", "displayName": "A"])
        }) { res in
            XCTAssertEqual(res.status, .ok)
        }
        try await app.test(.GET, "/users") { res in
            XCTAssertEqual(res.status, .ok)
            XCTAssertTrue(res.body.string.contains("a@b.com"))
        }
    }
}
