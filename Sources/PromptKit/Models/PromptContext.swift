//
//  PromptContext.swift
//  PromptKit
//
//  Editor/repo context used to expand `{…}` placeholders in a snippet at the moment it's sent,
//  inserted, or copied.
//
//  Created by David Sherlock on 9/5/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import Foundation

/// Editor/repo context used to expand `{…}` placeholders in a snippet at the moment
/// it's sent, inserted, or copied.
public struct PromptContext {
    /// `{file}`: the active file's path, relative to the repo.
    public var fileRelative: String?
    /// `{filename}`: the active file's name.
    public var fileName: String?
    /// `{selection}`: the editor's selected text.
    public var selection: String?
    /// `{line}`: the caret's line number.
    public var line: Int?
    /// `{branch}`: the current git branch.
    public var branch: String?
    /// `{repo}`: the project or repo name.
    public var repo: String?

    /// A context; any value left nil expands to empty.
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
