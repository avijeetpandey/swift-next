//
//  RouteRegistry.swift
//  SwiftNextServer
//
//  Central route registration. Each controller exposes a `boot(routes:)`
//  function (Vapor's `RouteCollection`) so the registry stays minimal.
//
import Vapor

public enum RouteRegistry {
    public static func register(on app: Application) throws {
        try app.register(collection: HealthController())
        try app.register(collection: PageController())
        try app.register(collection: UserController())
    }
}
