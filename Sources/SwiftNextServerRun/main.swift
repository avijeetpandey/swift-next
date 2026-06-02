//
//  main.swift
//  SwiftNextServer
//
//  Process entry-point. Keeps logic out of the @main attribute so the
//  configure() routine remains unit-testable.
//
import Vapor
import SwiftNextServerKit

var env = try Environment.detect()
try LoggingSystem.bootstrap(from: &env)

let app = try await Application.make(env)
do {
    try ServerConfiguration.configure(app)
    try await app.execute()
} catch {
    app.logger.report(error: error)
    try? await app.asyncShutdown()
    throw error
}
try await app.asyncShutdown()
