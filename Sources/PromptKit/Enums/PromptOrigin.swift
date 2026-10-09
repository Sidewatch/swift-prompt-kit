//
//  PromptOrigin.swift
//  PromptKit
//
//  Whose prompt a file is: the person's own, or the project's.
//
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

/// Where a prompt file came from, which decides how much it is trusted when it is used.
///
/// A global prompt is the person's own text in their own library: a command among them runs on
/// one click and may read the clipboard and the selection. A project prompt arrived with the
/// checkout — anyone who committed to the repository wrote it — so a host pastes it for the
/// person to read before it runs, and never fills it from the clipboard or the selection.
public enum PromptOrigin: String, Equatable, Sendable {
    /// The person's own library.
    case global
    /// A project's committed `.sidewatch/prompts`.
    case project
}
