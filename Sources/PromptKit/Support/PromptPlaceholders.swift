//
//  PromptPlaceholders.swift
//  PromptKit
//
//  Expands dynamic placeholders in a prompt/command body when it's used, so a saved snippet
//  like `Review {file} for bugs (branch {branch}, {today})` fills itself in against the live
//  editor + repo.
//
//  Created by David Sherlock on 7/19/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import Foundation

/// Expands placeholders in a prompt or command body when it is used, so a saved snippet like
/// `Review {file} for bugs (branch {branch}, {today})` fills itself in against the live editor
/// and repo. Known tokens are replaced (empty when unavailable); other braces are left alone.
/// Pure Foundation: the caller injects the clipboard string and "now", so expansion is
/// deterministic and testable.
public enum PromptPlaceholders {

    /// The tokens shown in an editor's placeholder legend.
    public static let legend: [(token: String, desc: String)] = [
        ("{file}",      String(localized: "active file, repo-relative", bundle: .module, comment: "Prompt placeholder legend: what the {…} token beside it expands to.")),
        ("{filename}",  String(localized: "active file name", bundle: .module, comment: "Prompt placeholder legend: what the {…} token beside it expands to.")),
        ("{selection}", String(localized: "selected text in the editor", bundle: .module, comment: "Prompt placeholder legend: what the {…} token beside it expands to.")),
        ("{line}",      String(localized: "caret line number", bundle: .module, comment: "Prompt placeholder legend: what the {…} token beside it expands to.")),
        ("{branch}",    String(localized: "current git branch", bundle: .module, comment: "Prompt placeholder legend: what the {…} token beside it expands to.")),
        ("{repo}",      String(localized: "project / repo name", bundle: .module, comment: "Prompt placeholder legend: what the {…} token beside it expands to.")),
        ("{date}",      String(localized: "today (YYYY-MM-DD)", bundle: .module, comment: "Prompt placeholder legend: what the {…} token beside it expands to.")),
        ("{time}",      String(localized: "now (HH:MM)", bundle: .module, comment: "Prompt placeholder legend: what the {…} token beside it expands to.")),
        ("{datetime}",  String(localized: "date + time", bundle: .module, comment: "Prompt placeholder legend: what the {…} token beside it expands to.")),
        ("{clipboard}", String(localized: "clipboard contents", bundle: .module, comment: "Prompt placeholder legend: what the {…} token beside it expands to.")),
    ]

    /// Replaces the known placeholders in `template`; unknown `{…}` tokens are left untouched.
    /// A single pass over the template: substituted values are never re-scanned, so a
    /// selection or clipboard holding a literal `{…}` survives verbatim.
    /// - Parameters:
    ///   - clipboard: the current clipboard string, or nil.
    ///   - now: the reference time for date/time tokens.
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
