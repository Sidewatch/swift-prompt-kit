//
//  PromptKitTests.swift
//  Tests for PromptFile frontmatter parse/serialize round-trip and the pure
//  PromptPlaceholders.expand token substitution (deterministic via injected now).
//

import XCTest
@testable import PromptKit

final class PromptKitTests: XCTestCase {

    private let url = URL(fileURLWithPath: "/prompts/api-review.md")

    // MARK: - PromptFile.parse

    func testParsesFrontmatterTitleAndDescription() {
        let raw = """
        ---
        title: API Review
        description: Review the API surface
        ---

        Check every public endpoint.
        """
        let pf = PromptFile.parse(raw, url: url)
        XCTAssertEqual(pf.title, "API Review")
        XCTAssertEqual(pf.description, "Review the API surface")
        XCTAssertEqual(pf.body, "Check every public endpoint.")
    }

    func testTitleFallsBackToPrettifiedFilename() {
        let pf = PromptFile.parse("just a body line\n", url: url)
        XCTAssertEqual(pf.title, "api review")             // hyphen → space
        XCTAssertEqual(pf.description, "just a body line")  // first non-empty line
    }

    func testStripsQuotesFromFrontmatterValues() {
        let raw = "---\ntitle: \"Quoted Title\"\ndescription: 'single'\n---\nbody"
        let pf = PromptFile.parse(raw, url: url)
        XCTAssertEqual(pf.title, "Quoted Title")
        XCTAssertEqual(pf.description, "single")
    }

    func testUnknownFrontmatterKeysIgnored() {
        let raw = "---\ntitle: T\nauthor: someone\ntags: a, b\n---\nbody"
        let pf = PromptFile.parse(raw, url: url)
        XCTAssertEqual(pf.title, "T")
        XCTAssertEqual(pf.body, "body")
    }

    func testColonInValuePreserved() {
        let raw = "---\ntitle: Ratio 3:1 review\n---\nbody"
        XCTAssertEqual(PromptFile.parse(raw, url: url).title, "Ratio 3:1 review")
    }

    func testBodyOpeningWithThematicBreakIsNotFrontmatter() {
        let raw = "---\n\nDo the thing carefully.\n\n---\n\nfinal section"
        let pf = PromptFile.parse(raw, url: url)
        XCTAssertEqual(pf.body, raw)                        // nothing dropped
        XCTAssertEqual(pf.title, "api review")              // filename fallback
    }

    func testDashesWithTrailingTextAreNotFrontmatter() {
        let raw = "--- draft ---\ntitle: not a key\n---\nrest"
        XCTAssertEqual(PromptFile.parse(raw, url: url).body, raw)
    }

    func testLongerDashRunIsNotFrontmatter() {
        let raw = "----\ntitle: x\n----\nrest"
        XCTAssertEqual(PromptFile.parse(raw, url: url).body, raw)
    }

    func testProseBetweenRulesWithColonLineStaysBody() {
        // "note: use staging" is key:value-shaped, but the prose line around it is
        // not — the whole span must stay body, not parse as frontmatter.
        let raw = "---\nSome prose first\nnote: use staging\n---\nrest"
        XCTAssertEqual(PromptFile.parse(raw, url: url).body, raw)
    }

    func testSerializeRoundTrips() {
        let pf = PromptFile(title: "T", description: "D", body: "the body", url: url)
        let reparsed = PromptFile.parse(pf.serialized(), url: url)
        XCTAssertEqual(reparsed.title, "T")
        XCTAssertEqual(reparsed.description, "D")
        XCTAssertEqual(reparsed.body, "the body")
    }

    func testSerializeOmitsEmptyDescription() {
        let pf = PromptFile(title: "T", description: "", body: "b", url: url)
        XCTAssertFalse(pf.serialized().contains("description:"))
    }

