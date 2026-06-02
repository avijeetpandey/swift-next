//
//  SwiftNextCLI.swift
//  SwiftNextCLI
//
//  Top-level entry-point for the `swiftnext-cli` binary.
//  Sub-commands live in their own files (single-responsibility).
//
import ArgumentParser

@main
struct SwiftNextCLI: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "swiftnext-cli",
        abstract: "Scaffold, run and test SwiftNext projects.",
        version: "0.1.0",
        subcommands: [InitCommand.self, DevCommand.self, TestCommand.self],
        defaultSubcommand: nil
    )
}
