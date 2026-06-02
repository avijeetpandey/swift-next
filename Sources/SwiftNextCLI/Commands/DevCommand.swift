//
//  DevCommand.swift
//  SwiftNextCLI
//
//  `swiftnext-cli dev` — concurrently boots the Vapor backend and the
//  AppLauncher client (delegates to `make run-all` so the behaviour
//  matches every other entry-point).
//
import ArgumentParser
import Foundation

struct DevCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "dev",
        abstract: "Boot the server and the SwiftUI client concurrently."
    )

    func run() async throws {
        try ShellRunner.runForeground(
            "/usr/bin/env",
            arguments: ["make", "run-all"]
        )
    }
}