    func testSerializeFlattensNewlinesInTitleAndDescription() {
        let pf = PromptFile(title: "X\ncommand: true", description: "line1\nline2", body: "b", url: url)
        let reparsed = PromptFile.parse(pf.serialized(), url: url)
        XCTAssertEqual(reparsed.title, "X command: true")
        XCTAssertEqual(reparsed.description, "line1 line2")
        XCTAssertFalse(reparsed.isCommand)                  // no injected command: key
        XCTAssertEqual(reparsed.body, "b")
    }

    // MARK: - category

    func testParsesCategory() {
        let raw = "---\ntitle: T\ncategory: Understand\n---\nbody"
        XCTAssertEqual(PromptFile.parse(raw, url: url).category, "Understand")
    }

    func testCategoryDefaultsEmpty() {
        XCTAssertEqual(PromptFile.parse("---\ntitle: T\n---\nbody", url: url).category, "")
    }

    func testCategoryRoundTrips() {
        let pf = PromptFile(title: "T", description: "D", body: "b", url: url, category: "Debug")
        XCTAssertEqual(PromptFile.parse(pf.serialized(), url: url).category, "Debug")
    }

    func testSerializeOmitsEmptyCategory() {
        let pf = PromptFile(title: "T", description: "", body: "b", url: url)
        XCTAssertFalse(pf.serialized().contains("category:"))
    }

    func testCategoryFlattensNewlines() {
        // Same injection guard as title/description: a newline in the value must not be
        // able to forge a second frontmatter key on reload.
        let pf = PromptFile(title: "T", description: "", body: "b", url: url,
                            category: "Debug\ncommand: true")
        let reparsed = PromptFile.parse(pf.serialized(), url: url)
        XCTAssertEqual(reparsed.category, "Debug command: true")
        XCTAssertFalse(reparsed.isCommand)
    }

    func testCategoryAndCommandCoexist() {
        let pf = PromptFile(title: "T", description: "D", body: "b", url: url,
                            isCommand: true, category: "Git")
        let reparsed = PromptFile.parse(pf.serialized(), url: url)
        XCTAssertTrue(reparsed.isCommand)
        XCTAssertEqual(reparsed.category, "Git")
    }

    func testPromptBridge() {
        let pf = PromptFile(title: "T", description: "D", body: "b", url: url)
        XCTAssertEqual(pf.prompt, Prompt(title: "T", body: "b"))
    }

    // MARK: - slug

    func testSlug() {
        XCTAssertEqual(PromptFile.slug("New Prompt"), "new-prompt")
        XCTAssertEqual(PromptFile.slug("Fix: bug!!!"), "fix-bug")
        XCTAssertEqual(PromptFile.slug("!!!"), "prompt")     // punctuation-only fallback
    }

    // MARK: - projectDirectory

    func testProjectDirectory() {
        let dir = PromptFile.projectDirectory(root: URL(fileURLWithPath: "/repo"))
        XCTAssertTrue(dir.path.hasSuffix(".sidewatch/prompts"))
    }

    // MARK: - read / create (disk)

