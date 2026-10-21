# Swift Prompt Kit

Reusable, file-backed prompt/snippet primitives for editor and agent tooling — a titled-snippet value type, a Markdown-frontmatter prompt file (parse / serialize / folder read+create), and a pure `{…}` placeholder expander. Foundation only, zero dependencies, fully testable (no AppKit).

- Module `PromptKit` in `Sources/PromptKit`; tests in `Tests`; `swift test` is the whole check.
- Swift 6 language mode, tools 6.2, macOS 14+, no dependencies unless the README says so.
- Part of the Sidewatch package family; every package follows the same layout and PR rules.

## Module map

- `Core/` — the engine: PromptFile
- `Enums/` — PromptSectionKind (a category, or one folder's uncategorised prompts); PromptOrigin (`global`: the person's own library; `project`: a checkout's `.sidewatch/prompts` — its commands are pasted, not run, and never read the clipboard or the selection)
- `Models/` — value types — the shape of a thing, nothing else: Prompt, PromptContext, PromptSection
- `Extensions/` — PromptFile+Filter (`matches(query:category:)`: every field, trimmed, any case; the category scope any case)
- `Support/` — pure helpers: parsing, escaping, validation: PromptPlaceholders, PromptImport (`markdown` / `json`: a pasted library split into prompts; `#` headings outside fences only, CRLF-safe), PromptLibraryLayout (`orderedCategories`: a preferred order then the alphabet, the first spelling naming a category; `sections`: categories across both folders, then each folder's uncategorised prompts, labelled only when something else is listed)

## Rules

Read `CONTRIBUTING.md` for the folder layout and the pull-request rules.

@CONTRIBUTING.md

- **Auditing? Read `AUDIT.md` first** — what the last full audit checked and fixed, and the known non-issues to skip; extend it, do not redo it.
