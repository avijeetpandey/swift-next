//
//  ProjectTemplates.swift
//  SwiftNextCLI
//
//  Static dictionary of every file the scaffolder writes to disk.
//  Each entry corresponds to one file in the documented project tree.
//
//  Generated projects depend on the local SwiftNext framework via a
//  relative `path:` reference — no remote fetch required.
//
import Foundation

enum ProjectTemplates {

    static func files(projectName: String) -> [(String, String)] {
        return [
            ("Package.swift",          packageSwift(name: projectName)),
            (".env",                   envFile),
            (".gitignore",             gitignore),
            ("Makefile",               makefile(name: projectName)),
            (".vscode/tasks.json",     vscodeTasks),

            // ── \(projectName)ServerKit ─────────────────────────────────────────────
            // Library target: all Vapor/Fluent logic.
            // Imported by BOTH \(projectName)App (in-process) and \(projectName)Server (CLI).
            ("Sources/\(projectName)ServerKit/Configuration/configure.swift",  serverConfigure(name: projectName)),
            ("Sources/\(projectName)ServerKit/Configuration/databases.swift",  serverDatabases),
            ("Sources/\(projectName)ServerKit/Controllers/PageController.swift", serverPageController(name: projectName)),
            ("Sources/\(projectName)ServerKit/Models/UserSchema.swift",        serverUserSchema),
            ("Sources/\(projectName)ServerKit/Migrations/CreateUser.swift",    serverCreateUser),
            ("Sources/\(projectName)ServerKit/Migrations/MigrationsRegistry.swift", serverMigrationsRegistry(name: projectName)),
            ("Sources/\(projectName)ServerKit/Routes/RouteRegistry.swift",     serverRouteRegistry(name: projectName)),

            // ── \(projectName)Server ────────────────────────────────────────────────
            // Thin CLI executable — imports \(projectName)ServerKit.
            // Use: swift run \(projectName)Server --auto-migrate
            ("Sources/\(projectName)Server/main.swift", serverMain(name: projectName)),

            // ── \(projectName)App ───────────────────────────────────────────────────
            // SwiftUI app — also imports \(projectName)ServerKit and runs Vapor in-process.
            // ONE-CLICK RUN: open Package.swift in Xcode → scheme \(projectName)App → My Mac → ▶ Run
            ("Sources/\(projectName)App/\(projectName)App.swift",   appMain(name: projectName)),
            ("Sources/\(projectName)App/InProcessServer.swift",     appInProcessServer(name: projectName)),

            // ── Tests ───────────────────────────────────────────────────────────────
            ("Tests/BackendTests/RouteTests.swift",           testsRoutes(name: projectName)),
            ("Tests/UIComponentsTests/RendererTests.swift",   testsRenderer),

            ("README.md", readme(name: projectName))
        ]
    }

    // MARK: - Package.swift

