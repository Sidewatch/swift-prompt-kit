import Foundation

/// Editor/repo context used to expand `{…}` placeholders in a snippet at the moment
/// it's sent, inserted, or copied.
public struct PromptContext {
    public var fileRelative: String?
    public var fileName: String?
    public var selection: String?
    public var line: Int?
    public var branch: String?
    public var repo: String?

    public init(fileRelative: String? = nil, fileName: String? = nil, selection: String? = nil,
                line: Int? = nil, branch: String? = nil, repo: String? = nil) {
        self.fileRelative = fileRelative
        self.fileName = fileName
        self.selection = selection
        self.line = line
        self.branch = branch
        self.repo = repo
    }
}

/// Expands dynamic placeholders in a prompt/command body when it's used, so a saved
/// snippet like `Review {file} for bugs (branch {branch}, {today})` fills itself in
/// against the live editor + repo. Known tokens are replaced (empty when the value
/// isn't available); anything else in braces is left untouched.
///
/// Pure Foundation: the clipboard value and the "now" timestamp are injected by the
/// caller (the app passes `NSPasteboard.general.string(forType:)` and `Date()`), so
/// expansion is deterministic and testable with no AppKit dependency.
public enum PromptPlaceholders {

    /// The tokens shown in an editor's placeholder legend.
    public static let legend: [(token: String, desc: String)] = [
        ("{file}",      "active file, repo-relative"),
        ("{filename}",  "active file name"),
        ("{selection}", "selected text in the editor"),
        ("{line}",      "caret line number"),
        ("{branch}",    "current git branch"),
        ("{repo}",      "project / repo name"),
        ("{date}",      "today (YYYY-MM-DD)"),
        ("{time}",      "now (HH:MM)"),
        ("{datetime}",  "date + time"),
        ("{clipboard}", "clipboard contents"),
    ]

    /// Replace the known placeholders in `template` using `context`, `clipboard`, and
    /// `now`. Unknown `{…}` tokens are left untouched.
    ///
    /// Expansion is a single pass over the template only — substituted values are never
    /// re-scanned, so a selection/clipboard/path containing a literal `{…}` token (real
    /// code full of brace template strings) survives verbatim instead of being expanded.
    ///
    /// - Parameters:
    ///   - clipboard: the current clipboard string, or nil (the app supplies
    ///     `NSPasteboard.general.string(forType: .string)`).
    ///   - now: the reference time for date/time tokens; defaults to `Date()`.
    public static func expand(_ template: String, context: PromptContext,
                              clipboard: String? = nil, now: Date = Date()) -> String {
        guard template.contains("{") else { return template }
        let df = DateFormatter()
        df.locale = Locale(identifier: "en_US_POSIX")
        df.dateFormat = "yyyy-MM-dd"; let date = df.string(from: now)
        df.dateFormat = "HH:mm";      let time = df.string(from: now)

        let values: [String: String?] = [
            "date": date, "today": date,
            "time": time,
            "datetime": "\(date) \(time)",
            "file": context.fileRelative,
            "filename": context.fileName,
            "selection": context.selection,
            "line": context.line.map(String.init),
            "branch": context.branch,
            "repo": context.repo,
            "clipboard": clipboard,
        ]

        var out = ""
        var i = template.startIndex
        while i < template.endIndex {
            guard let open = template[i...].firstIndex(of: "{") else {
                out += template[i...]
                break
            }
            out += template[i..<open]
            // The token name runs to the first `}` but must not cross another `{`.
            var j = template.index(after: open)
            while j < template.endIndex, template[j] != "}", template[j] != "{" {
                j = template.index(after: j)
            }
            if j < template.endIndex, template[j] == "}" {
                let name = template[template.index(after: open)..<j].lowercased()
                if let value = values[name] {
                    out += value ?? ""
                } else {
                    out += template[open...j]
                }
                i = template.index(after: j)
            } else {
                out += String(template[open])
                i = template.index(after: open)
            }
        }
        return out
    }
}
