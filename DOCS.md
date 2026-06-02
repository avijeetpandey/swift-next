# SwiftNext — Full Documentation

> **Version:** 1.0 · **Swift 5.9+** · **Vapor 4** · **macOS 13+ / iOS 16+**

This document is the authoritative reference for every aspect of SwiftNext — from scaffolding your first project to deploying to production.

**Table of Contents**

- [Part 1 — Getting Started](#part-1--getting-started)
- [Part 2 — Backend Development](#part-2--backend-development)
- [Part 3 — Frontend Development](#part-3--frontend-development)
- [Part 4 — Database](#part-4--database)
- [Part 5 — Testing](#part-5--testing)
- [Part 6 — Deployment](#part-6--deployment)
- [Part 7 — Advanced Topics](#part-7--advanced-topics)

---

## Part 1 — Getting Started

### Prerequisites

Before using SwiftNext, ensure the following tools are installed:

| Tool | Version | How to install |
|---|---|---|
| Xcode | 15.0+ | Mac App Store or [developer.apple.com](https://developer.apple.com/xcode/) |
| Swift | 5.9+ | Bundled with Xcode 15 |
| macOS | 13.0+ (Ventura) | System Preferences → Software Update |
| Git | any recent | `xcode-select --install` |
| Make | any | Bundled with macOS |

Optional for PostgreSQL development:

```bash
# Install Docker Desktop for PostgreSQL
brew install --cask docker
```

### Installing the CLI

The `swiftnext-cli` tool lives inside the framework repository. Build it once and symlink it onto your `$PATH`:

```bash
# 1. Clone the framework
git clone https://github.com/avijeetpandey/swift-next.git
cd swift-next

# 2. Build the CLI in release mode
swift build -c release --product swiftnext-cli

# 3. Symlink to /usr/local/bin (or any directory on $PATH)
ln -sf "$(pwd)/.build/release/swiftnext-cli" /usr/local/bin/swiftnext-cli

# 4. Verify
swiftnext-cli --version
```

If you prefer not to symlink, you can always run the CLI directly from the framework repo:

```bash
swift run swiftnext-cli <command>
```

### Scaffolding a New Project

```bash
swiftnext-cli init MyApp
```

This command:
1. Creates a `MyApp/` directory in the current working directory.
2. Writes a complete `Package.swift` with all SPM targets configured.
3. Generates source files for the server kit, thin server executable, and SwiftUI app.
4. Writes a `.env` file pre-populated with sensible defaults (SQLite, port 8080).
5. Writes a `Makefile` with `build`, `run-backend`, `run-frontend`, `run-all`, `test`, and `clean` targets.
6. Creates `.vscode/tasks.json` for VS Code users.
7. Creates stub test files for backend routes and UI renderer.

```bash
cd MyApp
make run-all   # ← starts server + opens SwiftUI app
```

### Project File Tour

```
MyApp/
├── Package.swift
```

The SPM manifest. Declares three main targets: `MyAppServerKit` (Vapor library), `MyAppServer` (thin executable), and `MyAppApp` (SwiftUI app). You will add new source files here as your app grows.

```
├── .env
```

Environment variables for local development. **Never commit this file.** Add `.env` to `.gitignore`.

```
├── Makefile
```

Convenience targets. `make run-all` is the primary development command — it starts the Vapor server in one process and the macOS SwiftUI app in another.

```
├── Sources/MyAppServerKit/Configuration/configure.swift
```

Bootstraps the Vapor `Application`: registers middleware (CORS, error), configures the database driver (reads `DB_DRIVER` from environment), and calls `RouteRegistry.register(on:)`.

```
├── Sources/MyAppServerKit/Configuration/databases.swift
```

Contains the `configureDatabases(_:)` function. Checks `DB_DRIVER` env var — `"sqlite"` uses `FluentSQLiteDriver` with `SQLITE_PATH`, `"postgres"` uses `FluentPostgresDriver` with individual `POSTGRES_*` vars.

```
├── Sources/MyAppServerKit/Controllers/PageController.swift
```

Your primary work area on the backend. Each function here corresponds to one screen in your app. Functions return `PagePayload`.

```
├── Sources/MyAppServerKit/Models/AppModels.swift
```

Place all Fluent model definitions here, or split into one file per model as your project grows.

```
├── Sources/MyAppServerKit/Migrations/
```

One migration file per schema change. `MigrationsRegistry.swift` lists them in order.

```
├── Sources/MyAppServerKit/Routes/RouteRegistry.swift
```

Single call site that registers all `RouteCollection` instances onto the Vapor `Application`.

```
├── Sources/MyAppServer/main.swift
```

Three lines: import, configure, run. This is intentionally thin so all logic lives in the testable `ServerKit` library target.

```
├── Sources/MyAppApp/MyAppApp.swift
```

`@main` SwiftUI `App`. Opens a `WindowGroup` containing `SwiftNextPageView(path: "/pages/home")`.

```
├── Sources/MyAppApp/InProcessServer.swift
```

Manages the `swift run MyAppServer` subprocess and the FSEvents file watcher for hot reload.

```
└── Tests/
```

`BackendTests/RouteTests.swift` uses `XCTVapor` to make real HTTP requests against an in-process app. `UIComponentsTests/RendererTests.swift` tests that component JSON round-trips correctly.

### First Run

**Option A — Xcode (recommended)**

```bash
open Package.swift
```

Select the `MyAppApp` scheme, press **Cmd+R**. Xcode builds all targets, `InProcessServer` spawns the Vapor server automatically, and the SwiftUI window appears.

**Option B — Terminal**

```bash
# Terminal 1: start backend
make run-backend

# Terminal 2: start frontend
make run-frontend
```

**Option C — Concurrent via Makefile**

```bash
make run-all
```

---

## Part 2 — Backend Development

### How Routing Works

SwiftNext uses Vapor's `RouteCollection` protocol. Each controller conforms to it, implementing `boot(routes:)` to register its paths:

```swift
// Sources/MyAppServerKit/Controllers/PageController.swift
import Vapor
import SharedModels

public struct PageController: RouteCollection {
    public func boot(routes: RoutesBuilder) throws {
        let pages = routes.grouped("pages")
        pages.get("home",    use: home)
        pages.get("about",   use: about)

        let actions = routes.grouped("actions")
        actions.post("submit", use: submit)
    }

    @Sendable
    func home(_ req: Request) async throws -> PagePayload { … }
}
```

Then register it in `RouteRegistry`:

```swift
// Sources/MyAppServerKit/Routes/RouteRegistry.swift
import Vapor

public enum RouteRegistry {
    public static func register(on app: Application) throws {
        try app.register(collection: HealthController())
        try app.register(collection: PageController())
        // Add more controllers here
    }
}
```

### Creating a New Page Endpoint

Here is a complete example — a blog posts listing page that reads from the database:

```swift
// In PageController.swift, inside boot(routes:):
pages.get("posts", use: posts)

// Handler:
@Sendable
func posts(_ req: Request) async throws -> PagePayload {
    let allPosts = try await Post.query(on: req.db)
        .sort(\.$createdAt, .descending)
        .all()

    var children: [SwiftNextComponent] = [
        .text(TextSpec(
            id: "heading",
            content: "Latest Posts",
            size: .largeTitle,
            weight: .bold,
            alignment: .leading
        ))
    ]

    for post in allPosts {
        children.append(.vstack(VStackSpec(
            id: "post-\(post.id!)",
            alignment: .leading,
            spacing: 4,
            padding: EdgePadding(top: 12, leading: 0, bottom: 12, trailing: 0),
            children: [
                .text(TextSpec(
                    id: "title-\(post.id!)",
                    content: post.title,
                    size: .headline,
                    weight: .semibold
                )),
                .text(TextSpec(
                    id: "body-\(post.id!)",
                    content: post.body,
                    size: .body,
                    color: ColorToken(semantic: .secondary)
                )),
                .divider(DividerSpec(id: "div-\(post.id!)"))
            ]
        )))
    }

    return PagePayload(
        title: "Blog",
        tree: [
            .vstack(VStackSpec(
                id: "root",
                alignment: .leading,
                spacing: 0,
                padding: EdgePadding(top: 24, leading: 24, bottom: 24, trailing: 24),
                children: children
            ))
        ]
    )
}
```

The client accesses this page via `SwiftNextPageView(path: "/pages/posts")`.

### Server Actions

A Server Action is any `POST` handler that returns a `PagePayload`. Buttons and text fields in the component tree reference an action via `actionRoute`.

```swift
// Boot registration
actions.post("create-post", use: createPost)

// Handler
private struct CreatePostInput: Content {
    let title: String
    let body: String
}

@Sendable
func createPost(_ req: Request) async throws -> PagePayload {
    let input = try req.content.decode(CreatePostInput.self)

    let post = Post(title: input.title, body: input.body)
    try await post.save(on: req.db)

    // Return a fresh page tree — the client replaces its current tree
    return PagePayload(
        title: "Post Created",
        tree: [
            .vstack(VStackSpec(
                id: "root",
                alignment: .center,
                spacing: 16,
                padding: EdgePadding(top: 40, leading: 24, bottom: 40, trailing: 24),
                children: [
                    .text(TextSpec(
                        id: "success",
                        content: "✅ '\(post.title)' was published.",
                        size: .title2,
                        weight: .semibold,
                        alignment: .center
                    )),
                    .button(ButtonSpec(
                        id: "back",
                        title: "Back to posts",
                        style: .secondary,
                        actionRoute: "/pages/posts"
                    ))
                ]
            ))
        ]
    )
}
```

On the client side, a button wired to this action looks like:

```swift
.button(ButtonSpec(
    id: "publish-btn",
    title: "Publish",
    style: .primary,
    actionRoute: "/actions/create-post",
    actionPayload: ["title": "My first post", "body": "Hello, world!"]
))
```

### Creating a Fluent Model

Each Fluent model lives in its own file. Here is a complete `Post` model:

```swift
// Sources/MyAppServerKit/Models/Post.swift
import Fluent
import Foundation

final class Post: Model, @unchecked Sendable {
    static let schema = "posts"

    @ID(format: .uuid)
    var id: UUID?

    @Field(key: "title")
    var title: String

    @Field(key: "body")
    var body: String

    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?

    @Timestamp(key: "updated_at", on: .update)
    var updatedAt: Date?

    init() {}

    init(id: UUID? = nil, title: String, body: String) {
        self.id = id
        self.title = title
        self.body = body
    }
}
```

### Writing a Migration

Migrations describe schema changes. One file per migration, named chronologically:

```swift
// Sources/MyAppServerKit/Migrations/CreatePost.swift
import Fluent

struct CreatePost: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("posts")
            .id()
            .field("title",      .string,   .required)
            .field("body",       .string,   .required)
            .field("created_at", .datetime)
            .field("updated_at", .datetime)
            .create()
    }

    func revert(on database: Database) async throws {
        try await database.schema("posts").delete()
    }
}
```

### Registering Models and Migrations

Add the migration to `MigrationsRegistry`:

```swift
// Sources/MyAppServerKit/Migrations/MigrationsRegistry.swift
import Fluent

public enum MigrationsRegistry {
    public static func register(migrations: Migrations) {
        migrations.add(CreatePost())
        // Order matters — add new migrations at the bottom
    }
}
```

### Using the Database in a Controller

Controllers receive a `Request` whose `.db` property provides a `Database` handle:

```swift
// Fetch all
let posts = try await Post.query(on: req.db).all()

// Fetch by ID
guard let post = try await Post.find(id, on: req.db) else {
    throw Abort(.notFound)
}

// Save
let newPost = Post(title: "Hello", body: "World")
try await newPost.save(on: req.db)

// Update
post.title = "Updated title"
try await post.save(on: req.db)

// Delete
try await post.delete(on: req.db)
```

### Query Examples

```swift
// Filter
let published = try await Post.query(on: req.db)
    .filter(\.$title == "SwiftNext")
    .all()

// Sort
let sorted = try await Post.query(on: req.db)
    .sort(\.$createdAt, .descending)
    .all()

// Pagination
let page = try await Post.query(on: req.db)
    .sort(\.$createdAt, .descending)
    .paginate(PageRequest(page: 1, per: 10))
// page.items = [Post], page.metadata.total = Int

// Count
let count = try await Post.query(on: req.db).count()
```

### Relationships (One-to-Many Example)

```swift
// Models
final class Author: Model, @unchecked Sendable {
    static let schema = "authors"
    @ID(format: .uuid) var id: UUID?
    @Field(key: "name") var name: String
    @Children(for: \.$author) var posts: [Post]
    init() {}
    init(name: String) { self.name = name }
}

final class Post: Model, @unchecked Sendable {
    static let schema = "posts"
    @ID(format: .uuid) var id: UUID?
    @Field(key: "title") var title: String
    @Parent(key: "author_id") var author: Author
    init() {}
}

// Eager load in a query
let authors = try await Author.query(on: req.db)
    .with(\.$posts)
    .all()
// authors[0].posts is now populated
```

### Custom JSON Responses

For endpoints that don't return `PagePayload` (e.g., REST-style data APIs):

```swift
struct PostDTO: Content {
    let id: UUID
    let title: String
    let body: String
}

func apiPosts(_ req: Request) async throws -> [PostDTO] {
    let posts = try await Post.query(on: req.db).all()
    return posts.map { PostDTO(id: $0.id!, title: $0.title, body: $0.body) }
}
```

---

## Part 3 — Frontend Development

### How SwiftNextPageView Works

`SwiftNextPageView` is the primary entry point for the client. It:

1. Calls `NetworkEngine.shared.fetchPage(path)` — a `GET` request to `SWIFTNEXT_API_BASE_URL + path`.
2. Decodes the JSON body as `PagePayload`.
3. Sets the navigation title from `payload.title`.
4. Renders `payload.tree` through `SwiftNextTree` → `SwiftNextRenderer` → Native* views.
5. Creates a `DefaultActionDispatcher` that wires button taps and field submissions back to the server.
6. Listens for `.swiftNextServerReloaded` to trigger hot-reload.

```swift
// MyAppApp.swift
import SwiftUI
import SwiftNextClient

@main
struct MyAppApp: App {
    var body: some Scene {
        WindowGroup {
            NavigationStack {
                SwiftNextPageView(path: "/pages/home")
            }
        }
    }
}
```

### All 9 Components — Server-Side Swift Examples

#### VStack

```swift
.vstack(VStackSpec(
    id: "card",
    alignment: .leading,       // .leading | .center | .trailing
    spacing: 12,
    padding: EdgePadding(top: 16, leading: 16, bottom: 16, trailing: 16),
    children: [/* nested components */],
    actionRoute: nil           // optional tap target on the whole stack
))
```

#### HStack

```swift
.hstack(HStackSpec(
    id: "toolbar",
    alignment: .center,        // .top | .center | .bottom
    spacing: 8,
    padding: EdgePadding(top: 0, leading: 16, bottom: 0, trailing: 16),
    children: [
        .text(TextSpec(id: "label", content: "Status:")),
        .spacer(SpacerSpec(id: "flex")),
        .text(TextSpec(id: "value", content: "Active", color: ColorToken(semantic: .accent)))
    ]
))
```

#### ZStack

```swift
.zstack(ZStackSpec(
    id: "overlay-card",
    alignment: .bottomLeading,
    padding: EdgePadding(top: 0, leading: 0, bottom: 0, trailing: 0),
    children: [
        .image(ImageSpec(id: "bg", url: "https://example.com/photo.jpg", width: 320, height: 200)),
        .text(TextSpec(id: "caption", content: "Caption text", color: ColorToken(hex: "#FFFFFF"),
                       size: .caption, weight: .semibold))
    ]
))
```

#### Text

```swift
.text(TextSpec(
    id: "headline",
    content: "SwiftNext makes full-stack Swift fast.",
    size: .headline,           // any FontSizeToken
    weight: .semibold,         // any FontWeightToken
    alignment: .leading,       // .leading | .center | .trailing
    color: ColorToken(semantic: .primary)   // or ColorToken(hex: "#333333")
))
```

#### Button

```swift
.button(ButtonSpec(
    id: "delete-btn",
    title: "Delete Account",
    style: .destructive,       // .primary | .secondary | .plain | .destructive
    actionRoute: "/actions/delete-account",
    actionPayload: ["confirm": "true"]
))
```

#### TextField

```swift
.textField(TextFieldSpec(
    id: "email-field",
    placeholder: "Enter your email",
    actionRoute: "/actions/subscribe",   // POSTed when user submits
    actionPayload: ["source": "homepage"],
    isSecure: false
))
```

For a password field:

```swift
.textField(TextFieldSpec(
    id: "password",
    placeholder: "Password",
    actionRoute: "/actions/login",
    isSecure: true
))
```

#### Image

```swift
// Remote URL
.image(ImageSpec(
    id: "hero",
    url: "https://example.com/hero.jpg",
    width: 320,
    height: 180,
    contentMode: .fill          // .fit | .fill
))

// SF Symbol
.image(ImageSpec(
    id: "icon",
    systemName: "star.fill",
    width: 24,
    height: 24
))

// Tappable image
.image(ImageSpec(
    id: "banner",
    url: "https://example.com/banner.jpg",
    actionRoute: "/pages/campaign"
))
```

#### Spacer

```swift
.spacer(SpacerSpec(id: "flex-gap", minLength: 16))
```

#### Divider

```swift
.divider(DividerSpec(
    id: "section-divider",
    color: ColorToken(semantic: .secondary),
    thickness: 1
))
```

### Design Tokens

Design tokens are `Codable` enums and structs shared between server and client via `SharedModels`. The client's `Modifier` extensions map them to SwiftUI equivalents at render time — you never reference UIKit or SwiftUI font/color APIs directly in your server code.

**FontSizeToken → SwiftUI mapping**

| Token | SwiftUI Font |
|---|---|
| `.largeTitle` | `.largeTitle` |
| `.title` | `.title` |
| `.title2` | `.title2` |
| `.title3` | `.title3` |
| `.headline` | `.headline` |
| `.subheadline` | `.subheadline` |
| `.body` | `.body` |
| `.callout` | `.callout` |
| `.footnote` | `.footnote` |
| `.caption` | `.caption` |
| `.caption2` | `.caption2` |

**ColorToken resolution**

`ColorToken(semantic: .accent)` resolves to the app's `AccentColor` asset in the asset catalog. `ColorToken(hex: "#FF6B35")` is decoded as a hex color. Both are resolved by the `ColorToken+SwiftUI` modifier extension in `SwiftNextClient`.

**EdgePadding**

```swift
// All sides equal
EdgePadding(top: 16, leading: 16, bottom: 16, trailing: 16)

// Horizontal only
EdgePadding(top: 0, leading: 24, bottom: 0, trailing: 24)

// Zero padding
EdgePadding(top: 0, leading: 0, bottom: 0, trailing: 0)
```

### Nested Components — Building Complex Layouts

Components compose recursively. Here is a card-grid pattern:

```swift
func dashboard(_ req: Request) async throws -> PagePayload {
    let stats = [("Users", "1,024"), ("Posts", "342"), ("Revenue", "$8,450")]

    let cards: [SwiftNextComponent] = stats.map { (label, value) in
        .vstack(VStackSpec(
            id: "card-\(label)",
            alignment: .leading,
            spacing: 4,
            padding: EdgePadding(top: 16, leading: 16, bottom: 16, trailing: 16),
            children: [
                .text(TextSpec(id: "val-\(label)", content: value,
                               size: .title, weight: .bold)),
                .text(TextSpec(id: "lbl-\(label)", content: label,
                               size: .caption, color: ColorToken(semantic: .secondary)))
            ]
        ))
    }

    return PagePayload(title: "Dashboard", tree: [
        .vstack(VStackSpec(
            id: "root",
            alignment: .leading,
            spacing: 16,
            padding: EdgePadding(top: 24, leading: 24, bottom: 24, trailing: 24),
            children: [
                .text(TextSpec(id: "heading", content: "Dashboard",
                               size: .largeTitle, weight: .bold)),
                .hstack(HStackSpec(id: "cards-row", alignment: .top,
                                   spacing: 12, children: cards))
            ]
        ))
    ])
}
```

### Server Actions from the Client

When a user taps a `ButtonSpec` that has an `actionRoute`, the flow is:

1. `NativeButton` calls `dispatcher.dispatch(route:payload:)`.
2. `DefaultActionDispatcher` POSTs to `SWIFTNEXT_API_BASE_URL + actionRoute` with the `actionPayload` JSON body.
3. The response is decoded as `PagePayload`.
4. The closure passed to `DefaultActionDispatcher` at construction time is called with the new payload.
5. `SwiftNextPageView` replaces its `payload` state — SwiftUI re-renders.

This is entirely automatic. You do not write any networking or state management code in the client.

### TextField Submissions

When a user submits a text field (presses Return), `NativeTextField` calls `dispatcher.dispatch(route:payload:)` with `["value": currentText]` merged with the field's `actionPayload`. The server receives this as a `Content`-decodable struct:

```swift
private struct FieldInput: Content { let value: String }

@Sendable
func handleSearch(_ req: Request) async throws -> PagePayload {
    let input = try req.content.decode(FieldInput.self)
    let query = input.value
    let results = try await Post.query(on: req.db)
        .filter(\.$title ~~ query)
        .all()
    // Build and return result PagePayload
}
```

### Multi-Page Navigation (Sidebar Pattern)

For macOS apps with sidebars, use a `NavigationSplitView` and multiple `SwiftNextPageView` instances:

```swift
// MyAppApp.swift
import SwiftUI
import SwiftNextClient

@main
struct MyAppApp: App {
    @State private var selectedPage: String = "/pages/home"

    var body: some Scene {
        WindowGroup {
            NavigationSplitView {
                List(selection: $selectedPage) {
                    Label("Home",      systemImage: "house").tag("/pages/home")
                    Label("Posts",     systemImage: "doc.text").tag("/pages/posts")
                    Label("Dashboard", systemImage: "chart.bar").tag("/pages/dashboard")
                }
                .navigationTitle("MyApp")
            } detail: {
                SwiftNextPageView(path: selectedPage)
            }
        }
    }
}
```

`SwiftNextPageView` automatically fetches the new path whenever `selectedPage` changes — navigation is zero boilerplate.

### Hot Reload Workflow

During development:

1. Run `make run-all` or open in Xcode with the `MyAppApp` scheme.
2. Edit any `.swift` file in `Sources/MyAppServerKit/` — e.g., change the text in `PageController`.
3. Save the file.
4. Within 2–5 seconds the running app shows the "Reloading…" badge, then updates automatically.

You never need to press Stop → Run. The `InProcessServer` class handles the entire cycle.

---

## Part 4 — Database

### SQLite — Zero-Config Development

SQLite is the default driver. No installation, no daemon, no credentials:

```
# .env
DB_DRIVER=sqlite
SQLITE_PATH=swiftnext.db
```

The database file is created in the working directory on first launch. It's a standard SQLite3 file — you can inspect it with any SQLite browser.

**Resetting the database during development:**

```bash
rm swiftnext.db
make run-backend   # recreates and re-migrates automatically
```

### PostgreSQL — Production Setup

Switch to Postgres for production by changing two env vars:

```
# .env (production)
DB_DRIVER=postgres
POSTGRES_HOST=localhost
POSTGRES_PORT=5432
POSTGRES_USER=myapp
POSTGRES_PASSWORD=s3cr3t
POSTGRES_DB=myapp_production
```

**Local development with Docker:**

```bash
docker run -d \
  --name swiftnext-postgres \
  -e POSTGRES_USER=swiftnext \
  -e POSTGRES_PASSWORD=swiftnext \
  -e POSTGRES_DB=swiftnext \
  -p 5432:5432 \
  postgres:16-alpine
```

### Running Migrations Manually

```bash
# Apply all pending migrations
swift run MyAppServer migrate

# Revert the last batch
swift run MyAppServer migrate --revert

# Revert all
swift run MyAppServer migrate --revert --all
```

### Auto-Migrate Flag

In development, pass `--auto-migrate` to apply pending migrations on every server boot. This is what `make run-backend` does:

```bash
swift run MyAppServer --auto-migrate
```

In production, run migrations as a separate step before deploying to avoid downtime races.

### Reverting Migrations

Each migration implements `revert(on:)`. Fluent tracks which migrations have been applied in a `_fluent_migrations` table. Reverting removes the most recently applied batch:

```bash
swift run MyAppServer migrate --revert
```

If you need to revert and re-apply from scratch (development only):

```bash
swift run MyAppServer migrate --revert --all
swift run MyAppServer --auto-migrate
```

### Database Best Practices

- **One migration per schema change.** Never edit an existing migration that has been applied to any environment.
- **Add columns as nullable or with defaults** so existing rows are valid without a backfill.
- **Use `@Timestamp(on: .create)` and `@Timestamp(on: .update)`** on all models for free audit fields.
- **Index foreign keys.** Fluent doesn't add indexes automatically; add `.field("author_id", .uuid, .required).constraint(.references("authors", "id"))` explicitly.
- **Do not share the development SQLite file across team members.** Each developer runs their own local database.

---

## Part 5 — Testing

### Backend Tests (XCTVapor)

SwiftNext uses `XCTVapor` for integration tests — it spins up the full Vapor application in-process and makes real HTTP requests without a network:

```swift
// Tests/BackendTests/RouteTests.swift
import XCTest
import XCTVapor
@testable import MyAppServerKit

final class RouteTests: XCTestCase {

    var app: Application!

    override func setUp() async throws {
        app = try await Application.make(.testing)
        try await configure(app)
        // Use a separate in-memory SQLite DB for each test run
        app.databases.use(.sqlite(.memory), as: .sqlite, isDefault: true)
        try await app.autoMigrate()
    }

    override func tearDown() async throws {
        try await app.autoRevert()
        try await app.asyncShutdown()
    }

    func testHomePageReturns200() async throws {
        try await app.test(.GET, "/pages/home") { res in
            XCTAssertEqual(res.status, .ok)
        }
    }

    func testHomePagePayloadHasTitle() async throws {
        try await app.test(.GET, "/pages/home") { res async throws in
            let payload = try res.content.decode(PagePayload.self)
            XCTAssertEqual(payload.title, "Home")
        }
    }

    func testGreetActionReturnsName() async throws {
        try await app.test(.POST, "/actions/greet",
            beforeRequest: { req in
                try req.content.encode(["value": "Alice"])
            },
            afterResponse: { res async throws in
                let payload = try res.content.decode(PagePayload.self)
                // Find the greeting text component
                let root = payload.tree.first!
                if case .vstack(let spec) = root,
                   case .text(let textSpec) = spec.children.first! {
                    XCTAssertTrue(textSpec.content.contains("Alice"))
                } else {
                    XCTFail("Expected vstack > text structure")
                }
            }
        )
    }
}
```

### Round-Trip Component Tests

Verify that components survive a full encode→decode cycle:

```swift
// Tests/SharedModelsTests/ComponentRoundTripTests.swift
import XCTest
import SharedModels

final class ComponentRoundTripTests: XCTestCase {

    let encoder = JSONEncoder()
    let decoder = JSONDecoder()

    func testTextRoundTrip() throws {
        let original = SwiftNextComponent.text(TextSpec(
            id: "t1",
            content: "Hello",
            size: .headline,
            weight: .bold
        ))
        let data    = try encoder.encode(original)
        let decoded = try decoder.decode(SwiftNextComponent.self, from: data)

        if case .text(let spec) = decoded {
            XCTAssertEqual(spec.content, "Hello")
            XCTAssertEqual(spec.size, .headline)
            XCTAssertEqual(spec.weight, .bold)
        } else {
            XCTFail("Expected .text")
        }
    }

    func testVStackWithChildrenRoundTrip() throws {
        let original = SwiftNextComponent.vstack(VStackSpec(
            id: "root",
            alignment: .leading,
            spacing: 12,
            children: [
                .text(TextSpec(id: "c1", content: "Child"))
            ]
        ))
        let data    = try encoder.encode(original)
        let decoded = try decoder.decode(SwiftNextComponent.self, from: data)

        if case .vstack(let spec) = decoded {
            XCTAssertEqual(spec.children.count, 1)
        } else {
            XCTFail("Expected .vstack")
        }
    }

    func testPagePayloadRoundTrip() throws {
        let payload = PagePayload(title: "Test", tree: [
            .text(TextSpec(id: "t", content: "Hi"))
        ])
        let data    = try encoder.encode(payload)
        let decoded = try decoder.decode(PagePayload.self, from: data)
        XCTAssertEqual(decoded.title, "Test")
        XCTAssertEqual(decoded.tree.count, 1)
    }
}
```

### Writing a Vapor Route Test

The pattern for testing route-specific behaviour:

```swift
func testCreatePostReturnsSuccessTree() async throws {
    try await app.test(.POST, "/actions/create-post",
        beforeRequest: { req in
            try req.content.encode(["title": "My Post", "body": "Hello world"])
        },
        afterResponse: { res async throws in
            XCTAssertEqual(res.status, .ok)
            let payload = try res.content.decode(PagePayload.self)
            XCTAssertEqual(payload.title, "Post Created")
        }
    )
}
```

### Client / Renderer Tests

Renderer tests verify that a `SwiftNextComponent` value produces the correct `View` type. Because `SwiftNextRenderer` is a SwiftUI `View`, use `@MainActor` and `ViewInspector` (or test via snapshot) in your UIComponentsTests target:

```swift
// Tests/UIComponentsTests/RendererTests.swift
import XCTest
import SharedModels
@testable import SwiftNextClient

final class RendererTests: XCTestCase {

    func testRendererAcceptsAllComponentKinds() {
        let components: [SwiftNextComponent] = [
            .text(TextSpec(id: "1", content: "Hi")),
            .button(ButtonSpec(id: "2", title: "Go")),
            .spacer(SpacerSpec(id: "3")),
            .divider(DividerSpec(id: "4")),
            .image(ImageSpec(id: "5", systemName: "star")),
            .textField(TextFieldSpec(id: "6", placeholder: "Type…")),
            .vstack(VStackSpec(id: "7", alignment: .leading, spacing: 8, children: [])),
            .hstack(HStackSpec(id: "8", alignment: .center, spacing: 8, children: [])),
            .zstack(ZStackSpec(id: "9", alignment: .center, children: []))
        ]
        // Verify every component has a stable id (exhaustive coverage)
        let ids = components.map(\.id)
        XCTAssertEqual(Set(ids).count, components.count, "All component IDs must be unique")
    }
}
```

### Running Tests

```bash
# All tests in parallel
make test

# Equivalent direct command
swift test --parallel

# Specific test target
swift test --filter BackendTests

# Single test method
swift test --filter RouteTests/testHomePageReturns200
```

### Test Isolation

Always use in-memory SQLite for tests to avoid pollution between runs:

```swift
// In setUp():
app.databases.use(.sqlite(.memory), as: .sqlite, isDefault: true)
try await app.autoMigrate()

// In tearDown():
try await app.autoRevert()
```

This ensures each test class starts with a clean schema and fresh data.

---

## Part 6 — Deployment

### Building for Production

```bash
# Release build (optimised, strips debug symbols)
swift build -c release

# The server binary is at:
.build/release/MyAppServer
```

### Frontend-Only Deployment (macOS App Bundle)

1. Open `Package.swift` in Xcode.
2. Select the `MyAppApp` scheme.
3. Set `SWIFTNEXT_API_BASE_URL` in the scheme's **Run** environment to your production server URL.
4. **Product → Archive**.
5. Use the Organizer to notarize and export a `.app` bundle or submit to the Mac App Store.

For iOS/iPadOS, add the iOS target to the scheme and follow standard App Store submission.

### Backend-Only Deployment (Linux Server)

SwiftNext's Vapor backend runs natively on Linux. Build on Ubuntu:

```bash
# On Ubuntu 22.04 with Swift 5.9 installed
swift build -c release --product MyAppServer
sudo cp .build/release/MyAppServer /usr/local/bin/myapp-server

# Run with systemd or supervisor
/usr/local/bin/myapp-server --auto-migrate
```

### Dockerfile for the Vapor Backend

```dockerfile
# Dockerfile
FROM swift:5.9-jammy AS builder
WORKDIR /app
COPY . .
RUN swift build -c release --product MyAppServer

FROM ubuntu:22.04
RUN apt-get update && apt-get install -y \
    libssl-dev \
    libsqlite3-dev \
    && rm -rf /var/lib/apt/lists/*
WORKDIR /app
COPY --from=builder /app/.build/release/MyAppServer .
COPY --from=builder /app/.env.production .env
EXPOSE 8080
ENTRYPOINT ["./MyAppServer", "--auto-migrate", "--hostname", "0.0.0.0", "--port", "8080"]
```

Build and run:

```bash
docker build -t myapp-server .
docker run -d -p 8080:8080 --env-file .env.production myapp-server
```

### docker-compose.yml (Full Stack with PostgreSQL)

```yaml
# docker-compose.yml
version: "3.9"

services:
  db:
    image: postgres:16-alpine
    restart: unless-stopped
    environment:
      POSTGRES_USER: myapp
      POSTGRES_PASSWORD: s3cr3t
      POSTGRES_DB: myapp_production
    volumes:
      - postgres_data:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U myapp"]
      interval: 5s
      timeout: 5s
      retries: 5

  server:
    build: .
    restart: unless-stopped
    ports:
      - "8080:8080"
    environment:
      DB_DRIVER: postgres
      POSTGRES_HOST: db
      POSTGRES_PORT: 5432
      POSTGRES_USER: myapp
      POSTGRES_PASSWORD: s3cr3t
      POSTGRES_DB: myapp_production
      SERVER_HOST: 0.0.0.0
      SERVER_PORT: 8080
    depends_on:
      db:
        condition: service_healthy

volumes:
  postgres_data:
```

```bash
docker-compose up -d
docker-compose logs -f server
```

### Environment Variables for Production

| Variable | Required | Default | Description |
|---|---|---|---|
| `SERVER_HOST` | No | `0.0.0.0` | Bind address |
| `SERVER_PORT` | No | `8080` | Listen port |
| `DB_DRIVER` | No | `sqlite` | `sqlite` or `postgres` |
| `SQLITE_PATH` | If SQLite | `swiftnext.db` | Path to database file |
| `POSTGRES_HOST` | If Postgres | — | DB hostname |
| `POSTGRES_PORT` | If Postgres | `5432` | DB port |
| `POSTGRES_USER` | If Postgres | — | DB username |
| `POSTGRES_PASSWORD` | If Postgres | — | DB password |
| `POSTGRES_DB` | If Postgres | — | DB name |
| `SWIFTNEXT_API_BASE_URL` | Client | `http://localhost:8080` | Base URL the client fetches from |

### Nginx Reverse Proxy

Place Nginx in front of the Vapor server to handle TLS and serve static assets:

```nginx
# /etc/nginx/sites-available/myapp
server {
    listen 443 ssl http2;
    server_name myapp.example.com;

    ssl_certificate     /etc/letsencrypt/live/myapp.example.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/myapp.example.com/privkey.pem;

    location / {
        proxy_pass         http://127.0.0.1:8080;
        proxy_http_version 1.1;
        proxy_set_header   Host              $host;
        proxy_set_header   X-Real-IP         $remote_addr;
        proxy_set_header   X-Forwarded-For   $proxy_add_x_forwarded_for;
        proxy_set_header   X-Forwarded-Proto $scheme;
        proxy_read_timeout 90;
    }
}

server {
    listen 80;
    server_name myapp.example.com;
    return 301 https://$host$request_uri;
}
```

---

## Part 7 — Advanced Topics

### Adding a Custom Component (End-to-End)

This section walks through adding a hypothetical `ProgressBarSpec` component.

**Step 1 — SharedModels: define the spec**

```swift
// Sources/SharedModels/Models/Progress/ProgressBarSpec.swift
import Foundation

public struct ProgressBarSpec: UIPrimitive {
    public let id: String
    public let value: Double        // 0.0 – 1.0
    public let tint: ColorToken?
    public let trackColor: ColorToken?
    public let actionRoute: String? = nil  // UIPrimitive conformance

    public init(id: String, value: Double,
                tint: ColorToken? = nil,
                trackColor: ColorToken? = nil) {
        self.id = id
        self.value = value
        self.tint = tint
        self.trackColor = trackColor
    }
}
```

**Step 2 — SharedModels: add the enum case**

```swift
// SwiftNextComponent.swift
case progressBar(ProgressBarSpec)   // add in appropriate MARK section
```

Add the corresponding `CodingKeys` handling:

```swift
// Kind enum
case progressBar

// init(from:)
case .progressBar: self = .progressBar(try c.decode(ProgressBarSpec.self, forKey: .spec))

// encode(to:)
case .progressBar(let s): try c.encode(Kind.progressBar, forKey: .type); try c.encode(s, forKey: .spec)

// id property
case .progressBar(let s): return s.id

// actionRoute property
case .progressBar(let s): return s.actionRoute
```

**Step 3 — SwiftNextClient: native view wrapper**

```swift
// Sources/SwiftNextClient/Components/NativeProgressBar.swift
#if canImport(SwiftUI)
import SwiftUI
import SharedModels

@available(iOS 16.0, macOS 13.0, *)
struct NativeProgressBar: View {
    let spec: ProgressBarSpec

    var body: some View {
        ProgressView(value: spec.value)
            .tint(spec.tint.map { Color(colorToken: $0) })
    }
}
#endif
```

**Step 4 — SwiftNextClient: add case to renderer**

```swift
// SwiftNextRenderer.swift — inside body's switch
case .progressBar(let s): NativeProgressBar(spec: s)
```

**Step 5 — Write tests**

```swift
// Tests/SharedModelsTests/ComponentRoundTripTests.swift
func testProgressBarRoundTrip() throws {
    let original = SwiftNextComponent.progressBar(
        ProgressBarSpec(id: "pb", value: 0.75, tint: ColorToken(semantic: .accent))
    )
    let data    = try encoder.encode(original)
    let decoded = try decoder.decode(SwiftNextComponent.self, from: data)
    if case .progressBar(let spec) = decoded {
        XCTAssertEqual(spec.value, 0.75)
    } else { XCTFail() }
}
```

**Step 6 — Update DOCS.md and component reference table in README.md.**

### Custom Action Dispatcher

Replace the default POST-based dispatcher with your own logic (e.g., to add auth headers):

```swift
// MyAppApp.swift
final class AuthActionDispatcher: SwiftNextActionDispatcher {
    let token: String
    var onPayload: ((PagePayload) -> Void)?

    init(token: String, onPayload: @escaping (PagePayload) -> Void) {
        self.token = token
        self.onPayload = onPayload
    }

    func dispatch(route: String, payload: [String: String]) async {
        guard let url = URL(string: ProcessInfo.processInfo.environment["SWIFTNEXT_API_BASE_URL"]! + route)
        else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.httpBody = try? JSONEncoder().encode(payload)
        guard let (data, _) = try? await URLSession.shared.data(for: request),
              let newPayload = try? JSONDecoder().decode(PagePayload.self, from: data)
        else { return }
        await MainActor.run { onPayload?(newPayload) }
    }
}
```

Pass it to `SwiftNextTree` by overriding `SwiftNextPageView` or composing around `SwiftNextTree` directly.

### Authentication Pattern (JWT Header Passing)

On the server, add a Vapor middleware that validates a `Bearer` token and injects the user into `req.auth`:

```swift
// Sources/MyAppServerKit/Middleware/JWTMiddleware.swift
import Vapor

struct JWTMiddleware: AsyncMiddleware {
    func respond(to request: Request, chainingTo next: AsyncResponder) async throws -> Response {
        guard let token = request.headers.bearerAuthorization?.token,
              let userID = validateJWT(token)   // your JWT validation logic
        else {
            throw Abort(.unauthorized)
        }
        request.auth.login(AuthenticatedUser(id: userID))
        return try await next.respond(to: request)
    }
}
```

Apply it to protected route groups:

```swift
let protected = routes.grouped(JWTMiddleware())
protected.get("pages", "profile", use: profile)
```

### Error Handling in Controllers

Throw `Abort` for HTTP-level errors. For user-facing errors in the component tree, return a `PagePayload` with an error message instead of throwing:

```swift
@Sendable
func profile(_ req: Request) async throws -> PagePayload {
    guard let user = try await UserSchema.find(req.parameters.get("id"), on: req.db) else {
        // HTTP-level 404 — useful for API clients
        throw Abort(.notFound, reason: "User not found")
    }
    return PagePayload(title: user.name, tree: [ /* profile tree */ ])
}

// Or return an error page for SDUI clients:
@Sendable
func safeProfile(_ req: Request) async throws -> PagePayload {
    do {
        guard let user = try await UserSchema.find(req.parameters.get("id"), on: req.db) else {
            return errorPage(message: "User not found.")
        }
        return PagePayload(title: user.name, tree: [ /* profile tree */ ])
    } catch {
        return errorPage(message: "Something went wrong.")
    }
}

private func errorPage(message: String) -> PagePayload {
    PagePayload(title: "Error", tree: [
        .vstack(VStackSpec(id: "err", alignment: .center, spacing: 12,
                           padding: EdgePadding(top: 40, leading: 24, bottom: 40, trailing: 24),
            children: [
                .text(TextSpec(id: "msg", content: message,
                               size: .body, color: ColorToken(semantic: .destructive)))
            ]))
    ])
}
```

### Logging

Vapor's `Logger` is available via `req.logger`:

```swift
req.logger.info("Fetching posts for user \(userID)")
req.logger.warning("Post not found: \(postID)")
req.logger.error("Database query failed: \(error)")
```

Configure the log level in `configure.swift`:

```swift
app.logger.logLevel = app.environment.isRelease ? .warning : .debug
```

### Performance Tips

- **Use `.paginate()` for any list endpoint** — never load unbounded arrays from the database.
- **Index frequently-queried columns.** Add `.constraint(.references(…))` or raw `CREATE INDEX` in a migration.
- **Cache static page trees** by computing them once at startup and returning the cached value in the handler. Use `actor` for thread-safe mutable caches.
- **Minimize component nesting depth.** Deep trees are decoded recursively — prefer flat structures where possible.
- **Use `@Sendable` on all handler closures** to catch data-race issues at compile time.
- **Enable Vapor's response compression** middleware for JSON-heavy page payloads over slow connections:

```swift
// configure.swift
app.middleware.use(DeflateMiddleware())
```