    static func packageSwift(name: String) -> String {
        """
        // swift-tools-version:5.9
        //
        //  Package.swift — \(name)
        //
        //  Architecture:
        //    \(name)ServerKit  ← library with ALL Vapor/Fluent logic
        //         └── \(name)Server  ← thin CLI executable (swift run \(name)Server)
        //
        //    \(name)App  ← SwiftUI app, spawns \(name)Server subprocess
        //                  + FSEvents hot-reload watcher on Sources/
        //
        //  ONE CLICK in Xcode:
        //    1. File → Open → Package.swift
        //    2. Scheme picker → "\(name)App" → destination "My Mac"
        //    3. Press ▶ Run
        //       • App spawns `swift run \(name)Server --auto-migrate`
        //       • Edit any .swift in Sources/ → server rebuilds & restarts automatically
        //       • SwiftNextPageView reconnects the moment the server is back up
        //
        import PackageDescription

        let package = Package(
            name: "\(name)",
            platforms: [.macOS(.v13)],
            products: [
                .executable(name: "\(name)App",       targets: ["\(name)App"]),
                .executable(name: "\(name)Server",    targets: ["\(name)Server"]),
                .library(   name: "\(name)ServerKit", targets: ["\(name)ServerKit"])
            ],
            dependencies: [
                .package(path: "../swift-next")
            ],
            targets: [

                // MARK: — Server library (all business logic, importable by App)
                .target(
                    name: "\(name)ServerKit",
                    dependencies: [
                        .product(name: "SharedModels",       package: "swift-next"),
                        .product(name: "SwiftNextServerKit", package: "swift-next")
                    ],
                    path: "Sources/\(name)ServerKit"
                ),

                // MARK: — Thin CLI executable (for terminal / CI use)
                .executableTarget(
                    name: "\(name)Server",
                    dependencies: ["\(name)ServerKit"],
                    path: "Sources/\(name)Server"
                ),

                // MARK: — SwiftUI App
                // Spawns \(name)Server subprocess + FSEvents hot-reload watcher.
                // Does NOT import \(name)ServerKit directly — separate processes.
                .executableTarget(
                    name: "\(name)App",
                    dependencies: [
                        .product(name: "SwiftNextClient", package: "swift-next"),
                        .product(name: "SharedModels",    package: "swift-next")
                    ],
                    path: "Sources/\(name)App"
                ),

                // MARK: — Tests
                .testTarget(
                    name: "BackendTests",
                    dependencies: [
                        "\(name)ServerKit",
                        .product(name: "SharedModels",       package: "swift-next"),
                        .product(name: "SwiftNextServerKit", package: "swift-next")
                    ],
                    path: "Tests/BackendTests"
                ),
                .testTarget(
                    name: "UIComponentsTests",
                    dependencies: [
                        .product(name: "SharedModels",    package: "swift-next"),
                        .product(name: "SwiftNextClient", package: "swift-next")
                    ],
                    path: "Tests/UIComponentsTests"
                )
            ]
        )
        """
    }

    // MARK: - .env

    static let envFile = """
    SERVER_HOST=0.0.0.0
    SERVER_PORT=8080
    LOG_LEVEL=info
    DB_DRIVER=sqlite
    SQLITE_PATH=swiftnext.db
    POSTGRES_HOST=localhost
    POSTGRES_PORT=5432
    POSTGRES_USER=swiftnext
    POSTGRES_PASSWORD=swiftnext
    POSTGRES_DB=swiftnext
    SWIFTNEXT_API_BASE_URL=http://localhost:8080
    """

    // MARK: - .gitignore

    static let gitignore = """
    .build/
    .swiftpm/
    DerivedData/
    .swiftnext.server.pid
    swiftnext.db*
    .DS_Store
    """

    // MARK: - Makefile

    static func makefile(name: String) -> String {
        """
        SWIFT      ?= swift
        SERVER_BIN ?= \(name)Server
        SIMULATOR  ?= platform=iOS Simulator,name=iPhone 15

        .PHONY: build run-all run-backend run-frontend run-ios test clean

        build:
        \\t$(SWIFT) build

        run-backend:
        \\t$(SWIFT) run $(SERVER_BIN) --auto-migrate

        run-frontend:
        \\t$(SWIFT) run \(name)App

        run-ios:
        \\txcodebuild -scheme \(name)App -destination '$(SIMULATOR)' build

        run-all:
        \\t@( $(SWIFT) run $(SERVER_BIN) --auto-migrate & echo $$$$! > .swiftnext.server.pid ) ; \\
        \\t  trap 'kill `cat .swiftnext.server.pid` 2>/dev/null; rm -f .swiftnext.server.pid' EXIT INT TERM ; \\
        \\t  sleep 2 ; $(SWIFT) run \(name)App

        test:
        \\t$(SWIFT) test --parallel

        clean:
        \\t$(SWIFT) package clean && rm -rf .build .swiftnext.server.pid
        """
    }

    // MARK: - .vscode/tasks.json

    static let vscodeTasks = """
    {
      "version": "2.0.0",
      "tasks": [
        {
          "label": "SwiftNext: Run All",
          "type": "shell",
          "command": "make run-all",
          "group": { "kind": "build", "isDefault": true },
          "presentation": { "reveal": "always", "panel": "dedicated" }
        },
        {
          "label": "SwiftNext: Run Backend",
          "type": "shell",
          "command": "make run-backend",
          "presentation": { "reveal": "always", "panel": "dedicated" }
        },
        {
          "label": "SwiftNext: Run Frontend (macOS)",
          "type": "shell",
          "command": "make run-frontend",
          "presentation": { "reveal": "always", "panel": "dedicated" }
        },
        {
          "label": "SwiftNext: Test",
          "type": "shell",
          "command": "make test",
          "group": { "kind": "test", "isDefault": true },
          "presentation": { "reveal": "always", "panel": "dedicated" }
        }
      ]
    }
    """