    func testCreateThenReadRoundTrip() throws {
        let dir = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("promptkit-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: dir) }

        let pf = PromptFile(title: "Saved One", description: "desc", body: "body text", url: dir)
        let created = try XCTUnwrap(PromptFile.create(in: dir, base: "Saved One", content: pf.serialized()))
        XCTAssertTrue(created.lastPathComponent.hasPrefix("saved-one"))

        let all = PromptFile.read(dir)
        XCTAssertEqual(all.count, 1)
        XCTAssertEqual(all.first?.title, "Saved One")
        XCTAssertEqual(all.first?.body, "body text")
    }

    func testCreateDeduplicatesFilenames() throws {
        let dir = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("promptkit-dup-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: dir) }
        let a = try XCTUnwrap(PromptFile.create(in: dir, base: "note", content: "x"))
        let b = try XCTUnwrap(PromptFile.create(in: dir, base: "note", content: "y"))
        XCTAssertNotEqual(a.lastPathComponent, b.lastPathComponent)
        XCTAssertEqual(PromptFile.read(dir).count, 2)
    }

    // MARK: - PromptPlaceholders.expand

    private func fixedNow() -> Date {
        // 2026-07-19 14:05:00 UTC.
        DateComponents(calendar: Calendar(identifier: .gregorian),
                       timeZone: TimeZone(identifier: "UTC"),
                       year: 2026, month: 7, day: 19, hour: 14, minute: 5).date!
    }

    func testExpandFillsContextTokens() {
        let ctx = PromptContext(fileRelative: "src/main.swift", fileName: "main.swift",
                                selection: "let x = 1", line: 42, branch: "feature", repo: "myrepo")
        let out = PromptPlaceholders.expand(
            "Review {file} ({filename}) line {line} on {branch} of {repo}: {selection}",
            context: ctx)
        XCTAssertEqual(out, "Review src/main.swift (main.swift) line 42 on feature of myrepo: let x = 1")
    }

    func testExpandMissingValuesBecomeEmpty() {
        let out = PromptPlaceholders.expand("[{branch}]", context: PromptContext())
        XCTAssertEqual(out, "[]")
    }

    func testExpandDateTimeDeterministic() {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone.current
        let out = PromptPlaceholders.expand("{date} {time} | {datetime} | {today}",
                                            context: PromptContext(), now: fixedNow())
        // Exact strings depend on the machine's timezone; assert structure instead.
        XCTAssertTrue(out.contains("|"))
        XCTAssertFalse(out.contains("{date}"))
        XCTAssertFalse(out.contains("{datetime}"))
        XCTAssertFalse(out.contains("{today}"))
    }

    func testExpandClipboardInjected() {
        let out = PromptPlaceholders.expand("paste: {clipboard}", context: PromptContext(),
                                            clipboard: "copied text")
        XCTAssertEqual(out, "paste: copied text")
    }

    func testExpandLeavesUnknownTokens() {
        let out = PromptPlaceholders.expand("keep {unknown} token", context: PromptContext())
        XCTAssertEqual(out, "keep {unknown} token")
    }

    func testExpandCaseInsensitiveTokens() {
        let out = PromptPlaceholders.expand("{FILE}", context: PromptContext(fileRelative: "a.swift"))
        XCTAssertEqual(out, "a.swift")
    }

    func testExpandNoBracesShortCircuits() {
        XCTAssertEqual(PromptPlaceholders.expand("no tokens here", context: PromptContext()),
                       "no tokens here")
    }

    func testExpandDoesNotReExpandTokensInsideSubstitutedValues() {
        // A selection that itself contains a placeholder-shaped string (real code with
        // brace template strings) must survive verbatim — no clipboard leak.
        let ctx = PromptContext(selection: "let s = \"{clipboard}\"")
        let out = PromptPlaceholders.expand("Review {selection}", context: ctx,
                                            clipboard: "SECRET-TOKEN")
        XCTAssertEqual(out, "Review let s = \"{clipboard}\"")
    }

    func testExpandDoesNotReExpandTokensInsideFileNames() {
        let ctx = PromptContext(fileRelative: "{branch}.swift", branch: "main")
        XCTAssertEqual(PromptPlaceholders.expand("Check {file} on {branch}", context: ctx),
                       "Check {branch}.swift on main")
    }

    func testExpandUnmatchedBracesLeftLiteral() {
        let ctx = PromptContext(fileRelative: "a.swift")
        XCTAssertEqual(PromptPlaceholders.expand("open { brace {file}", context: ctx),
                       "open { brace a.swift")
        XCTAssertEqual(PromptPlaceholders.expand("{{file}", context: ctx), "{a.swift")
        XCTAssertEqual(PromptPlaceholders.expand("tail {", context: ctx), "tail {")
    }
}
