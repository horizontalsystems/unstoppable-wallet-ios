import UIKit
import Down
import libcmark

protocol MarkdownBlock: CustomStringConvertible {}

class MarkdownVisitor {
    private let attributedStringVisitor: AttributedStringVisitor
    private let styler: Styler

    init(attributedStringVisitor: AttributedStringVisitor, styler: Styler) {
        self.attributedStringVisitor = attributedStringVisitor
        self.styler = styler
    }

}

extension MarkdownVisitor: Visitor {
    public typealias Result = MarkdownBlock

    public func visit(document node: Document) -> MarkdownBlock {
        DocumentBlock(blocks: visitChildren(of: node))
    }

    public func visit(blockQuote node: BlockQuote) -> MarkdownBlock {
        BlockQuoteBlock(blocks: visitChildren(of: node))
    }

    public func visit(list node: List) -> MarkdownBlock {
        var startOrder: Int?

        if case .ordered(let start) = node.listType {
            startOrder = start
        }

        return ListBlock(blocks: visitChildren(of: node), tight: node.isTight, startOrder: startOrder)
    }

    public func visit(item node: Item) -> MarkdownBlock {
        ItemBlock(blocks: visitChildren(of: node))
    }

    public func visit(codeBlock node: CodeBlock) -> MarkdownBlock {
        UnhandledBlock(type: "CodeBlock")
    }

    public func visit(htmlBlock node: HtmlBlock) -> MarkdownBlock {
        UnhandledBlock(type: "HtmlBlock")
    }

    public func visit(customBlock node: CustomBlock) -> MarkdownBlock {
        UnhandledBlock(type: "CustomBlock")
    }

    public func visit(paragraph node: Paragraph) -> MarkdownBlock {
        // handle paragraph with single image
        if node.children.count == 1, let image = node.children.first as? Image {
            return visit(image: image)
        }

        let s = attributedStringVisitor.visitChildren(of: node).joined
        styler.style(paragraph: s)
        return ParagraphBlock(attributedString: s)
    }

    public func visit(heading node: Heading) -> MarkdownBlock {
        let s = attributedStringVisitor.visitChildren(of: node).joined
        styler.style(heading: s, level: node.headingLevel)
        return HeadingBlock(attributedString: s, level: node.headingLevel)
    }

    public func visit(thematicBreak node: ThematicBreak) -> MarkdownBlock {
        UnhandledBlock(type: "ThematicBreak")
    }

    public func visit(text node: Text) -> MarkdownBlock {
        UnhandledBlock(type: "Text")
    }

    public func visit(softBreak node: SoftBreak) -> MarkdownBlock {
        UnhandledBlock(type: "SoftBreak")
    }

    public func visit(lineBreak node: LineBreak) -> MarkdownBlock {
        UnhandledBlock(type: "LineBreak")
    }

    public func visit(code node: Code) -> MarkdownBlock {
        UnhandledBlock(type: "Code")
    }

    public func visit(htmlInline node: HtmlInline) -> MarkdownBlock {
        UnhandledBlock(type: "HtmlInline")
    }

    public func visit(customInline node: CustomInline) -> MarkdownBlock {
        UnhandledBlock(type: "CustomInline")
    }

    public func visit(emphasis node: Emphasis) -> MarkdownBlock {
        UnhandledBlock(type: "Emphasis")
    }

    public func visit(strong node: Strong) -> MarkdownBlock {
        UnhandledBlock(type: "Strong")
    }

    public func visit(link node: Link) -> MarkdownBlock {
        UnhandledBlock(type: "Link")
    }

    public func visit(image node: Image) -> MarkdownBlock {
        ImageBlock(title: node.title, url: node.url)
    }

}

extension MarkdownVisitor {

    struct DocumentBlock: MarkdownBlock {
        let blocks: [MarkdownBlock]

        var description: String {
            "DocumentBlock: \(blocks.count) blocks:\n\(blocks.map { "\($0)" }.joined(separator: "\n"))\n\n"
        }

    }

    struct HeadingBlock: MarkdownBlock {
        let attributedString: NSAttributedString
        let level: Int

        var description: String {
            "Heading Block: level: \(level): \(attributedString.string)"
        }

    }

    struct ParagraphBlock: MarkdownBlock {
        let attributedString: NSAttributedString

        var description: String {
            "Paragraph Block: \(attributedString.string)"
        }

    }

    struct ImageBlock: MarkdownBlock {
        let title: String?
        let url: String?

        var description: String {
            "Image Block: title: \(title ?? "nil"), url: \(url ?? "nil")"
        }

    }

    struct ListBlock: MarkdownBlock {
        let blocks: [MarkdownBlock]
        let tight: Bool
        var startOrder: Int?

        var itemBlocks: [ItemBlock] {
            blocks.compactMap { $0 as? ItemBlock }
        }

        var description: String {
            "List Block: [tight=\(tight), startOrder=\(startOrder.map { "\($0)" } ?? "nil")] \(blocks.count) blocks:\n\(blocks.map { "\($0)" }.joined(separator: "\n"))\n\n"
        }

    }

    struct ItemBlock: MarkdownBlock {
        let blocks: [MarkdownBlock]

        var paragraphBlocks: [ParagraphBlock] {
            blocks.compactMap { $0 as? ParagraphBlock }
        }

        var description: String {
            "Item Block: \(blocks.count) block(s)"
        }

    }

    struct BlockQuoteBlock: MarkdownBlock {
        let blocks: [MarkdownBlock]

        var paragraphBlocks: [ParagraphBlock] {
            blocks.compactMap { $0 as? ParagraphBlock }
        }

        var description: String {
            "BlockQuote Block: \(blocks.count) block(s)"
        }

    }

    struct UnhandledBlock: MarkdownBlock {
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
