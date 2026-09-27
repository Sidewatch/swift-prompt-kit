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
