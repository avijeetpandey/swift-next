//
//  PageController.swift
//  SwiftNextServer
//
//  ┌──────────────────────────────────────────────────────────────────┐
//  │  PAGE CONTROLLER — the Server-Driven UI entry point              │
//  ├──────────────────────────────────────────────────────────────────┤
//  │  Returns a `PagePayload` containing a tree of                    │
//  │  `SwiftNextComponent` values. Every page in your app is one      │
//  │  function in here. Buttons / fields can reference the           │
//  │  /actions/* routes which return a fresh tree (Server Actions).   │
//  └──────────────────────────────────────────────────────────────────┘
//
import Vapor
import Fluent
import SharedModels

public struct PageController: RouteCollection {

    public init() {}

    public func boot(routes: RoutesBuilder) throws {
        let pages = routes.grouped("pages")
        pages.get("home", use: home)

        let actions = routes.grouped("actions")
        actions.post("greet", use: greet)
    }

    // MARK: - Pages

    @Sendable
    func home(_ req: Request) async throws -> PagePayload {
        let userCount = try await UserSchema.query(on: req.db).count()

        let tree: [SwiftNextComponent] = [
            .vstack(VStackSpec(
                id: "root",
                alignment: .leading,
                spacing: 16,
                padding: EdgePadding(top: 24, leading: 24, bottom: 24, trailing: 24),
                children: [
                    .text(TextSpec(
                        id: "title",
                        content: "Welcome to SwiftNext",
                        size: .largeTitle,
                        weight: .bold,
                        alignment: .leading
                    )),
                    .text(TextSpec(
                        id: "subtitle",
                        content: "\(userCount) users registered.",
                        size: .body,
                        weight: .regular,
                        alignment: .leading,
                        color: ColorToken(semantic: .secondary)
                    )),
                    .textField(TextFieldSpec(
                        id: "name",
                        placeholder: "Your name",
                        actionRoute: "/actions/greet"
                    )),
                    .button(ButtonSpec(
                        id: "cta",
                        title: "Say hello",
                        style: .primary,
                        actionRoute: "/actions/greet"
                    ))
                ]
            ))
        ]
        return PagePayload(title: "Home", tree: tree)
    }

    // MARK: - Server Actions

    private struct GreetInput: Content { let value: String? }

    @Sendable
    func greet(_ req: Request) async throws -> PagePayload {
        let name = (try? req.content.decode(GreetInput.self).value) ?? "stranger"
        let tree: [SwiftNextComponent] = [
            .vstack(VStackSpec(
                id: "root",
                alignment: .center,
                spacing: 12,
                padding: EdgePadding(top: 24, leading: 24, bottom: 24, trailing: 24),
                children: [
                    .text(TextSpec(
                        id: "greeting",
                        content: "Hello, \(name)!",
                        size: .title,
                        weight: .semibold,
                        alignment: .center
                    ))
                ]
            ))
        ]
        return PagePayload(title: "Greeting", tree: tree)
    }
}
