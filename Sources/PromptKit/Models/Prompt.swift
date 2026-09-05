//
//  Prompt.swift
//  PromptKit
//
//  A titled snippet — either a prompt (text pasted to an agent) or a command (a CLI line run in
//  the terminal).
//
//  Created by David Sherlock on 7/19/26.
//

import Foundation

/// A titled snippet — either a prompt (text pasted to an agent) or a command (a CLI
/// line run in the terminal). The atom both the Prompts and Commands lists store.
public struct Prompt: Codable, Equatable {
    public var title: String
    public var body: String

    public init(title: String, body: String) {
        self.title = title
        self.body = body
    }
}
