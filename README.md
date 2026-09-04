# Swift Prompt Kit

Reusable, file-backed prompt/snippet primitives for editor and agent tooling — a titled-snippet value type, a Markdown-frontmatter prompt file (parse / serialize / folder read+create), and a pure `{…}` placeholder expander. Foundation only, zero dependencies, fully testable (no AppKit).

## Features

- ✂️ **Titled snippets** — `Prompt { title, body }`: the `Codable`/`Equatable` atom a Prompts or Commands list stores
- 📄 **File-backed prompts** — `PromptFile`: one `.md` file = one prompt. Optional YAML frontmatter (`title` / `description`, the `SKILL.md` convention) with a sensible no-frontmatter fallback (prettified filename → title, first non-empty line → description). `parse` / `serialized` round-trip; `read(_:)` lists a folder sorted by title; `create(in:base:content:)` writes a uniquely-named file; `projectDirectory(root:)` is the committed `<root>/.sidewatch/prompts` convention
- 🔤 **Placeholder expansion** — `PromptPlaceholders.expand(_:context:clipboard:now:)` fills `{file}`, `{filename}`, `{selection}`, `{line}`, `{branch}`, `{repo}`, `{date}`/`{today}`, `{time}`, `{datetime}`, `{clipboard}` against live editor/repo context. **Pure**: the clipboard string and the reference `Date` are injected by the caller, so expansion is deterministic and needs no AppKit. Unknown `{…}` tokens are left untouched
- 🪶 **Zero dependencies** — Foundation only
- 🧪 **Tested** — frontmatter parse edge-cases (quotes, colons-in-values, unknown keys, fallbacks), serialize round-trip, slug/dedup, folder create+read, and every placeholder token

## Requirements

- macOS 14+
- Swift 6.2+ (Swift 6 language mode)

## Installation

### Swift Package Manager

```swift
dependencies: [
    .package(url: "https://github.com/Sidewatch/swift-prompt-kit.git", from: "1.0.0")
]
```

## Usage

```swift
import PromptKit

// Parse a file-backed prompt.
let pf = PromptFile.load(url)                 // frontmatter + body, or nil if unreadable
print(pf?.title ?? "", pf?.body ?? "")

// List a project's committed prompts.
let prompts = PromptFile.read(PromptFile.projectDirectory(root: repoRoot))

// Expand placeholders at send time (caller supplies clipboard + now).
let ctx = PromptContext(fileRelative: "src/main.swift", line: 42, branch: "feature", repo: "myrepo")
let filled = PromptPlaceholders.expand(
    "Review {file} line {line} on {branch}",
    context: ctx,
    clipboard: NSPasteboard.general.string(forType: .string))
```

## Notes

- Persistence of a user's snippet list (e.g. `UserDefaults`) and the global prompts folder are intentionally **not** here — those are app-configuration concerns. This package is the pure model + parsing layer.
- `PromptPlaceholders.legend` exposes the `(token, description)` pairs for rendering a placeholder hint in a UI.

## For agents

Read `CONTRIBUTING.md` first: the folder layout and the PR rules. `swift test` is the whole
check, and a new test must fail before the change it covers. `CLAUDE.md` / `AGENTS.md` carry a
module map.

