//
//  PromptSectionKind.swift
//  PromptKit
//
//  What a section of a prompt library list holds.
//
//  Created by David Sherlock on 10/21/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import Foundation

/// What a section of a prompt library list holds: one category's prompts from any folder, or the
/// uncategorised prompts of one folder.
public enum PromptSectionKind: Equatable, Sendable {
    /// The prompts whose `category:` is this name (in the spelling seen first).
    case category(String)
    /// The person's own uncategorised prompts.
    case mine
    /// The open project's uncategorised prompts.
    case project
}
