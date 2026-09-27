//
//  Prompt.swift
//  PromptKit
//
//  A titled snippet — either a prompt (text pasted to an agent) or a command (a CLI line run in
//  the terminal).
//
//  Created by David Sherlock on 7/19/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import Foundation

/// A titled snippet — either a prompt (text pasted to an agent) or a command (a CLI
/// line run in the terminal). The value the send, insert and placeholder paths take.
public struct Prompt: Codable, Equatable {
    /// The name shown in a list.
    public var title: String
    /// The text sent, inserted or copied, before placeholder expansion.
    public var body: String

    /// A snippet with a title and body.
    public init(title: String, body: String) {
        self.title = title
        self.body = body
    }
}
