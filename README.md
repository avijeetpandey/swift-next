<div align="center">

```
 ███████╗██╗    ██╗██╗███████╗████████╗███╗   ██╗███████╗██╗  ██╗████████╗
 ██╔════╝██║    ██║██║██╔════╝╚══██╔══╝████╗  ██║██╔════╝╚██╗██╔╝╚══██╔══╝
 ███████╗██║ █╗ ██║██║█████╗     ██║   ██╔██╗ ██║█████╗   ╚███╔╝    ██║   
 ╚════██║██║███╗██║██║██╔══╝     ██║   ██║╚██╗██║██╔══╝   ██╔██╗    ██║   
 ███████║╚███╔███╔╝██║██║        ██║   ██║ ╚████║███████╗██╔╝ ██╗   ██║   
 ╚══════╝ ╚══╝╚══╝ ╚═╝╚═╝        ╚═╝   ╚═╝  ╚═══╝╚══════╝╚═╝  ╚═╝   ╚═╝  
```

**The full-stack Swift framework · Server-Driven UI · Zero config · Hot reload**

![Swift 5.9+](https://img.shields.io/badge/Swift-5.9%2B-FA7343?style=flat-square&logo=swift&logoColor=white)
![macOS 13+](https://img.shields.io/badge/macOS-13%2B-000000?style=flat-square&logo=apple&logoColor=white)
![iOS 16+](https://img.shields.io/badge/iOS-16%2B-000000?style=flat-square&logo=apple&logoColor=white)
![Vapor 4](https://img.shields.io/badge/Vapor-4-6B57FF?style=flat-square)
![License MIT](https://img.shields.io/badge/License-MIT-blue?style=flat-square)
![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen?style=flat-square)

</div>

---

## ✨ What is SwiftNext?

SwiftNext is a **full-stack Swift framework** that lets you build the entire product — server, API, and native UI — in a single Swift codebase. Inspired by Next.js, it pairs a **Vapor 4 + Fluent** backend with a **SwiftUI** frontend through a **Server-Driven UI (SDUI)** architecture: your Vapor route returns a tree of `SwiftNextComponent` JSON, and the SwiftUI client renders it as 100 % native views on macOS, iOS, and iPadOS.

Unlike traditional iOS/macOS development where the server team owns a REST API and the client team owns the UI code, SwiftNext collapses both into one package. You share `Codable` types, design tokens, and validation logic between layers — no code generation, no OpenAPI, no duplication. The result is a workflow that feels as fast as a JavaScript meta-framework but produces native Apple platform apps backed by a production-grade Swift server.

---

## 🏗 Architecture

```
┌──────────────────────────────────────────────────────────────────────────┐
│                         SwiftNext Data Flow                              │
├──────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│   ╔══════════════╗    HTTP GET     ╔══════════════════════╗              │
│   ║  SwiftUI App ║ ◄────────────── ║   Vapor 4 Backend    ║              │
│   ║  (macOS/iOS) ║                 ║  (SwiftNextServerKit) ║              │
│   ╚══════╤═══════╝  PagePayload    ╚══════════╤═══════════╝              │
│          │           JSON                      │                          │
│          ▼                                     │ Fluent ORM               │
│   ╔══════════════╗                    ╔════════▼══════════╗              │
│   ║ NetworkEngine║                    ║  SQLite/Postgres  ║              │
│   ╚══════╤═══════╝                    ╚═══════════════════╝              │
│          │                                                                │
│          ▼                                                                │
│   ╔══════════════════╗                                                   │
│   ║SwiftNextRenderer ║  ← exhaustive switch over SwiftNextComponent      │
│   ╚══════╤═══════════╝                                                   │
│          │                                                                │
│          ▼                                                                │
│   ╔══════════════════════════════════════════════════════╗               │
│   ║  NativeVStack / NativeText / NativeButton / …        ║               │
│   ║  100 % native SwiftUI — zero WebView                 ║               │
│   ╚══════════════════════════════════════════════════════╝               │
│                                                                          │
│  Server Actions (button taps / field submissions):                       │
│   NativeButton ──POST /actions/greet──► Vapor handler ──► new PagePayload│
└──────────────────────────────────────────────────────────────────────────┘
```

---

## 🚀 Quick Start

> **Requirements:** Xcode 15+, Swift 5.9+, macOS 13+

```bash
# 1. Clone and build the framework + CLI
git clone https://github.com/avijeetpandey/swift-next.git
cd swift-next
swift build

# 2. Scaffold a new project
swift run swiftnext-cli init MyApp

# 3. Enter your project
cd MyApp

# 4. Start the full stack (server + client simultaneously)
make run-all

# 5. Open in Xcode for hot-reload development
open Package.swift
```

Your app is now running at `http://localhost:8080` with the SwiftUI client connected. Edit any `.swift` file under `Sources/` and the UI reloads automatically — no Cmd+R required.

---

## 📂 Project Structure

After `swiftnext-cli init MyApp`, your project looks like this:

```
MyApp/
├── Package.swift                      ← SPM manifest, declares all targets
├── .env                               ← Local env vars (not committed)
├── Makefile                           ← build / run / test shortcuts
├── .vscode/
│   └── tasks.json                     ← VS Code tasks for run-all / test
│
├── Sources/
│   ├── MyAppServerKit/                ← Vapor library (all server logic)
│   │   ├── Configuration/
│   │   │   ├── configure.swift        ← App bootstrap (middleware, DB, routes)
│   │   │   └── databases.swift        ← SQLite / Postgres driver selection
│   │   ├── Controllers/
│   │   │   └── PageController.swift   ← Page endpoints + Server Actions
│   │   ├── Models/
│   │   │   └── AppModels.swift        ← Fluent model definitions
│   │   ├── Migrations/
│   │   │   ├── CreateJoke.swift       ← Example migration (delete & replace)
│   │   │   └── MigrationsRegistry.swift
│   │   └── Routes/
│   │       └── RouteRegistry.swift    ← Registers all RouteCollections
│   │
│   ├── MyAppServer/
│   │   └── main.swift                 ← Thin executable, calls ServerKit
│   │
│   └── MyAppApp/
│       ├── MyAppApp.swift             ← @main SwiftUI App entry point
│       └── InProcessServer.swift      ← FSEvents watcher + hot-reload logic
│
└── Tests/
    ├── BackendTests/
    │   └── RouteTests.swift           ← XCTVapor integration tests
    └── UIComponentsTests/
        └── RendererTests.swift        ← Renderer unit tests
```

---

## 🧠 Key Concepts

### Server-Driven UI (SDUI)

In SwiftNext, the server **owns the layout**. Instead of the client hard-coding view logic, each screen is described by a `PagePayload` the server returns:

```swift
// Server (Vapor handler)
func home(_ req: Request) async throws -> PagePayload {
    PagePayload(title: "Home", tree: [
        .vstack(VStackSpec(
            id: "root",
            alignment: .leading,
            spacing: 16,
            padding: EdgePadding(top: 24, leading: 24, bottom: 24, trailing: 24),
            children: [
                .text(TextSpec(id: "h1", content: "Hello", size: .largeTitle, weight: .bold)),
                .button(ButtonSpec(id: "cta", title: "Learn more", actionRoute: "/actions/detail"))
            ]
        ))
    ])
}
```

The client fetches this JSON and renders it with zero layout logic of its own.

### PagePayload

The top-level envelope returned by every page endpoint:

```swift
public struct PagePayload: Codable, Hashable, Sendable {
    public let title: String            // Sets the navigation bar title
    public let tree: [SwiftNextComponent]  // Root-level component array
}
```

### SwiftNextComponent

A recursive, `Codable` enum — the single source of truth for every UI node that can travel from server to client:

```json
{
  "type": "vstack",
  "spec": {
    "id": "root",
    "alignment": "leading",
    "spacing": 16,
    "children": [
      { "type": "text",   "spec": { "id": "t1", "content": "Welcome", "size": "largeTitle", "weight": "bold" } },
      { "type": "button", "spec": { "id": "b1", "title": "Continue", "style": "primary", "actionRoute": "/actions/next" } }
    ]
  }
}
```

### Server Actions

Buttons and text fields carry an `actionRoute`. When triggered, the client POSTs to that route and replaces the current page tree with the response — enabling full server-round-trip mutations without any client-side state management:

```
User taps button
      │
      ▼
NativeButton fires DefaultActionDispatcher
      │
      ├── POST /actions/greet  { "value": "Alice" }
      │
      ▼
Vapor handler returns new PagePayload
      │
      ▼
SwiftNextPageView replaces tree → UI updates
```

---

## 🛠 CLI Commands

| Command | Description |
|---|---|
| `swiftnext-cli init <ProjectName>` | Scaffold a complete new SwiftNext project |
| `swiftnext-cli dev` | Start server + client with hot reload |
| `swiftnext-cli test` | Run all tests (equivalent to `swift test --parallel`) |

### Makefile Targets (framework & scaffolded projects)

| Target | Description |
|---|---|
| `make build` | Compile all targets |
| `make run-backend` | Start the Vapor server (auto-migrates) |
| `make run-frontend` | Launch the macOS SwiftUI app |
| `make run-all` | Start server and client concurrently |
| `make test` | Run all tests in parallel |
| `make clean` | Remove `.build` directory |

---

## 🧩 Component Reference

All 9 built-in components, their `type` string, and key properties:

| Component | `type` | Key Properties |
|---|---|---|
| **VStack** | `vstack` | `alignment` (leading/center/trailing), `spacing`, `padding`, `children[]` |
| **HStack** | `hstack` | `alignment` (top/center/bottom), `spacing`, `padding`, `children[]` |
| **ZStack** | `zstack` | `alignment` (9-point grid), `padding`, `children[]` |
| **Text** | `text` | `content`, `size` (FontSizeToken), `weight` (FontWeightToken), `color`, `alignment` |
| **Button** | `button` | `title`, `style` (primary/secondary/plain/destructive), `actionRoute`, `actionPayload` |
| **TextField** | `textField` | `placeholder`, `actionRoute`, `actionPayload`, `isSecure` |
| **Image** | `image` | `url`, `systemName` (SF Symbol), `width`, `height`, `contentMode`, `actionRoute` |
| **Spacer** | `spacer` | `minLength` |
| **Divider** | `divider` | `color`, `thickness` |

### Design Tokens

**Font sizes** (`FontSizeToken`): `largeTitle`, `title`, `title2`, `title3`, `headline`, `subheadline`, `body`, `callout`, `footnote`, `caption`, `caption2`

**Font weights** (`FontWeightToken`): `ultraLight`, `thin`, `light`, `regular`, `medium`, `semibold`, `bold`, `heavy`, `black`

**Colors** (`ColorToken`): semantic roles (`primary`, `secondary`, `accent`, `background`, `foreground`, `destructive`) or hex strings (`"#FF6B35"`, `"#FF6B35CC"` with alpha)

**Alignment** (`StackAlignment`): `leading`, `center`, `trailing`, `top`, `bottom`, `topLeading`, `topTrailing`, `bottomLeading`, `bottomTrailing`

---

## 🗄 Database

SwiftNext supports **SQLite** (zero-config, development default) and **PostgreSQL** (production).

### SQLite — No Setup Required

```bash
# .env
DB_DRIVER=sqlite
SQLITE_PATH=swiftnext.db
```

The database file is created automatically on first run. Perfect for local development.

### PostgreSQL — Production Grade

```bash
# .env
DB_DRIVER=postgres
POSTGRES_HOST=localhost
POSTGRES_PORT=5432
POSTGRES_USER=swiftnext
POSTGRES_PASSWORD=swiftnext
POSTGRES_DB=swiftnext
```

Switch between them by changing `DB_DRIVER` — no code changes required.

### Migrations

```bash
# Auto-migrate on server boot (recommended for development)
swift run SwiftNextServer --auto-migrate

# Or via Makefile
make run-backend   # includes --auto-migrate
```

---

## ♻️ Hot Reload

SwiftNext ships a first-class hot-reload experience for full-stack development:

1. **`InProcessServer`** in your SwiftUI app spawns `swift run MyAppServer --auto-migrate` as a subprocess.
2. **FSEvents** watches every `.swift` file under `Sources/` with an 800 ms debounce to avoid rebuilds on rapid saves.
3. On change: the old server process is killed, `swift run` is re-invoked (which recompiles and restarts the server).
4. `Notification.Name.swiftNextServerReloaded` is posted on the main thread.
5. **`SwiftNextPageView`** catches the notification, shows a `"Reloading…"` badge, and retries the page fetch with a 1.5 s backoff loop until the server is back up.
6. The UI updates **automatically** — you see your backend and layout changes in the running app within seconds.

```
Save .swift file
      │
      ▼ (800ms debounce)
FSEvents fires
      │
      ├── kill old SwiftNextServer process
      ├── swift run MyAppServer --auto-migrate  (recompile + restart)
      └── post .swiftNextServerReloaded notification
                │
                ▼
        SwiftNextPageView
              │
              ├── shows "Reloading…" badge
              └── retries fetchPage() every 1.5s
                        │
                        ▼ (server back up)
                  UI updates ✅
```

---

## 🚢 Deployment

For full deployment guides, see **[📖 DOCS.md → Part 6: Deployment](DOCS.md#part-6--deployment)**.

### Overview

| Target | Command | Notes |
|---|---|---|
| Release build | `swift build -c release` | Produces optimized binary |
| macOS app bundle | Xcode Archive | Standard `.app` distribution |
| Linux server (Docker) | See `Dockerfile` in DOCS.md | Vapor runs natively on Linux |
| docker-compose (full stack) | See `docker-compose.yml` in DOCS.md | Postgres + server in containers |

---

## 📋 Requirements

| Requirement | Minimum Version |
|---|---|
| Xcode | 15.0+ |
| Swift | 5.9+ |
| macOS (development) | 13.0+ (Ventura) |
| iOS/iPadOS deployment target | 16.0+ |
| Vapor | 4.92+ |
| Fluent | 4.9+ |

---

## 📚 Documentation & Links

| Resource | Description |
|---|---|
| 📖 [DOCS.md](DOCS.md) | Full documentation — getting started, backend, frontend, database, testing, deployment, advanced topics |
| 🤝 [CONTRIBUTING.md](CONTRIBUTING.md) | How to contribute — setup, conventions, component checklist, PR guide |

---

## 📄 License

SwiftNext is released under the **MIT License**.  
See [LICENSE](LICENSE) for details.

---

<div align="center">
Built with ❤️ in Swift · <a href="DOCS.md">Documentation</a> · <a href="CONTRIBUTING.md">Contributing</a>
</div>
