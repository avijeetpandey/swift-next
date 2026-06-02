//
//  databases.swift
//  SwiftNextServer
//
//  ┌──────────────────────────────────────────────────────────────────┐
//  │  ZERO-CONFIG DATABASE BOOTSTRAP                                  │
//  ├──────────────────────────────────────────────────────────────────┤
//  │  Resolution order:                                               │
//  │    1. DB_DRIVER=postgres → uses POSTGRES_* env vars              │
//  │    2. DB_DRIVER=sqlite or unset → opens ./swiftnext.db           │
//  │  This means a brand-new clone runs `swift run SwiftNextServer    │
//  │  --auto-migrate` and is immediately persisting data without any  │
//  │  external service.                                               │
//  └──────────────────────────────────────────────────────────────────┘
//
import Vapor
import Fluent
import FluentPostgresDriver
import FluentSQLiteDriver

public enum DatabaseBootstrap {

    /// Wires up Fluent against either Postgres or SQLite based on the
    /// process environment, then registers every migration declared by
    /// `MigrationsRegistry`.
    public static func configure(_ app: Application) throws {
        let driver = Environment.get("DB_DRIVER")?.lowercased() ?? "sqlite"

        switch driver {
        case "postgres", "postgresql", "psql":
            let host     = Environment.get("POSTGRES_HOST")     ?? "localhost"
            let port     = Environment.get("POSTGRES_PORT").flatMap(Int.init)
                                ?? PostgresConfiguration.ianaPortNumber
            let username = Environment.get("POSTGRES_USER")     ?? "swiftnext"
            let password = Environment.get("POSTGRES_PASSWORD") ?? "swiftnext"
            let database = Environment.get("POSTGRES_DB")       ?? "swiftnext"

            app.databases.use(
                .postgres(
                    configuration: .init(
                        hostname: host,
                        port: port,
                        username: username,
                        password: password,
                        database: database,
                        tls: .disable
                    )
                ),
                as: .psql
            )
            app.logger.info("SwiftNext: connected to Postgres at \(host):\(port)/\(database)")

        default:
            let path = Environment.get("SQLITE_PATH") ?? "swiftnext.db"
            app.databases.use(.sqlite(.file(path)), as: .sqlite)
            app.logger.info("SwiftNext: using local SQLite store at \(path)")
        }

        MigrationsRegistry.register(on: app)
    }
}