    // MARK: - Server sources

    static func serverConfigure(name: String) -> String {
        """
        //  configure.swift — \(name)ServerKit
        //
        //  Boot routine. DatabaseBootstrap (from SwiftNextServerKit) already
        //  registers the base `users` migration via its own MigrationsRegistry.
        //  Add YOUR OWN app-specific migrations in MigrationsRegistry.swift —
        //  do NOT re-add the framework migrations here (that causes duplicates).
        //
        import Vapor
        import Fluent
        import SwiftNextServerKit

        public func configure(_ app: Application) throws {
            app.http.server.configuration.hostname =
                Environment.get("SERVER_HOST") ?? "0.0.0.0"
            app.http.server.configuration.port =
                Environment.get("SERVER_PORT").flatMap(Int.init) ?? 8080

            // ISO-8601 wire dates
            let enc = JSONEncoder(); enc.dateEncodingStrategy = .iso8601
            let dec = JSONDecoder(); dec.dateDecodingStrategy = .iso8601
            ContentConfiguration.global.use(encoder: enc, for: .json)
            ContentConfiguration.global.use(decoder: dec, for: .json)

            // Database (SQLite zero-config or Postgres via DB_DRIVER env var).
            // Also registers framework-level migrations (CreateUser etc.).
            try DatabaseBootstrap.configure(app)

            // Register THIS app's additional migrations (see MigrationsRegistry.swift)
            MigrationsRegistry.register(on: app)

            if app.environment.arguments.contains("--auto-migrate") {
                app.logger.info("[\(name)] auto-migrate: applying pending migrations")
                try app.autoMigrate().wait()
            }

            // Routes
            try app.register(collection: SwiftNextServerKit.HealthController())
            try app.register(collection: PageController())
        }
        """
    }

    static let serverDatabases = """
    //  databases.swift
    //
    //  Re-exports the framework's DatabaseBootstrap so app-level
    //  configure.swift can call it without a full import chain.
    //
    @_exported import SwiftNextServerKit
    """

    static func serverPageController(name: String) -> String {
        // NOTE: \\( in the template produces \( in the generated file,
        // which Swift then treats as string interpolation at runtime.
        let appName = name
        return """
        //  PageController.swift — \(appName)
        //
        //  Add your own pages here by appending routes in boot(routes:).
        //  Each handler returns a PagePayload whose `tree` is a nested
        //  [SwiftNextComponent] array rendered natively on the client.
        //
        //  Flow:  Swift server → PagePayload JSON → NetworkEngine →
        //         SwiftNextRenderer → native SwiftUI on the device.
        //
        import Vapor
        import Fluent
        import SharedModels
        import SwiftNextServerKit   // provides UserSchema

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
                let userLabel = userCount == 1 ? "user" : "users"

                return PagePayload(title: "\(appName)", tree: [
                    .vstack(VStackSpec(
                        id: "root",
                        alignment: .leading,
                        spacing: 20,
                        padding: EdgePadding(top: 32, leading: 24, bottom: 32, trailing: 24),
                        children: [
                            .text(TextSpec(
                                id: "title",
                                content: "Welcome to \(appName) 👋",
                                size: .largeTitle,
                                weight: .bold,
                                alignment: .leading
                            )),
                            .text(TextSpec(
                                id: "subtitle",
                                content: "\\(userCount) registered \\(userLabel)",
                                size: .body,
                                weight: .regular,
                                alignment: .leading,
                                color: ColorToken(semantic: .secondary)
                            )),
                            .divider(DividerSpec(id: "sep")),
                            .textField(TextFieldSpec(
                                id: "name-field",
                                placeholder: "Enter your name…",
                                actionRoute: "/actions/greet"
                            )),
                            .button(ButtonSpec(
                                id: "greet-btn",
                                title: "Say hello →",
                                style: .primary,
                                actionRoute: "/actions/greet"
                            ))
                        ]
                    ))
                ])
            }

            // MARK: - Server Actions

            private struct GreetInput: Content { let value: String? }

            @Sendable
            func greet(_ req: Request) async throws -> PagePayload {
                let greeting = (try? req.content.decode(GreetInput.self))?.value ?? "stranger"
                return PagePayload(title: "Greeting", tree: [
                    .vstack(VStackSpec(
                        id: "root",
                        alignment: .center,
                        spacing: 16,
                        padding: EdgePadding(top: 40, leading: 24, bottom: 40, trailing: 24),
                        children: [
                            .text(TextSpec(
                                id: "hello",
                                content: "Hello, \\(greeting)! 🎉",
                                size: .title,
                                weight: .semibold,
                                alignment: .center
                            ))
                        ]
                    ))
                ])
            }
        }
        """
    }

