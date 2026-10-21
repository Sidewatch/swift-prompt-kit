//
//  PromptLibraryLayout.swift
//  PromptKit
//
//  How a prompt library is listed: categories in order, then each folder's uncategorised prompts.
//
//  Created by David Sherlock on 10/21/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import Foundation

/// How a prompt library is listed.
public enum PromptLibraryLayout {
    /// The distinct categories of `files` in display order: those in `order` first, in its order, then
    /// any others alphabetically. Names match without regard to case, and the FIRST spelling seen
    /// names the category, so "debug" and "Debug" are one. Uncategorised files add nothing.
    public static func orderedCategories(of files: [PromptFile], preferring order: [String]) -> [String] {
        var seen: [String] = []
        for file in files where !file.category.isEmpty && !seen.contains(where: { same($0, file.category) }) {
            seen.append(file.category)
        }
        func rank(_ name: String) -> Int { order.firstIndex { same($0, name) } ?? order.count }
        return seen.sorted {
            rank($0) == rank($1) ? $0.localizedCaseInsensitiveCompare($1) == .orderedAscending : rank($0) < rank($1)
        }
    }

    /// The sections listing `global` (the person's) and `project` prompts. Categorised prompts group by
    /// category whichever folder they came from — a category is about what a prompt is FOR, and splitting
    /// one across two folders would bury half of it — in `orderedCategories` order. Uncategorised prompts
    /// follow in their folder's section, mine then the project's. A category section is always labelled; a
    /// folder section only when something else is listed to tell it from (a library of nothing but
    /// uncategorised prompts from one folder needs no headers). Empty sections are left out.
    public static func sections(global: [PromptFile], project: [PromptFile], preferring order: [String]) -> [PromptSection] {
        let categorised = (global + project).filter { !$0.category.isEmpty }
        var out = orderedCategories(of: categorised, preferring: order).map { name in
            PromptSection(kind: .category(name), showsHeader: true, files: categorised.filter { same($0.category, name) })
        }
        let looseGlobal = global.filter { $0.category.isEmpty }
        let looseProject = project.filter { $0.category.isEmpty }
        let headers = !out.isEmpty || (!looseGlobal.isEmpty && !looseProject.isEmpty)
        if !looseGlobal.isEmpty { out.append(PromptSection(kind: .mine, showsHeader: headers, files: looseGlobal)) }
        if !looseProject.isEmpty { out.append(PromptSection(kind: .project, showsHeader: headers, files: looseProject)) }
        return out
    }

    private static func same(_ a: String, _ b: String) -> Bool { a.caseInsensitiveCompare(b) == .orderedSame }
}
