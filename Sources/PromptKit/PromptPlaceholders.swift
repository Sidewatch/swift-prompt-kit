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

        var out = template
        func sub(_ token: String, _ value: String?) {
            out = out.replacingOccurrences(of: "{\(token)}", with: value ?? "", options: .caseInsensitive)
        }
        sub("date", date); sub("today", date)
        sub("time", time)
        sub("datetime", "\(date) \(time)")
        sub("file", context.fileRelative)
        sub("filename", context.fileName)
        sub("selection", context.selection)
        sub("line", context.line.map(String.init))
        sub("branch", context.branch)
        sub("repo", context.repo)
        sub("clipboard", clipboard)
        return out
    }
}
