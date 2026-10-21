//
//  PromptLibraryLayoutTests.swift
//  PromptKitTests
//
//  Category order, sections and their headers, and the library filter.
//
//  Created by David Sherlock on 10/21/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import XCTest
@testable import PromptKit

/// `PromptLibraryLayout` and `PromptFile.matches(query:category:)`.
final class PromptLibraryLayoutTests: XCTestCase {
    private func file(_ title: String, _ category: String = "", body: String = "", origin: PromptOrigin = .global) -> PromptFile {
        PromptFile(
            title: title, description: "", body: body, url: URL(fileURLWithPath: "/p/\(title).md"), category: category, origin: origin)
    }

    func testCategoriesFollowThePreferredOrderThenTheAlphabetAndTheFirstSpellingWins() {
        let files = [file("a", "zeta"), file("b", "Debug"), file("c", "alpha"), file("d", "debug"), file("e", "Plan"), file("f")]
        XCTAssertEqual(
            PromptLibraryLayout.orderedCategories(of: files, preferring: ["plan", "debug"]), ["Plan", "Debug", "alpha", "zeta"])
    }

    func testACategoryGathersBothFoldersAndLooseOnesKeepTheirFolder() {
        let sections = PromptLibraryLayout.sections(
            global: [file("g1", "Debug"), file("g2")], project: [file("p1", "debug", origin: .project), file("p2", origin: .project)],
            preferring: [])
        XCTAssertEqual(sections.map(\.kind), [.category("Debug"), .mine, .project])
        XCTAssertEqual(sections[0].files.map(\.title), ["g1", "p1"])
        XCTAssertEqual(sections.map(\.showsHeader), [true, true, true])
    }

    func testOneFolderOfLoosePromptsNeedsNoHeaderButTwoDo() {
        let mineOnly = PromptLibraryLayout.sections(global: [file("a"), file("b")], project: [], preferring: [])
        XCTAssertEqual(mineOnly.map(\.kind), [.mine])
        XCTAssertEqual(mineOnly.map(\.showsHeader), [false])
        let both = PromptLibraryLayout.sections(global: [file("a")], project: [file("b", origin: .project)], preferring: [])
        XCTAssertEqual(both.map(\.showsHeader), [true, true])
        let projectBesideACategory = PromptLibraryLayout.sections(
            global: [file("a", "Plan")], project: [file("b", origin: .project)], preferring: [])
        XCTAssertEqual(projectBesideACategory.map(\.showsHeader), [true, true])
        XCTAssertTrue(PromptLibraryLayout.sections(global: [], project: [], preferring: []).isEmpty)
    }

    func testTheFilterReadsEveryFieldAndTheScopeIgnoresCase() {
        let f = file("Fix tests", "Debug", body: "run the suite")
        XCTAssertTrue(f.matches(query: "", category: nil))
        XCTAssertTrue(f.matches(query: "  SUITE ", category: nil), "body, trimmed, any case")
        XCTAssertTrue(f.matches(query: "debug", category: nil), "category text")
        XCTAssertTrue(f.matches(query: "fix", category: "debug"))
        XCTAssertFalse(f.matches(query: "fix", category: "Plan"))
        XCTAssertFalse(f.matches(query: "deploy", category: nil))
    }
}
