import Foundation

/// A file-backed prompt — one `.md` file, one prompt. Optional YAML frontmatter carries
/// the title + description (the `SKILL.md` convention), so an agent can author these and
/// they show up in a Prompts list; the body follows. Editing one is just editing the file
/// in a tab, and a save is a normal disk write — no special store round-trip.
///
/// Two folders typically feed a picker: a user-global one and a per-project
/// `.sidewatch/prompts` (`projectDirectory(root:)`). Both read/write identically.
public struct PromptFile: Equatable {
    public var title: String
    public var description: String
    public var body: String
    public let url: URL
    /// `command: true` in the frontmatter — the prompt is a CLI line that should be
    /// *run* (submitted) when sent to the terminal, not pasted unsubmitted. This is how
    /// the old separate "Commands" list folds into one unified Prompts library.
    public var isCommand: Bool

    public init(title: String, description: String, body: String, url: URL, isCommand: Bool = false) {
        self.title = title
        self.description = description
        self.body = body
        self.url = url
        self.isCommand = isCommand
    }

    /// Bridges to the snippet type the send / insert / placeholder paths already take.
    public var prompt: Prompt { Prompt(title: title, body: body) }

    // MARK: - Read

    /// Parses a prompt file. Frontmatter `title`/`description` win; without frontmatter
    /// the title falls back to the (prettified) filename and the description to the first
    /// non-empty line — so a plain `.md` still works.
    public static func load(_ url: URL) -> PromptFile? {
        guard let raw = try? String(contentsOf: url, encoding: .utf8) else { return nil }
        return parse(raw, url: url)
    }

    /// The pure parse behind ``load(_:)`` — frontmatter + body from raw text. Exposed for
    /// testing without touching disk.
    public static func parse(_ raw: String, url: URL) -> PromptFile {
        var title = "", description = "", body = raw
        var isCommand = false

        if raw.hasPrefix("---") {
            let lines = raw.components(separatedBy: "\n")
            if let close = lines.dropFirst().firstIndex(where: { $0.trimmingCharacters(in: .whitespaces) == "---" }) {
                for line in lines[1..<close] {
                    let parts = line.split(separator: ":", maxSplits: 1).map { $0.trimmingCharacters(in: .whitespaces) }
                    guard parts.count == 2 else { continue }
                    let value = unquote(parts[1])
                    switch parts[0].lowercased() {
                    case "title":       title = value
                    case "description": description = value
                    case "command":     isCommand = (value.lowercased() == "true")
                    default:            break
                    }
                }
                body = lines[(close + 1)...].joined(separator: "\n").trimmingCharacters(in: .newlines)
            }
        }

        if title.isEmpty { title = prettifiedName(url) }
        if description.isEmpty {
            description = body.components(separatedBy: "\n")
                .first(where: { !$0.trimmingCharacters(in: .whitespaces).isEmpty }) ?? ""
        }
        return PromptFile(title: title, description: description, body: body, url: url, isCommand: isCommand)
    }

    private static func unquote(_ s: String) -> String {
        var t = s
        for q in ["\"", "'"] where t.hasPrefix(q) && t.hasSuffix(q) && t.count >= 2 {
            t = String(t.dropFirst().dropLast())
        }
        return t
    }

    /// "api-review.md" → "api review" (title fallback when there's no frontmatter).
    private static func prettifiedName(_ url: URL) -> String {
        url.deletingPathExtension().lastPathComponent
            .replacingOccurrences(of: "-", with: " ")
            .replacingOccurrences(of: "_", with: " ")
    }

    // MARK: - Write

    /// Serializes to `title`/`description` frontmatter + body — the on-disk form a new
    /// prompt or an edit-via-tab save round-trips through.
    public func serialized() -> String {
        var head = "---\ntitle: \(title)\n"
        if !description.isEmpty { head += "description: \(description)\n" }
        if isCommand { head += "command: true\n" }
        head += "---\n\n"
        return head + body
    }

    // MARK: - Folders

    /// A project's committed prompts folder (`<root>/.sidewatch/prompts`).
    public static func projectDirectory(root: URL) -> URL {
        root.appendingPathComponent(".sidewatch/prompts", isDirectory: true)
    }

    /// Every `.md`/`.markdown`/`.txt` prompt in `dir`, sorted by title (empty when the
    /// folder doesn't exist).
    public static func read(_ dir: URL) -> [PromptFile] {
        guard let files = try? FileManager.default.contentsOfDirectory(
            at: dir, includingPropertiesForKeys: nil) else { return [] }
        return files
            .filter { ["md", "markdown", "txt"].contains($0.pathExtension.lowercased()) }
            .compactMap(load)
            .sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
    }

    /// Writes `content` to a new uniquely-named `.md` in `dir` (creating `dir`), returning
    /// the URL. `base` seeds the filename ("Untitled Prompt" → untitled-prompt.md).
    @discardableResult
    public static func create(in dir: URL, base: String, content: String) -> URL? {
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let stem = slug(base)
        var url = dir.appendingPathComponent("\(stem).md")
        var n = 2
        while FileManager.default.fileExists(atPath: url.path) {
            url = dir.appendingPathComponent("\(stem)-\(n).md"); n += 1
        }
        guard (try? content.write(to: url, atomically: true, encoding: .utf8)) != nil else { return nil }
        return url
    }

    /// "New Prompt" → "new-prompt"; empty/punctuation-only → "prompt".
    public static func slug(_ base: String) -> String {
        let s = base.lowercased()
            .replacingOccurrences(of: " ", with: "-")
            .filter { $0.isLetter || $0.isNumber || $0 == "-" || $0 == "_" }
        return s.isEmpty ? "prompt" : s
    }
}
