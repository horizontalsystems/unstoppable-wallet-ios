import Foundation
import HsToolKit
import SwiftUI
import Testing
@testable import WalletCore

struct MarkdownParserTests {
    private static let articleUrl = URL(string: "https://host/path/article.md")!

    private static func parse(_ content: String, url: URL? = articleUrl) -> [MarkdownBlockViewItem] {
        MarkdownParser.viewItems(content: content, url: url, configuration: AcademyMarkdownConfig.config)
    }

    private static func listItems(_ viewItems: [MarkdownBlockViewItem]) -> [(text: String, prefix: String?, tightTop: Bool, tightBottom: Bool)] {
        viewItems.compactMap { viewItem in
            guard case let .listItem(attributedString, prefix, tightTop, tightBottom) = viewItem else {
                return nil
            }

            return (String(attributedString.characters), prefix.map { String($0.characters) }, tightTop, tightBottom)
        }
    }

    private static func blockQuotes(_ viewItems: [MarkdownBlockViewItem]) -> [(tightTop: Bool, tightBottom: Bool)] {
        viewItems.compactMap { viewItem in
            guard case let .blockQuote(_, tightTop, tightBottom) = viewItem else {
                return nil
            }

            return (tightTop, tightBottom)
        }
    }

    @Test func headingLevelsAndParagraphs() throws {
        let viewItems = Self.parse("# H1\n\n## H2\n\n### H3\n\ntext")

        try #require(viewItems.count == 4)

        let levels: [Int] = viewItems.compactMap { viewItem in
            guard case let .header(_, level) = viewItem else {
                return nil
            }
            return level
        }
        #expect(levels == [1, 2, 3])

        guard case let .header(heading, _) = viewItems[0] else {
            Issue.record("first item is not a header")
            return
        }
        let run = try #require(heading.runs.first)
        #expect(run.swiftUI.font != nil)
        #expect(run.swiftUI.foregroundColor != nil)

        guard case let .text(text) = viewItems[3] else {
            Issue.record("last item is not text")
            return
        }
        #expect(String(text.characters) == "text")
    }

    @Test func orderedListPrefixesAndTightness() {
        let items = Self.listItems(Self.parse("1. a\n2. b\n3. c"))

        #expect(items.map(\.text) == ["a", "b", "c"])
        #expect(items.map(\.prefix) == ["1.", "2.", "3."])
        #expect(items.map(\.tightTop) == [false, true, true])
        #expect(items.map(\.tightBottom) == [true, true, false])
    }

    @Test func bulletListLoose() {
        let items = Self.listItems(Self.parse("- a\n\n- b"))

        #expect(items.map(\.prefix) == ["•", "•"])
        #expect(items.map(\.tightTop) == [false, false])
        #expect(items.map(\.tightBottom) == [false, false])
    }

    @Test func listItemSecondParagraphHasNoPrefix() {
        let items = Self.listItems(Self.parse("- first\n\n  second\n"))

        #expect(items.map(\.text) == ["first", "second"])
        #expect(items.map(\.prefix) == ["•", nil])
    }

    @Test func blockQuoteTightness() {
        let quotes = Self.blockQuotes(Self.parse("> one\n>\n> two"))

        #expect(quotes.map(\.tightTop) == [false, true])
        #expect(quotes.map(\.tightBottom) == [true, false])
    }

    @Test func imageTypeFromSuffixAndRelativeUrl() {
        let viewItems = Self.parse("![alt](images/pic-l.png \"t\")\n\ntext\n\n![alt](images/pic-p.png)\n\n![alt](images/pic.png)")

        guard case let .image(firstUrl, firstType, firstTight) = viewItems.first else {
            Issue.record("first item is not an image")
            return
        }
        #expect(firstUrl.absoluteString == "https://host/path/images/pic-l.png")
        #expect(firstType == .landscape)
        #expect(firstTight)
        #expect(viewItems.count > 1 && viewItems[1] == .imageTitle(text: "t"))

        let images: [(url: String, kind: MarkdownImageType, tight: Bool)] = viewItems.compactMap { viewItem in
            guard case let .image(url, type, tight) = viewItem else {
                return nil
            }
            return (url.absoluteString, type, tight)
        }

        #expect(images.map(\.url) == ["https://host/path/images/pic-l.png", "https://host/path/images/pic-p.png", "https://host/path/images/pic.png"])
        #expect(images.map(\.kind) == [.landscape, .portrait, .square])
        #expect(images.map(\.tight) == [true, false, false])
    }