    static let serverUserSchema = """
    //  AppModels.swift — \\ Add your app-specific Fluent models here.
    //
    //  The base UserSchema is provided by SwiftNextServerKit and is already
    //  available for import. This file is a placeholder for your own models.
    //
    //  Example:
    //
    //  import Fluent
    //  import Vapor
    //
    //  public final class Post: Model, Content, @unchecked Sendable {
    //      public static let schema = "posts"
    //      @ID(key: .id)         public var id:    UUID?
    //      @Field(key: "title")  public var title: String
    //      @Field(key: "body")   public var body:  String
    //      public init() {}
    //      public init(id: UUID? = nil, title: String, body: String) {
    //          self.id = id; self.title = title; self.body = body
    //      }
    //  }
    """

    static let serverCreateUser = """
    //  CreateUser.swift — Example Fluent migration
    //
    //  NOTE: The SwiftNext framework already creates the `users` table.
    //  This file is a reference example for adding your own custom migrations.
    //  Rename it (e.g. CreatePost.swift) and register it in MigrationsRegistry.swift.
    //
    import Fluent

    // Example — rename and customise for your own tables:
    //
    // public struct CreatePost: AsyncMigration {
    //     public init() {}
    //
    //     public func prepare(on database: Database) async throws {
    //         try await database.schema("posts")
    //             .id()
    //             .field("title", .string, .required)
    //             .field("body",  .string, .required)
    //             .field("created_at", .datetime)
    //             .create()
    //     }
    //
    //     public func revert(on database: Database) async throws {
    //         try await database.schema("posts").delete()
    //     }
    // }
    """

    static func serverMigrationsRegistry(name: String) -> String {
        """
        //  MigrationsRegistry.swift — \(name)
        //
        //  Register YOUR app-specific Fluent migrations here.
        //  The SwiftNext framework already handles the base `users` table.
        //
        //  Example:
        //    public static func register(on app: Application) {
        //        app.migrations.add(CreatePost())
        //    }
        //
        import Vapor

        public enum MigrationsRegistry {
            public static func register(on app: Application) {
                // Add your app-level migrations here
            }
        }
        """
    }

    static func serverRouteRegistry(name: String) -> String {
        """
        //  RouteRegistry.swift — \(name)
        import Vapor
        import SwiftNextServerKit

        public enum RouteRegistry {
            public static func register(on app: Application) throws {
                try app.register(collection: HealthController())
                try app.register(collection: PageController())
            }
        }
        """
    }

    static func serverMain(name: String) -> String {
        """
        //  main.swift — \(name)Server (thin CLI executable)
        //
        //  All server logic lives in \(name)ServerKit.
        //  Run standalone:  swift run \(name)Server --auto-migrate
        //
        import \(name)ServerKit
        import Vapor

        var env = try Environment.detect()
        try LoggingSystem.bootstrap(from: &env)
        let app = try await Application.make(env)
        do {
            try configure(app)
            try await app.execute()
        } catch {
            app.logger.report(error: error)
            try? await app.asyncShutdown()
            throw error
        }
        try await app.asyncShutdown()
        """
    }

    // MARK: - Xcode Workspace

    /// Generates a .xcworkspace so Xcode can see both the generated project
    /// and the local swift-next dependency in a single window, which enables
    /// proper scheme generation and the Run button for executable targets.
    static func xcworkspace(name: String) -> String {
        """
        <?xml version="1.0" encoding="UTF-8"?>
        <Workspace version="1.0">
           <FileRef location="group:Package.swift"/>
           <FileRef location="group:../swift-next/Package.swift"/>
        </Workspace>
        """
    }

