//
//  TestCommand.swift
//  SwiftNextCLI
//
//  `swiftnext-cli test` — runs every test target via `swift test`.
//
import ArgumentParser
import Foundation

struct TestCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "test",
        abstract: "Run BackendTests, UIComponentsTests and SharedModelsTests."
    )

    func run() async throws {
        try ShellRunner.runForeground(
            "/usr/bin/env",
            arguments: ["swift", "test", "--parallel"]
        )
    }
}
