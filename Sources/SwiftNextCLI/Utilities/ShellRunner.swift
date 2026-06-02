//
//  ShellRunner.swift
//  SwiftNextCLI
//
//  Tiny wrapper around `Process` for foreground command execution.
//
import Foundation

enum ShellRunner {

    @discardableResult
    static func runForeground(_ launchPath: String,
                              arguments: [String],
                              cwd: URL? = nil) throws -> Int32 {
        let p = Process()
        p.launchPath = launchPath
        p.arguments  = arguments
        if let cwd = cwd { p.currentDirectoryURL = cwd }
        p.standardOutput = FileHandle.standardOutput
        p.standardError  = FileHandle.standardError
        try p.run()
        p.waitUntilExit()
        return p.terminationStatus
    }
}