    // MARK: - Xcode Schemes

    /// Pre-generated scheme for the macOS SwiftUI client app.
    /// Placed in .swiftpm/xcode/xcshareddata/xcschemes/ so Xcode shows it
    /// immediately without needing to auto-discover targets.
    static func xcschemeApp(name: String) -> String {
        """
        <?xml version="1.0" encoding="UTF-8"?>
        <Scheme LastUpgradeVersion="1500" version="1.7">
           <BuildAction parallelizeBuildables="YES" buildImplicitDependencies="YES">
              <BuildActionEntries>
                 <BuildActionEntry buildForRunning="YES" buildForTesting="YES" buildForProfiling="YES" buildForArchiving="YES" buildForAnalyzing="YES">
                    <BuildableReference
                       BuildableIdentifier = "primary"
                       BlueprintIdentifier = "\(name)App"
                       BuildableName = "\(name)App"
                       BlueprintName = "\(name)App"
                       ReferencedContainer = "container:Package.swift">
                    </BuildableReference>
                 </BuildActionEntry>
              </BuildActionEntries>
           </BuildAction>
           <TestAction buildConfiguration="Debug"
              selectedDebuggerIdentifier="Xcode.DebuggerFoundation.Debugger.LLDB"
              selectedLauncherIdentifier="Xcode.DebuggerFoundation.Launcher.LLDB"
              shouldUseLaunchSchemeArgsEnv="YES">
              <Testables/>
           </TestAction>
           <LaunchAction buildConfiguration="Debug"
              selectedDebuggerIdentifier="Xcode.DebuggerFoundation.Debugger.LLDB"
              selectedLauncherIdentifier="Xcode.DebuggerFoundation.Launcher.LLDB"
              launchStyle="0"
              useCustomWorkingDirectory="NO"
              ignoresPersistentStateOnLaunch="NO"
              debugDocumentVersioning="YES"
              debugServiceExtension="internal"
              allowLocationSimulation="YES">
              <BuildableProductRunnable runnableDebuggingMode="0">
                 <BuildableReference
                    BuildableIdentifier = "primary"
                    BlueprintIdentifier = "\(name)App"
                    BuildableName = "\(name)App"
                    BlueprintName = "\(name)App"
                    ReferencedContainer = "container:Package.swift">
                 </BuildableReference>
              </BuildableProductRunnable>
           </LaunchAction>
           <ProfileAction buildConfiguration="Release" shouldUseLaunchSchemeArgsEnv="YES">
              <BuildableProductRunnable runnableDebuggingMode="0">
                 <BuildableReference
                    BuildableIdentifier = "primary"
                    BlueprintIdentifier = "\(name)App"
                    BuildableName = "\(name)App"
                    BlueprintName = "\(name)App"
                    ReferencedContainer = "container:Package.swift">
                 </BuildableReference>
              </BuildableProductRunnable>
           </ProfileAction>
           <AnalyzeAction buildConfiguration="Debug"/>
           <ArchiveAction buildConfiguration="Release" revealArchiveInOrganizer="YES"/>
        </Scheme>
        """
    }

