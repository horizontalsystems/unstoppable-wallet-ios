import UIKit
import Down
import libcmark

protocol GuideBlock: CustomStringConvertible {}

class GuideVisitor {
    private let attributedStringVisitor: AttributedStringVisitor
    private let styler: Styler

    init(attributedStringVisitor: AttributedStringVisitor, styler: Styler) {
        self.attributedStringVisitor = attributedStringVisitor
        self.styler = styler
    }

}

extension GuideVisitor: Visitor {
    public typealias Result = GuideBlock

    public func visit(document node: Document) -> GuideBlock {
        DocumentBlock(blocks: visitChildren(of: node))
    }

    public func visit(blockQuote node: BlockQuote) -> GuideBlock {
        BlockQuoteBlock(blocks: visitChildren(of: node))
    }

    public func visit(list node: List) -> GuideBlock {
        var startOrder: Int?

        if case .ordered(let start) = node.listType {
            startOrder = start
        }

        return ListBlock(blocks: visitChildren(of: node), tight: node.isTight, startOrder: startOrder)
    }

    public func visit(item node: Item) -> GuideBlock {
        ItemBlock(blocks: visitChildren(of: node))
    }

    public func visit(codeBlock node: CodeBlock) -> GuideBlock {
        UnhandledBlock(type: "CodeBlock")
    }

    public func visit(htmlBlock node: HtmlBlock) -> GuideBlock {
        UnhandledBlock(type: "HtmlBlock")
    }

    public func visit(customBlock node: CustomBlock) -> GuideBlock {
        UnhandledBlock(type: "CustomBlock")
    }

    public func visit(paragraph node: Paragraph) -> GuideBlock {
        // handle paragraph with single image
        if node.children.count == 1, let image = node.children.first as? Image {
            return visit(image: image)
        }

        let s = attributedStringVisitor.visitChildren(of: node).joined
        styler.style(paragraph: s)
        return ParagraphBlock(attributedString: s)
    }

    public func visit(heading node: Heading) -> GuideBlock {
        let s = attributedStringVisitor.visitChildren(of: node).joined
        styler.style(heading: s, level: node.headingLevel)
        return HeadingBlock(attributedString: s, level: node.headingLevel)
    }

    public func visit(thematicBreak node: ThematicBreak) -> GuideBlock {
        UnhandledBlock(type: "ThematicBreak")
    }

    public func visit(text node: Text) -> GuideBlock {
        UnhandledBlock(type: "Text")
    }

    public func visit(softBreak node: SoftBreak) -> GuideBlock {
        UnhandledBlock(type: "SoftBreak")
    }

    public func visit(lineBreak node: LineBreak) -> GuideBlock {
        UnhandledBlock(type: "LineBreak")
    }

    public func visit(code node: Code) -> GuideBlock {
        UnhandledBlock(type: "Code")
    }

    public func visit(htmlInline node: HtmlInline) -> GuideBlock {
        UnhandledBlock(type: "HtmlInline")
    }

    public func visit(customInline node: CustomInline) -> GuideBlock {
        UnhandledBlock(type: "CustomInline")
    }

    public func visit(emphasis node: Emphasis) -> GuideBlock {
        UnhandledBlock(type: "Emphasis")
    }

    public func visit(strong node: Strong) -> GuideBlock {
        UnhandledBlock(type: "Strong")
    }

    public func visit(link node: Link) -> GuideBlock {
        UnhandledBlock(type: "Link")
    }

    public func visit(image node: Image) -> GuideBlock {
        ImageBlock(title: node.title, url: node.url)
    }

}

extension GuideVisitor {

    struct DocumentBlock: GuideBlock {
        let blocks: [GuideBlock]

        var description: String {
            "DocumentBlock: \(blocks.count) blocks:\n\(blocks.map { "\($0)" }.joined(separator: "\n"))\n\n"
        }

    }

    struct HeadingBlock: GuideBlock {
        let attributedString: NSAttributedString
        let level: Int

        var description: String {
            "Heading Block: level: \(level): \(attributedString.string)"
        }

    }

    struct ParagraphBlock: GuideBlock {
        let attributedString: NSAttributedString

        var description: String {
            "Paragraph Block: \(attributedString.string)"
        }

    }

    struct ImageBlock: GuideBlock {
        let title: String?
        let url: String?

        var description: String {
            "Image Block: title: \(title ?? "nil"), url: \(url ?? "nil")"
        }

    }

    struct ListBlock: GuideBlock {
        let blocks: [GuideBlock]
        let tight: Bool
        var startOrder: Int?

        var itemBlocks: [ItemBlock] {
            blocks.compactMap { $0 as? ItemBlock }
        }

        var description: String {
            "List Block: [tight=\(tight), startOrder=\(startOrder.map { "\($0)" } ?? "nil")] \(blocks.count) blocks:\n\(blocks.map { "\($0)" }.joined(separator: "\n"))\n\n"
        }

    }

    struct ItemBlock: GuideBlock {
        let blocks: [GuideBlock]

        var paragraphBlocks: [ParagraphBlock] {
            blocks.compactMap { $0 as? ParagraphBlock }
        }

        var description: String {
            "Item Block: \(blocks.count) block(s)"
        }

    }

    struct BlockQuoteBlock: GuideBlock {
        let blocks: [GuideBlock]

        var paragraphBlocks: [ParagraphBlock] {
            blocks.compactMap { $0 as? ParagraphBlock }
        }

        var description: String {
            "BlockQuote Block: \(blocks.count) block(s)"
        }

    }

    struct UnhandledBlock: GuideBlock {
        let type: String

        var description: String {
            "Unhandled Block: \(type)"
        }

    }

}

private extension Sequence where Iterator.Element == NSMutableAttributedString {

    var joined: NSMutableAttributedString {
        reduce(into: NSMutableAttributedString()) { $0.append($1) }
    }

}
