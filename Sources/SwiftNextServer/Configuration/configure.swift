//
//  configure.swift
//  SwiftNextServer
//
//  Top-level boot routine. Called by `main.swift` before `app.run()`.
//  Configures: networking, JSON, database, migrations and routes.
//
import Vapor
import Fluent

public enum ServerConfiguration {

    public static func configure(_ app: Application) throws {
        // Networking
        app.http.server.configuration.hostname =
            Environment.get("SERVER_HOST") ?? "0.0.0.0"
        app.http.server.configuration.port =
            Environment.get("SERVER_PORT").flatMap(Int.init) ?? 8080

        // JSON: ISO-8601 dates by default for stable wire contracts.
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        ContentConfiguration.global.use(encoder: encoder, for: .json)
        ContentConfiguration.global.use(decoder: decoder, for: .json)

        // Database + migrations
        try DatabaseBootstrap.configure(app)

        // Auto-migrate when --auto-migrate is passed (zero-config dev).
        if app.environment.arguments.contains("--auto-migrate") {
            app.logger.info("SwiftNext: --auto-migrate detected, applying migrations")
            try app.autoMigrate().wait()
        }

        // Routes
        try RouteRegistry.register(on: app)
    }
}