    /// Pre-generated scheme for the Vapor backend server.
    static func xcschemeServer(name: String) -> String {
        """
        <?xml version="1.0" encoding="UTF-8"?>
        <Scheme LastUpgradeVersion="1500" version="1.7">
           <BuildAction parallelizeBuildables="YES" buildImplicitDependencies="YES">
              <BuildActionEntries>
                 <BuildActionEntry buildForRunning="YES" buildForTesting="YES" buildForProfiling="YES" buildForArchiving="YES" buildForAnalyzing="YES">
                    <BuildableReference
                       BuildableIdentifier = "primary"
                       BlueprintIdentifier = "\(name)Server"
                       BuildableName = "\(name)Server"
                       BlueprintName = "\(name)Server"
                       ReferencedContainer = "container:Package.swift">
                    </BuildableReference>
                 </BuildActionEntry>
              </BuildActionEntries>
           </BuildAction>
           <TestAction buildConfiguration="Debug"
              selectedDebuggerIdentifier="Xcode.DebuggerFoundation.Debugger.LLDB"
              selectedLauncherIdentifier="Xcode.DebuggerFoundation.Launcher.LLDB"
              shouldUseLaunchSchemeArgsEnv="YES">
              <Testables/>
           </TestAction>
           <LaunchAction buildConfiguration="Debug"
              selectedDebuggerIdentifier="Xcode.DebuggerFoundation.Debugger.LLDB"
              selectedLauncherIdentifier="Xcode.DebuggerFoundation.Launcher.LLDB"
              launchStyle="0"
              useCustomWorkingDirectory="NO"
              ignoresPersistentStateOnLaunch="NO"
              debugDocumentVersioning="YES"
              debugServiceExtension="internal"
              allowLocationSimulation="YES">
              <CommandLineArguments>
                 <CommandLineArgument argument="--auto-migrate" isEnabled="YES"/>
              </CommandLineArguments>
              <BuildableProductRunnable runnableDebuggingMode="0">
                 <BuildableReference
                    BuildableIdentifier = "primary"
                    BlueprintIdentifier = "\(name)Server"
                    BuildableName = "\(name)Server"
                    BlueprintName = "\(name)Server"
                    ReferencedContainer = "container:Package.swift">
                 </BuildableReference>
              </BuildableProductRunnable>
           </LaunchAction>
           <ProfileAction buildConfiguration="Release" shouldUseLaunchSchemeArgsEnv="YES">
              <BuildableProductRunnable runnableDebuggingMode="0">
                 <BuildableReference
                    BuildableIdentifier = "primary"
                    BlueprintIdentifier = "\(name)Server"
                    BuildableName = "\(name)Server"
                    BlueprintName = "\(name)Server"
                    ReferencedContainer = "container:Package.swift">
                 </BuildableReference>
              </BuildableProductRunnable>
           </ProfileAction>
           <AnalyzeAction buildConfiguration="Debug"/>
           <ArchiveAction buildConfiguration="Release" revealArchiveInOrganizer="YES"/>
        </Scheme>
        """
    }

    // MARK: - App sources

    static func appMain(name: String) -> String {
        """
        //  \(name)App.swift
        //
        //  ONE-CLICK RUN in Xcode:
        //    1. File → Open → Package.swift
        //    2. Scheme picker: "\(name)App" → "My Mac" → ▶ Run
        //
        //  SPM executables have no Info.plist, so we must manually register
        //  as a regular foreground app (Dock icon, keyboard focus, text input).
        //
        import SwiftUI
        import AppKit
        import SwiftNextClient

        @main
        struct \(name)App: App {

            @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

            init() {
                InProcessServer.shared.start()
            }

            var body: some Scene {
                WindowGroup("\(name)") {
                    ContentRootView()
                }
                .defaultSize(width: 960, height: 700)
                .commands {
                    CommandGroup(replacing: .appTermination) {
                        Button("Quit \(name)") {
                            InProcessServer.shared.stop()
                            NSApp.terminate(nil)
                        }
                        .keyboardShortcut("q")
                    }
                }
            }
        }

        // Makes the process a proper foreground app:
        //  • Dock icon appears
        //  • App activates and takes keyboard focus
        //  • Text fields and button clicks work
        final class AppDelegate: NSObject, NSApplicationDelegate {
            func applicationDidFinishLaunching(_ notification: Notification) {
                NSApp.setActivationPolicy(.regular)
                NSApp.activate(ignoringOtherApps: true)
            }

            func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
                InProcessServer.shared.stop()
                return true
            }
        }

        struct ContentRootView: View {
            var body: some View {
                SwiftNextPageView(path: "/pages/home")
            }
        }
        """
    }

