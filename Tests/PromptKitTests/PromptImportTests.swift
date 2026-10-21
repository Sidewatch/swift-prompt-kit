//
//  PromptImportTests.swift
//  PromptKitTests
//
//  Importing prompts from Markdown and JSON: CRLF files, code fences, what is and is not a heading.
//
//  Created by David Sherlock on 10/21/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import XCTest
@testable import PromptKit

/// `PromptImport`.
final class PromptImportTests: XCTestCase {
    private func titles(_ prompts: [(title: String, body: String)]) -> [String] { prompts.map(\.title) }

    func testEachHeadingStartsAPromptAndTextBeforeTheFirstIsNot() {
        let prompts = PromptImport.markdown("intro text\n# Review\nCheck the diff.\n\n## Explain\nSay why.\n")
        XCTAssertEqual(titles(prompts), ["Review", "Explain"])
        XCTAssertEqual(prompts.first?.body, "Check the diff.")
    }

    func testACRLFFileKeepsSingleLineBreaks() {
        let prompts = PromptImport.markdown("# Steps\r\none\r\ntwo\r\n\r\nthree\r\n")
        XCTAssertEqual(prompts.first?.body, "one\ntwo\n\nthree", "one blank line stays one")
    }

    func testAHashInsideACodeFenceIsTheBodysNotAHeading() {
        let text = "# Setup\nRun:\n```sh\n# install the tools\nbrew install x\n```\nDone.\n# Next\nMore.\n"
        let prompts = PromptImport.markdown(text)
        XCTAssertEqual(titles(prompts), ["Setup", "Next"])
        XCTAssertTrue(prompts.first?.body.contains("# install the tools") ?? false)
        let tilde = PromptImport.markdown("# A\n~~~\n# not a heading\n~~~\n")
        XCTAssertEqual(titles(tilde), ["A"])
    }

    func testOnlyAnATXHeadingIsAHeading() {
        XCTAssertEqual(titles(PromptImport.markdown("# Tags\n#hashtag stays text\n")), ["Tags"])
        XCTAssertEqual(titles(PromptImport.markdown("# Tags\nfirst\n####### seven is text\nmore\n")), ["Tags"], "seven # is text")
        XCTAssertEqual(PromptImport.markdown("# Tags\n#hashtag stays text\n").first?.body, "#hashtag stays text")
    }

    func testEmptySectionsAndUntitledHeadingsAreDropped() {
        XCTAssertEqual(titles(PromptImport.markdown("# Empty\n\n#\nbody\n# Kept\nyes\n")), ["Kept"])
    }

    func testJSONPromptsAndNotAPromptList() throws {
        let data = Data(#"[{"title":"A","body":"one"},{"title":"","body":"x"},{"title":"B","body":""}]"#.utf8)
        XCTAssertEqual(try XCTUnwrap(PromptImport.json(data)).map(\.title), ["A"])
        XCTAssertNil(PromptImport.json(Data(#"{"title":"A"}"#.utf8)))
    }
}
