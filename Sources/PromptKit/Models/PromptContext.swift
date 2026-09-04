//
//  PromptContext.swift
//  PromptKit
//

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