    /// Subprocess-based server manager with FSEvents hot-reload.
    /// When any .swift file in Sources/ changes: kills the old process,
    /// respawns `swift run <name>Server --auto-migrate` (which recompiles),
    /// then posts .swiftNextServerReloaded so the UI reconnects.
    static func appInProcessServer(name: String) -> String {
        """
        //  InProcessServer.swift — \(name)App
        //
        //  HOT RELOAD:
        //    Edit any .swift file in Sources/ → FSEvents fires →
        //    `swift run \(name)Server` respawns (auto-recompiles) →
        //    SwiftNextPageView reconnects automatically.
        //
        import Foundation
        import CoreServices
        import SwiftNextClient   // for Notification.Name.swiftNextServerReloaded

        final class InProcessServer: @unchecked Sendable {

            static let shared = InProcessServer()
            private var serverProcess: Process?
            private var watcher: SourceWatcher?
            private let lock = NSLock()

            private let projectRoot: URL = {
                URL(fileURLWithPath: #file)
                    .deletingLastPathComponent()
                    .deletingLastPathComponent()
                    .deletingLastPathComponent()
            }()

            func start() {
                spawnServer()
                startWatcher()
            }

            func stop() {
                watcher?.stop()
                lock.lock()
                serverProcess?.terminate()
                serverProcess = nil
                lock.unlock()
            }

            private func spawnServer() {
                lock.lock()
                serverProcess?.terminate()
                serverProcess = nil
                lock.unlock()

                let p = Process()
                p.executableURL = URL(fileURLWithPath: "/usr/bin/env")
                // --build-path .build-server: separate cache from Xcode's .build/
                // so the subprocess never blocks on Xcode's SPM lock.
                p.arguments = ["swift", "run", "--build-path", ".build-server",
                                "\(name)Server", "--auto-migrate"]
                p.currentDirectoryURL = projectRoot

                let out = Pipe(); let err = Pipe()
                p.standardOutput = out; p.standardError = err
                out.fileHandleForReading.readabilityHandler = { fh in
                    let d = fh.availableData; if !d.isEmpty { FileHandle.standardOutput.write(d) }
                }
                err.fileHandleForReading.readabilityHandler = { fh in
                    let d = fh.availableData; if !d.isEmpty { FileHandle.standardError.write(d) }
                }
                try? p.run()
                lock.lock(); serverProcess = p; lock.unlock()
                fputs("[SwiftNext] 🚀 Server spawned (pid \\(p.processIdentifier))\\n", stderr)
            }

            private func startWatcher() {
                let path = projectRoot.appendingPathComponent("Sources").path
                watcher = SourceWatcher(path: path) { [weak self] in
                    fputs("[SwiftNext] 🔄 Source changed — hot reloading…\\n", stderr)
                    self?.spawnServer()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        NotificationCenter.default.post(
                            name: .swiftNextServerReloaded, object: nil)
                    }
                }
                watcher?.start()
                fputs("[SwiftNext] 👀 Watching \\(path) for .swift changes\\n", stderr)
            }
        }

        final class SourceWatcher {
            private let path: String
            private let handler: () -> Void
            private var stream: FSEventStreamRef?
            private var debounce: DispatchWorkItem?
            private let queue = DispatchQueue(label: "swiftnext.watcher", qos: .utility)

            init(path: String, handler: @escaping () -> Void) {
                self.path = path; self.handler = handler
            }

            func start() {
                let paths = [path] as CFArray
                var ctx = FSEventStreamContext(version: 0,
                    info: Unmanaged.passRetained(self).toOpaque(),
                    retain: nil, release: nil, copyDescription: nil)
                let cb: FSEventStreamCallback = { _, info, count, raw, _, _ in
                    guard let info else { return }
                    let me = Unmanaged<SourceWatcher>.fromOpaque(info).takeUnretainedValue()
                    let arr = unsafeBitCast(raw, to: CFArray.self)
                    for i in 0..<count {
                        if let ptr = CFArrayGetValueAtIndex(arr, i) {
                            let p = Unmanaged<CFString>.fromOpaque(ptr).takeUnretainedValue() as String
                            if p.hasSuffix(".swift") { me.schedule(); return }
                        }
                    }
                }
                stream = FSEventStreamCreate(kCFAllocatorDefault, cb, &ctx, paths,
                    FSEventStreamEventId(kFSEventStreamEventIdSinceNow), 0.3,
                    FSEventStreamCreateFlags(
                        kFSEventStreamCreateFlagFileEvents | kFSEventStreamCreateFlagUseCFTypes))
                guard let s = stream else { return }
                FSEventStreamSetDispatchQueue(s, queue)
                FSEventStreamStart(s)
            }

            func stop() {
                guard let s = stream else { return }
                FSEventStreamStop(s); FSEventStreamInvalidate(s); FSEventStreamRelease(s)
                stream = nil
            }

            private func schedule() {
                debounce?.cancel()
                let w = DispatchWorkItem { [weak self] in self?.handler() }
                debounce = w
                queue.asyncAfter(deadline: .now() + 0.8, execute: w)
            }
        }
        """
    }

