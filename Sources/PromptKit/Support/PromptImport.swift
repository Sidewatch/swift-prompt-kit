//
//  PromptImport.swift
//  PromptKit
//
//  Prompts read out of a Markdown file or a JSON list, for importing into a library.
//
//  Created by David Sherlock on 10/21/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import Foundation

/// Prompts read out of a file someone already has: a Markdown file of headed sections, or a JSON list of
/// prompts. Each comes back as a title and a body, empties dropped, for the host to write as prompt files.
public enum PromptImport {
    /// One prompt per heading in `markdown`: the heading (`#` to `######` then a space, or alone on its line)
    /// is the title, the lines up to the next heading the body, trimmed. Text before the first heading is
    /// not a prompt. Lines are split on every break kind (a CRLF break is one), and a `#` line inside a
    /// fenced code block (```` ``` ```` or `~~~`) is the body's, not a heading — a shell comment in a prompt
    /// must not cut it in two. `#tag` without the space is text, as Markdown reads it.
    public static func markdown(_ markdown: String) -> [(title: String, body: String)] {
        var prompts: [(title: String, body: String)] = []
        var title: String?
        var body: [Substring] = []
        var fence: Substring?
        func flush() {
            if let title, !title.isEmpty {
                let text = body.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
                if !text.isEmpty { prompts.append((title, text)) }
            }
            body = []
        }
        for line in markdown.split(omittingEmptySubsequences: false, whereSeparator: \.isNewline) {
            let lead = line.drop { $0 == " " }
            if let open = fence {
                if lead.hasPrefix(open) { fence = nil }
                body.append(line)
                continue
            }
            if lead.hasPrefix("```") || lead.hasPrefix("~~~") {
                fence = lead.prefix(3)
                body.append(line)
                continue
            }
            if let heading = heading(line) {
                flush()
                title = heading
            } else {
                body.append(line)
            }
        }
        flush()
        return prompts
    }

    /// The prompts in a JSON list of `{"title": …, "body": …}` objects (``Prompt``'s own encoding), those
    /// with an empty title or body dropped; nil when `data` is not such a list.
    public static func json(_ data: Data) -> [(title: String, body: String)]? {
        guard let decoded = try? JSONDecoder().decode([Prompt].self, from: data) else { return nil }
        return decoded.filter { !$0.title.isEmpty && !$0.body.isEmpty }.map { ($0.title, $0.body) }
    }

    /// The text of an ATX heading line (`## Title`), or nil when the line is not one: 1–6 `#`, then a
    /// space or the end of the line.
    static func heading(_ line: Substring) -> String? {
        let hashes = line.prefix { $0 == "#" }
        guard (1...6).contains(hashes.count) else { return nil }
        let rest = line.dropFirst(hashes.count)
        guard rest.isEmpty || rest.first == " " || rest.first == "\t" else { return nil }
        return rest.trimmingCharacters(in: .whitespaces)
    }
}
