//
//  InitCommand.swift
//  SwiftNextCLI
//
//  `swiftnext-cli init <ProjectName>` — generates the canonical
//  directory tree, default boilerplates, .env, Makefile, .vscode tasks
//  and an empty SQLite database file.
//
import ArgumentParser
import Foundation

struct InitCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "init",
        abstract: "Scaffold a new SwiftNext project."
    )

    @Argument(help: "Name of the project (also the directory name).")
    var projectName: String

    @Option(name: .shortAndLong, help: "Parent directory in which to create the project.")
    var path: String = "."

    func run() async throws {
        let root = URL(fileURLWithPath: path)
            .appendingPathComponent(projectName, isDirectory: true)
        try ProjectScaffolder().scaffold(at: root, projectName: projectName)
        print("✅  Created \(projectName) at \(root.path)")
        print("")
        print("ONE-CLICK RUN in Xcode:")
        print("  1. open \(root.path)/Package.swift")
        print("  2. Select scheme \"\(projectName)App\" → destination \"My Mac\"")
        print("  3. Press ▶ Run  (server + UI start together)")
        print("")
        print("Terminal alternative:")
        print("  cd \(root.path) && make run-all")
    }
}