    // MARK: - Tests

    static func testsRoutes(name: String) -> String {
        let appName = name
        return """
        //  RouteTests.swift — BackendTests
        //
        //  These tests use SwiftNextServerKit directly (no XCTVapor needed).
        //  To add full Vapor integration tests, add the `vapor` package
        //  to Package.swift and import XCTVapor here.
        //
        import XCTest
        import SharedModels
        import SwiftNextServerKit

        final class RouteTests: XCTestCase {

            func testPagePayloadEncoding() throws {
                let payload = PagePayload(title: "\(appName)", tree: [
                    .text(TextSpec(id: "t", content: "Hello"))
                ])
                let data    = try JSONEncoder().encode(payload)
                let decoded = try JSONDecoder().decode(PagePayload.self, from: data)
                XCTAssertEqual(decoded.title, "\(appName)")
                XCTAssertFalse(decoded.tree.isEmpty)
            }

            func testAllComponentCasesRoundTrip() throws {
                let cases: [SwiftNextComponent] = [
                    .vstack(VStackSpec(id: "v", children: [])),
                    .hstack(HStackSpec(id: "h", children: [])),
                    .text(TextSpec(id: "t", content: "hello")),
                    .button(ButtonSpec(id: "b", title: "Go", actionRoute: "/actions/test"))
                ]
                for component in cases {
                    let data    = try JSONEncoder().encode(component)
                    let decoded = try JSONDecoder().decode(SwiftNextComponent.self, from: data)
                    XCTAssertEqual(component, decoded)
                }
            }
        }
        """
    }

    static let testsRenderer = """
    //  RendererTests.swift — UIComponentsTests
    import XCTest
    import SharedModels

    final class RendererTests: XCTestCase {

        func testRoundTrip() throws {
            let original = PagePayload(title: "T", tree: [
                .text(TextSpec(id: "t", content: "Hi"))
            ])
            let data    = try JSONEncoder().encode(original)
            let decoded = try JSONDecoder().decode(PagePayload.self, from: data)
            XCTAssertEqual(decoded, original)
        }

        func testEveryComponentCase() throws {
            let cases: [SwiftNextComponent] = [
                .vstack(VStackSpec(id: "v", children: [])),
                .hstack(HStackSpec(id: "h", children: [])),
                .zstack(ZStackSpec(id: "z", children: [])),
                .spacer(SpacerSpec(id: "s")),
                .divider(DividerSpec(id: "d")),
                .text(TextSpec(id: "t", content: "x")),
                .textField(TextFieldSpec(id: "tf")),
                .image(ImageSpec(id: "i", url: "https://x.com/y.png")),
                .button(ButtonSpec(id: "b", title: "Go"))
            ]
            for c in cases {
                let data = try JSONEncoder().encode(c)
                let back = try JSONDecoder().decode(SwiftNextComponent.self, from: data)
                XCTAssertEqual(c, back)
            }
        }
    }
    """

    // MARK: - README

    static func readme(name: String) -> String {
        return """
        # \(name)

        A SwiftNext full-stack app. Both server and client are written in Swift.

        ## Architecture

        ```
        \(name)ServerKit  (library)
             ├── \(name)App     — SwiftUI app, runs Vapor IN-PROCESS via InProcessServer
             └── \(name)Server  — thin CLI executable (for terminal / CI)
        ```

        ## One-click Run (Xcode)

        1. `open Package.swift` in Xcode  *(File → Open → Package.swift)*
        2. Scheme picker → **`\(name)App`** → destination **`My Mac`**
        3. Press **▶ Run**
           - Xcode builds `\(name)ServerKit` + `\(name)App` together
           - `InProcessServer` starts Vapor on a background thread
           - SwiftUI window opens connected to `http://localhost:8080`

        ## Terminal

        ```bash
        make run-all       # server + client (concurrent)
        make run-backend   # Vapor API only
        make run-frontend  # macOS SwiftUI client only
        make test          # all tests
        ```

        ## Add a page

        Edit `Sources/\(name)ServerKit/Controllers/PageController.swift` — add a route in
        `boot(routes:)` and return a `PagePayload` tree of `SwiftNextComponent` values.
        """
    }
}