    @Test func linksConvertedWithJacobUnderline() throws {
        let viewItems = Self.parse("before [x](https://a.b) after")

        guard case let .text(text) = try #require(viewItems.first) else {
            Issue.record("first item is not text")
            return
        }

        let linkRun = try #require(text.runs.first { $0.link != nil })
        #expect(linkRun.link == URL(string: "https://a.b"))
        #expect(linkRun.swiftUI.underlineStyle == .single)
        #expect(linkRun.swiftUI.foregroundColor != nil)
        #expect(String(text[linkRun.range].characters) == "x")
    }

    @Test func noUIKitScopedAttributesRemain() throws {
        let viewItems = Self.parse("# Title\n\nSome **bold** and *italic* with [link](https://a.b)\n\n- item\n\n> quote")

        let attributedStrings: [AttributedString] = viewItems.flatMap { viewItem -> [AttributedString] in
            switch viewItem {
            case let .header(attributedString, _), let .text(attributedString), let .blockQuote(attributedString, _, _):
                return [attributedString]
            case let .listItem(attributedString, prefix, _, _):
                return [attributedString] + (prefix.map { [$0] } ?? [])
            case .image, .imageTitle:
                return []
            }
        }

        #expect(attributedStrings.count == 5)

        for attributedString in attributedStrings {
            for run in attributedString.runs {
                #expect(run.uiKit.font == nil)
                #expect(run.uiKit.foregroundColor == nil)
            }

            let nsAttributedString = try NSAttributedString(attributedString, including: \.uiKit)
            var hasParagraphStyle = false
            nsAttributedString.enumerateAttribute(.paragraphStyle, in: NSRange(location: 0, length: nsAttributedString.length)) { value, _, _ in
                if value != nil {
                    hasParagraphStyle = true
                }
            }
            #expect(!hasParagraphStyle)
        }
    }

    @Test func infoViewItemMapping() {
        guard case let .listItem(attributedString, prefix, tightTop, tightBottom) = InfoModule.ViewItem.listItem(text: "x").markdownBlockViewItem else {
            Issue.record("listItem is not mapped to .listItem")
            return
        }

        #expect(String(attributedString.characters) == "x")
        #expect(prefix.map { String($0.characters) } == "•")
        #expect(!tightTop)
        #expect(!tightBottom)

        guard case let .header(_, level) = InfoModule.ViewItem.header3(text: "h").markdownBlockViewItem else {
            Issue.record("header3 is not mapped to .header")
            return
        }

        #expect(level == 3)
    }

    @MainActor @Test func linkActionResolvesRelativeMarkdown() throws {
        let url = try #require(URL(string: "https://host/faq/en/a.md"))
        let relativeUrl = try #require(URL(string: "../b.md"))

        let viewModel = MarkdownViewModel(url: url, mode: .article, handleRelativeUrl: true, networkManager: NetworkManager())
        #expect(try viewModel.linkAction(url: relativeUrl) == .pushMarkdown(url: #require(URL(string: "https://host/faq/b.md"))))

        let htmlUrl = try #require(URL(string: "https://host/page.html"))
        #expect(viewModel.linkAction(url: htmlUrl) == .external(url: htmlUrl))

        let notHandlingViewModel = MarkdownViewModel(url: url, mode: .article, handleRelativeUrl: false, networkManager: NetworkManager())
        #expect(notHandlingViewModel.linkAction(url: relativeUrl) == .external(url: relativeUrl))
    }
}
