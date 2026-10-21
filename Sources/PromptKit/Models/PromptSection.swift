//
//  PromptSection.swift
//  PromptKit
//
//  One section of a prompt library list.
//
//  Created by David Sherlock on 10/21/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import Foundation

/// One section of a prompt library list: what it holds, whether it is labelled, and its prompts.
public struct PromptSection: Equatable {
    /// What the section holds.
    public let kind: PromptSectionKind
    /// Whether the list labels it with a header.
    public let showsHeader: Bool
    /// Its prompts, in the order they were given.
    public let files: [PromptFile]

    /// A section of `files` holding `kind`.
    public init(kind: PromptSectionKind, showsHeader: Bool, files: [PromptFile]) {
        self.kind = kind
        self.showsHeader = showsHeader
        self.files = files
    }
}
