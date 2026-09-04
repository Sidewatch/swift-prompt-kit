# Swift Prompt Kit

Reusable, file-backed prompt/snippet primitives for editor and agent tooling — a titled-snippet value type, a Markdown-frontmatter prompt file (parse / serialize / folder read+create), and a pure `{…}` placeholder expander. Foundation only, zero dependencies, fully testable (no AppKit).

- Module `PromptKit` in `Sources/PromptKit`; tests in `Tests`; `swift test` is the whole check.
- Swift 6 language mode, tools 6.0, macOS 14+, no dependencies unless the README says so.
- Part of the Sidewatch package family; every package follows the same layout and PR rules.

## Module map

- `Core/` — the engine: PromptFile
- `Models/` — value types — the shape of a thing, nothing else: Prompt
- `Support/` — pure helpers: parsing, escaping, validation: PromptPlaceholders

## Rules

@CONTRIBUTING.md
