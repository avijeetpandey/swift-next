//
//  MigrationsRegistry.swift
//  SwiftNextServer
//
//  Single registration point for every Fluent migration. Adding a new
//  schema means appending one line here.
//
import Vapor
import Fluent

public enum MigrationsRegistry {
    public static func register(on app: Application) {
        app.migrations.add(CreateUser())
    }
}
