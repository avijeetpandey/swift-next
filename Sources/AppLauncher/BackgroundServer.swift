//
//  BackgroundServer.swift
//  AppLauncher
//
//  Owns the lifecycle of the detached `SwiftNextServer` process. Used
//  by the Xcode "Run" button so a single click boots both halves of
//  the stack.
//
import Foundation

final class BackgroundServer: @unchecked Sendable {

    static let shared = BackgroundServer()

    private var process: Process?
    private let lock = NSLock()

    func start() {
        lock.lock(); defer { lock.unlock() }
        guard process == nil else { return }

        let p = Process()
        p.launchPath = "/usr/bin/env"
        p.arguments = ["swift", "run", "SwiftNextServer", "--auto-migrate"]
        p.standardOutput = FileHandle.standardOutput
        p.standardError  = FileHandle.standardError
        do {
            try p.run()
            process = p
            FileHandle.standardError.write(Data("[AppLauncher] booted SwiftNextServer (pid \(p.processIdentifier))\n".utf8))
        } catch {
            FileHandle.standardError.write(Data("[AppLauncher] failed to launch server: \(error)\n".utf8))
        }
    }

    func startBlocking() {
        start()
        process?.waitUntilExit()
    }

    func stop() {
        lock.lock(); defer { lock.unlock() }
        process?.terminate()
        process = nil
    }
}
