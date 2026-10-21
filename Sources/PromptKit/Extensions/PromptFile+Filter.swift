//
//  PromptFile+Filter.swift
//  PromptKit
//
//  Whether a prompt passes a library's search text and category scope.
//
//  Created by David Sherlock on 10/21/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import Foundation

public extension PromptFile {
    /// Whether the prompt passes a library filter: its category is `category` (any case; nil = every
    /// category), and `query` — trimmed, any case; empty = everything — is in its title, description,
    /// body or category.
    func matches(query: String, category scope: String?) -> Bool {
        if let scope, category.caseInsensitiveCompare(scope) != .orderedSame { return false }
        let q = query.trimmingCharacters(in: .whitespaces).lowercased()
        return q.isEmpty || [title, description, body, category].contains { $0.lowercased().contains(q) }
    }
}
