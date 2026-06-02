# Contributing to SwiftNext

Thank you for your interest in contributing to SwiftNext! This guide covers everything you need to know — from filing a bug report to landing a new component. Please read it in full before opening a PR.

---

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Ways to Contribute](#ways-to-contribute)
- [Development Setup](#development-setup)
- [Branch Naming Conventions](#branch-naming-conventions)
- [Code Style](#code-style)
- [How to Add a New Component](#how-to-add-a-new-component)
- [How to Add a New CLI Command](#how-to-add-a-new-cli-command)
- [Testing Requirements](#testing-requirements)
- [Pull Request Guide](#pull-request-guide)
- [Commit Message Convention](#commit-message-convention)
- [Maintainers](#maintainers)
- [License](#license)

---

## Code of Conduct

SwiftNext is an open, welcoming project. All contributors are expected to:

- **Be respectful.** Critique ideas, not people.
- **Be constructive.** Feedback should help the project and the contributor improve.
- **Be inclusive.** Contributors of all backgrounds and experience levels are welcome.
- **Assume good intent.** Read charitably; ask for clarification before escalating.

Violations of these principles may result in removal from the project. If you experience or witness unacceptable behaviour, email the maintainers (see [Maintainers](#maintainers)).

---

## Ways to Contribute

### 🐛 Bug Reports

Open a GitHub issue with:
- A concise title describing the problem.
- Steps to reproduce the bug (minimal repro preferred).
- Expected vs. actual behavior.
- SwiftNext version, Xcode version, macOS/iOS version.
- Relevant stack traces or log output.

### 💡 Feature Requests

Open a GitHub issue tagged `enhancement`. Describe:
- The problem you're trying to solve.
- Your proposed solution.
- Any alternatives you've considered.

Large features may be discussed in a GitHub Discussion before an issue is filed.

### 📝 Documentation Improvements

Documentation lives in `README.md`, `DOCS.md`, and inline code comments. Fix typos, add examples, improve clarity — all PRs welcome.

### 🔧 Code Contributions

For bug fixes: open an issue first (or comment on an existing one) so work isn't duplicated.  
For new features: discuss in an issue before investing significant implementation time.  
For new components: follow the [How to Add a New Component](#how-to-add-a-new-component) checklist.

---

## Development Setup

### 1. Fork and Clone

```bash
# Fork via GitHub UI, then:
git clone https://github.com/<your-username>/swift-next.git
cd swift-next
```

### 2. Install Dependencies

SwiftNext has no external tooling beyond Xcode and Swift. All dependencies are managed by SPM and fetched automatically:

```bash
swift package resolve
```

### 3. Build

```bash
swift build
# Or build a specific product:
swift build --product swiftnext-cli
```

### 4. Run Tests (Baseline)

Before making any changes, run the full test suite and confirm it passes:

```bash
swift test --parallel
```

All tests must pass on the `main` branch at all times. If you find a failing test on `main` before you've made changes, please open an issue.

### 5. Open in Xcode

```bash
open Package.swift
```

Select any scheme and press **Cmd+B** to confirm the build.

### 6. Set Up the `.env` File

```bash
cp .env.example .env   # or create .env manually
```

The default `.env` (SQLite, port 8080) works for all development scenarios.

---

## Branch Naming Conventions

All branches must be prefixed with a category:

| Prefix | Use for |
|---|---|
| `feat/` | New features or components |
| `fix/` | Bug fixes |
| `docs/` | Documentation-only changes |
| `chore/` | Maintenance (dependency bumps, CI, build config) |
| `test/` | Test additions or corrections |
| `refactor/` | Non-breaking code restructuring |

**Examples:**

```
feat/progress-bar-component
fix/hot-reload-debounce-crash
docs/deployment-docker-guide
chore/bump-vapor-4.95
test/page-controller-pagination
refactor/network-engine-async
```

Branch names use lowercase kebab-case after the prefix. No uppercase, no spaces, no underscores.

---

## Code Style

SwiftNext follows the [Swift API Design Guidelines](https://www.swift.org/documentation/api-design-guidelines/) and the conventions described below.

### One Type Per File

Every `struct`, `class`, `enum`, `actor`, and `protocol` lives in its own `.swift` file. The file name matches the type name exactly:

```
VStackSpec.swift         → public struct VStackSpec
SwiftNextRenderer.swift  → public struct SwiftNextRenderer
RouteRegistry.swift      → public enum RouteRegistry
```

### File Header

All source files must begin with a standard header:

```swift
//
//  TypeName.swift
//  ModuleName
//
//  One-line description of this file's purpose.
//
```

### Access Control

- **`public`** — types and members that form the public API.
- **`internal`** (default, no keyword needed) — implementation details within a module.
- **`private`** or **`fileprivate`** — helpers used only within a single type or file.

Prefer the narrowest access level that satisfies the requirement.

### Naming

- Use descriptive names. Abbreviations are acceptable only when they are universally understood (e.g., `id`, `url`, `db`).
- `Spec` suffix for value types that describe a component's configuration: `TextSpec`, `ButtonSpec`.
- `Controller` suffix for Vapor `RouteCollection` types.
- `Native` prefix for SwiftUI view wrappers of server-side specs: `NativeText`, `NativeButton`.

### Async / Concurrency

- Mark Vapor handler closures `@Sendable`.
- Use `async/await` — no Combine, no callbacks in new code.
- Annotate UI-updating code with `@MainActor` or dispatch with `await MainActor.run { }`.

### Comments

Comment code that is non-obvious. Do not comment self-explanatory code. Use `// MARK: -` to organise long files into sections.

### Formatting

SwiftNext does not yet enforce a formatter automatically. Follow the surrounding file's indentation (4-space tabs, as is standard in Xcode-generated files). A future PR adding `swift-format` or `swiftlint` configuration would be welcome.

---

## How to Add a New Component

Adding a component is a deliberate, end-to-end act. Use this checklist — every item is required for the PR to be merged.

### Checklist

- [ ] **SharedModels: define the spec**
  - Create `Sources/SharedModels/Models/<Category>/<ComponentName>Spec.swift`.
  - Conform to `UIPrimitive` (provides `id` and `actionRoute`).
  - All properties must be `Codable`, `Hashable`, and `Sendable`.
  - Provide a memberwise `init` with sensible defaults.

- [ ] **SharedModels: add the enum case**
  - Add `.componentName(ComponentNameSpec)` to `SwiftNextComponent`.
  - Add the `Kind` raw value string (lowercase, snake_case for multi-word names).
  - Add the decode case in `init(from:)`.
  - Add the encode case in `encode(to:)`.
  - Add the `id` property case.
  - Add the `actionRoute` property case (return `nil` if the component is non-interactive).

- [ ] **SwiftNextClient: create the native view**
  - Create `Sources/SwiftNextClient/Components/Native<ComponentName>.swift`.
  - Wrap the spec in a SwiftUI `View` that renders the component natively.
  - Guard the file with `#if canImport(SwiftUI) && (os(iOS) || os(macOS) || ...)`.
  - Decorate with `@available(iOS 16.0, macOS 13.0, *)`.

- [ ] **SwiftNextClient: add the renderer case**
  - Add `case .componentName(let s): NativeComponentName(spec: s)` inside `SwiftNextRenderer.body`.
  - The compiler will warn about the missing case if you forget this step.

- [ ] **Tests: round-trip test in SharedModelsTests**
  - Add a test method to `ComponentRoundTripTests` that encodes and decodes the new component and asserts key property equality.

- [ ] **Tests: renderer test in UIComponentsTests**
  - Update the `testRendererAcceptsAllComponentKinds` test or add a dedicated test.

- [ ] **Documentation**
  - Add a row to the **Component Reference** table in `README.md`.
  - Add a subsection under **All 9 Components** (now 10+) in `DOCS.md` Part 3.
  - Update the component count in the elevator pitch in `README.md` if needed.

### Example PR Description for a New Component

```
feat: add ProgressBar component

Adds `ProgressBarSpec` to SharedModels and `NativeProgressBar` to
SwiftNextClient. The component renders a native SwiftUI ProgressView
driven by a server-supplied 0.0–1.0 value and an optional tint token.

Checklist:
- [x] ProgressBarSpec (SharedModels)
- [x] SwiftNextComponent enum case + Codable
- [x] NativeProgressBar (SwiftNextClient)
- [x] SwiftNextRenderer case
- [x] Round-trip test
- [x] Renderer test
- [x] README + DOCS updated
```

---

## How to Add a New CLI Command

The CLI is built with [swift-argument-parser](https://github.com/apple/swift-argument-parser).

### Steps

1. **Create a command file** in `Sources/SwiftNextCLI/Commands/`:

```swift
// Sources/SwiftNextCLI/Commands/BuildCommand.swift
import ArgumentParser

struct BuildCommand: AsyncParsableCommand {
    static var configuration = CommandConfiguration(
        commandName: "build",
        abstract: "Build the project in release mode."
    )

    @Option(name: .long, help: "Build configuration (debug|release).")
    var configuration: String = "release"

    func run() async throws {
        try ShellRunner.run("swift build -c \(configuration)")
    }
}
```

2. **Register the command** in the root command group in `SwiftNextCLI.swift`:

```swift
@main
struct SwiftNextCLI: AsyncParsableCommand {
    static var configuration = CommandConfiguration(
        subcommands: [
            InitCommand.self,
            DevCommand.self,
            TestCommand.self,
            BuildCommand.self,   // ← add here
        ]
    )
}
```

3. **Write tests** — add an integration test in `Tests/CLITests/` that invokes the command and asserts side effects (if applicable).

4. **Update documentation** — add a row to the **CLI Commands** table in `README.md` and a section in `DOCS.md`.

---

## Testing Requirements

**All pull requests must pass `swift test --parallel` with zero failures and zero skipped tests.**

Additional requirements:

| Scenario | Requirement |
|---|---|
| New component | Round-trip test + renderer test |
| New Vapor route | XCTVapor test with at least one happy-path assertion |
| Bug fix | Regression test that would have caught the bug |
| Refactor | All existing tests continue to pass, no tests deleted |
| Documentation-only PR | No test requirement |

Run the full suite before pushing:

```bash
swift test --parallel
```

If you are adding tests for a scenario that cannot be exercised without an external service (e.g., real PostgreSQL), use the `@available` annotation and a note in the PR description. We use in-memory SQLite for all CI tests.

---

## Pull Request Guide

### Before You Open a PR

- [ ] The branch is up to date with `main` (`git rebase origin/main`).
- [ ] `swift build` succeeds.
- [ ] `swift test --parallel` passes.
- [ ] Your commit messages follow the [Conventional Commits](#commit-message-convention) convention.
- [ ] You have updated documentation if the change affects the public API or user-facing behaviour.

### PR Title

Follow the same convention as commit messages:

```
feat(client): add NativeProgressBar component
fix(server): correct hot-reload debounce interval
docs: add Docker deployment guide
```

### PR Description Template

```markdown
## What this PR does

<!-- One paragraph describing the change and why it's needed. -->

## Changes

- Added `ProgressBarSpec` to `SharedModels`
- Added `NativeProgressBar` to `SwiftNextClient`
- Updated `SwiftNextRenderer` switch
- Added round-trip and renderer tests

## Testing

- `swift test --parallel` passes
- Manually verified in the example app on macOS 14 / iOS 17

## Screenshots (if UI change)

<!-- Before / After, or a screen recording -->
```

### Review Process

1. A maintainer will review within 5 business days.
2. Address all requested changes. Mark conversations as resolved when complete.
3. Maintainers may squash-merge to keep the history clean.
4. Do not force-push after a review has started — append new commits.

---

## Commit Message Convention

SwiftNext uses **[Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/)**.

### Format

```
<type>(<scope>): <short description>

[optional body]

[optional footer(s)]
```

### Types

| Type | Use for |
|---|---|
| `feat` | New feature or component |
| `fix` | Bug fix |
| `docs` | Documentation changes |
| `test` | Adding or correcting tests |
| `refactor` | Code restructuring (no behaviour change) |
| `chore` | Maintenance (deps, CI, build config) |
| `perf` | Performance improvement |
| `revert` | Reverts a previous commit |

### Scopes (optional but encouraged)

| Scope | Module |
|---|---|
| `shared` | `SharedModels` |
| `server` | `SwiftNextServerKit` |
| `client` | `SwiftNextClient` |
| `cli` | `SwiftNextCLI` |
| `docs` | README / DOCS / CONTRIBUTING |
| `ci` | GitHub Actions / CI |

### Examples

```
feat(shared): add ProgressBarSpec and enum case
fix(client): prevent hot-reload loop when server returns 503
docs: document PostgreSQL docker-compose setup
test(server): add pagination test for /pages/posts
chore: bump vapor to 4.95.0
refactor(client): extract NetworkEngine retry logic into helper
```

### Breaking Changes

If your PR changes the public API (e.g., renames a `Spec` property, changes JSON keys), add a `BREAKING CHANGE:` footer:

```
feat(shared): rename ButtonSpec.style to ButtonSpec.variant

BREAKING CHANGE: `ButtonSpec.style` is now `ButtonSpec.variant`.
Update server-side code and any stored JSON accordingly.
```

---

## Maintainers

| Name | GitHub | Role |
|---|---|---|
| Avijeet Pandey | [@avijeetpandey](https://github.com/avijeetpandey) | Project lead & core maintainer |

To reach the maintainers for security issues or code-of-conduct concerns, open a private GitHub Security Advisory or send a direct message via GitHub.

We welcome additional maintainers. If you have been a consistent contributor for several months and are interested in taking on more responsibility, please reach out.

---

## License

By contributing to SwiftNext, you agree that your contributions will be licensed under the **MIT License** — the same license that covers the project. See [LICENSE](LICENSE) for the full text.
