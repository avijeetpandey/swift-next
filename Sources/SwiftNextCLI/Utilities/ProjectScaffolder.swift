//
//  ProjectScaffolder.swift
//  SwiftNextCLI
//
//  Materialises the canonical SwiftNext directory tree on disk.
//
//  The full tree is generated programmatically (rather than copied
//  from disk) so the CLI binary is self-contained — no template
//  resources need to be located at runtime.
//
import Foundation

struct ProjectScaffolder {

    func scaffold(at root: URL, projectName: String) throws {
        let fm = FileManager.default
        try fm.createDirectory(at: root, withIntermediateDirectories: true)

        // Directories
        let dirs = [
            "Sources/\(projectName)ServerKit/Configuration",
            "Sources/\(projectName)ServerKit/Controllers",
            "Sources/\(projectName)ServerKit/Models",
            "Sources/\(projectName)ServerKit/Migrations",
            "Sources/\(projectName)ServerKit/Routes",
            "Sources/\(projectName)Server",
            "Sources/\(projectName)App",
            "Tests/BackendTests",
            "Tests/UIComponentsTests",
            ".vscode"
        ]
        for dir in dirs {
            try fm.createDirectory(at: root.appendingPathComponent(dir),
                                   withIntermediateDirectories: true)
        }

        // Files (each one is a single-responsibility .swift / config file)
        for (relPath, content) in ProjectTemplates.files(projectName: projectName) {
            let url = root.appendingPathComponent(relPath)
            try fm.createDirectory(at: url.deletingLastPathComponent(),
                                   withIntermediateDirectories: true)
            try content.write(to: url, atomically: true, encoding: .utf8)
        }

        // Touch SQLite file (zero-config dev DB)
        let dbURL = root.appendingPathComponent("swiftnext.db")
        if !fm.fileExists(atPath: dbURL.path) {
            fm.createFile(atPath: dbURL.path, contents: Data())
        }
    }
}
