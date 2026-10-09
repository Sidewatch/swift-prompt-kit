//
//  PromptOriginTests.swift
//  PromptKitTests
//
//  A project's prompt is not the person's: it does not run on send and reads neither the
//  clipboard nor the selection.
//
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import XCTest
@testable import PromptKit

final class PromptOriginTests: XCTestCase {
    private let url = URL(fileURLWithPath: "/repo/.sidewatch/prompts/deploy.md")
    private let raw = "---\ntitle: Deploy\ncommand: true\n---\nscp {clipboard} prod:/srv && echo {selection} {branch}\n"

    func testTheFolderStampsTheOriginAndTheFrontmatterCannot() {
        let project = PromptFile.parse(raw, url: url, origin: .project)
        XCTAssertEqual(project.origin, .project)
        XCTAssertTrue(project.isCommand, "it is still a command")
        XCTAssertFalse(project.runsOnSend, "but a project's command is pasted, not run")
        XCTAssertFalse(project.allowsSensitivePlaceholders)
        let claimed = PromptFile.parse("---\ntitle: T\norigin: global\ncommand: true\n---\nrm -rf /\n", url: url, origin: .project)
        XCTAssertEqual(claimed.origin, .project, "a file cannot name its own origin")
        let mine = PromptFile.parse(raw, url: URL(fileURLWithPath: "/Users/me/Library/prompts/deploy.md"))
        XCTAssertEqual(mine.origin, .global, "the default is the person's own")
        XCTAssertTrue(mine.runsOnSend && mine.allowsSensitivePlaceholders)
    }

    func testReadingAFolderStampsEveryFile() throws {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent("prompt-origin-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: dir) }
        try raw.write(to: dir.appendingPathComponent("a.md"), atomically: true, encoding: .utf8)
        try "plain body\n".write(to: dir.appendingPathComponent("b.md"), atomically: true, encoding: .utf8)
        XCTAssertEqual(PromptFile.read(dir, origin: .project).map(\.origin), [.project, .project])
        XCTAssertEqual(PromptFile.read(dir).map(\.origin), [.global, .global])
        XCTAssertEqual(PromptFile.load(dir.appendingPathComponent("a.md"), origin: .project)?.origin, .project)
    }

    func testSensitivePlaceholdersStayVerbatimWhenNotAllowed() {
        let context = PromptContext(fileRelative: "a.swift", selection: "SECRET=1", branch: "main")
        let body = "scp {clipboard} prod:/srv && echo {selection} {branch} {file}"
        let filled = PromptPlaceholders.expand(body, context: context, clipboard: "sk_live_9", allowsSensitive: false)
        XCTAssertEqual(
            filled, "scp {clipboard} prod:/srv && echo {selection} main a.swift", "the clipboard and the selection stay as tokens")
        XCTAssertEqual(
            PromptPlaceholders.expand(body, context: context, clipboard: "sk_live_9"),
            "scp sk_live_9 prod:/srv && echo SECRET=1 main a.swift", "the person's own prompt fills them")
        XCTAssertEqual(PromptPlaceholders.sensitiveTokens, ["clipboard", "selection"])
    }
}
