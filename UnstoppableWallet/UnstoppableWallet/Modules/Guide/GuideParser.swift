import UIKit
import ThemeKit
import Down
import libcmark

class GuideParser {

    private let fonts = StaticFontCollection(
            heading1: .title2,
            heading2: .title3,
            heading3: .headline2,
            body: .body
    )

    private let colors = StaticColorCollection(
            heading1: .themeOz,
            heading2: .themeJacob,
            heading3: .themeJacob,
            body: .themeOz
    )

    private let paragraphStyles: StaticParagraphStyleCollection = {
        var paragraphStyles = StaticParagraphStyleCollection()

        let bodyParagraphStyle = NSMutableParagraphStyle()
        bodyParagraphStyle.lineSpacing = 6

        paragraphStyles.heading1 = NSParagraphStyle()
        paragraphStyles.heading2 = NSParagraphStyle()
        paragraphStyles.heading3 = NSParagraphStyle()
        paragraphStyles.body = bodyParagraphStyle

        return paragraphStyles
    }()

}

extension GuideParser: IGuideParser {

    func blocks(markdownFileName: String) -> [GuideBlock] {
        guard let url = Bundle.main.url(forResource: markdownFileName, withExtension: "md") else {
            return []
        }

        do {
            let string = try NSString(contentsOf: url, encoding: String.Encoding.utf8.rawValue) as String
            let down = Down(markdownString: string)

            let configuration = DownStylerConfiguration(
                    fonts: fonts,
                    colors: colors,
                    paragraphStyles: paragraphStyles
            )

            let styler = DownStyler(configuration: configuration)

            let tree = try down.toAST().wrap()

            guard let document = tree as? Document else {
                throw DownErrors.astRenderingError
            }

            let attributedStringVisitor = AttributedStringVisitor(styler: styler)
            let visitor = MyVisitor(attributedStringVisitor: attributedStringVisitor)
            let block = document.accept(visitor)

            print(block)

            guard let documentBlock = block as? DocumentBlock else {
                return []
            }

            var blocks = [GuideBlock]()

            for block in documentBlock.blocks {
                if let headingBlock = block as? HeadingBlock {
                    if headingBlock.level == 1 {
                        blocks.append(.h1(attributedString: headingBlock.attributedString))
                    } else if headingBlock.level == 2 {
                        blocks.append(.h2(attributedString: headingBlock.attributedString))
                    } else if headingBlock.level == 3 {
                        blocks.append(.h3(attributedString: headingBlock.attributedString))
                    }
                }

                if let paragraphBlock = block as? ParagraphBlock {
                    blocks.append(.text(attributedString: paragraphBlock.attributedString))
                }

                if let listBlock = block as? ListBlock {
                    for block in listBlock.blocks {
                        if let itemBlock = block as? ItemBlock {
                            blocks.append(.text(attributedString: itemBlock.attributedString))
                        }
                    }
                }
            }

            return blocks
        } catch {
            return []
        }
    }

}

class MyVisitor {
    private let attributedStringVisitor: AttributedStringVisitor

    init(attributedStringVisitor: AttributedStringVisitor) {
        self.attributedStringVisitor = attributedStringVisitor
    }

}

extension MyVisitor: Visitor {
    public typealias Result = MyBlock

    public func visit(document node: Document) -> MyBlock {
        DocumentBlock(blocks: visitChildren(of: node))
    }

    public func visit(blockQuote node: BlockQuote) -> MyBlock {
        SimpleBlock(attributedString: attributedStringVisitor.visit(blockQuote: node), type: "blockQuote")
    }

    public func visit(list node: List) -> MyBlock {
        ListBlock(blocks: visitChildren(of: node))
    }

    public func visit(item node: Item) -> MyBlock {
        ItemBlock(attributedString: attributedStringVisitor.visit(item: node))
    }

    public func visit(codeBlock node: CodeBlock) -> MyBlock {
        SimpleBlock(attributedString: attributedStringVisitor.visit(codeBlock: node), type: "codeBlock")
    }

    public func visit(htmlBlock node: HtmlBlock) -> MyBlock {
        SimpleBlock(attributedString: attributedStringVisitor.visit(htmlBlock: node), type: "htmlBlock")
    }

    public func visit(customBlock node: CustomBlock) -> MyBlock {
        SimpleBlock(attributedString: attributedStringVisitor.visit(customBlock: node), type: "customBlock")
    }

    public func visit(paragraph node: Paragraph) -> MyBlock {
        let attributedStrings = attributedStringVisitor.visitChildren(of: node)
        let attributedString = attributedStrings.reduce(into: NSMutableAttributedString()) { $0.append($1) }
        return ParagraphBlock(attributedString: attributedString)
    }

    public func visit(heading node: Heading) -> MyBlock {
        HeadingBlock(attributedString: attributedStringVisitor.visit(heading: node), level: node.headingLevel)
    }

    public func visit(thematicBreak node: ThematicBreak) -> MyBlock {
        SimpleBlock(attributedString: attributedStringVisitor.visit(thematicBreak: node), type: "thematicBreak")
    }

    public func visit(text node: Text) -> MyBlock {
        SimpleBlock(attributedString: attributedStringVisitor.visit(text: node), type: "text")
    }

    public func visit(softBreak node: SoftBreak) -> MyBlock {
        SimpleBlock(attributedString: attributedStringVisitor.visit(softBreak: node), type: "softBreak")
    }

    public func visit(lineBreak node: LineBreak) -> MyBlock {
        SimpleBlock(attributedString: attributedStringVisitor.visit(lineBreak: node), type: "lineBreak")
    }

    public func visit(code node: Code) -> MyBlock {
        SimpleBlock(attributedString: attributedStringVisitor.visit(code: node), type: "code")
    }

    public func visit(htmlInline node: HtmlInline) -> MyBlock {
        SimpleBlock(attributedString: attributedStringVisitor.visit(htmlInline: node), type: "htmlInline")
    }

    public func visit(customInline node: CustomInline) -> MyBlock {
        SimpleBlock(attributedString: attributedStringVisitor.visit(customInline: node), type: "customInline")
    }

    public func visit(emphasis node: Emphasis) -> MyBlock {
        SimpleBlock(attributedString: attributedStringVisitor.visit(emphasis: node), type: "emphasis")
    }

    public func visit(strong node: Strong) -> MyBlock {
        SimpleBlock(attributedString: attributedStringVisitor.visit(strong: node), type: "strong")
    }

    public func visit(link node: Link) -> MyBlock {
        SimpleBlock(attributedString: attributedStringVisitor.visit(link: node), type: "link")
    }

    public func visit(image node: Image) -> MyBlock {
        ImageBlock(title: node.title, url: node.url)
    }

}

protocol MyBlock: CustomStringConvertible {
}

struct DocumentBlock: MyBlock {
    let blocks: [MyBlock]

    var description: String {
        "DocumentBlock: \(blocks.count) blocks:\n\(blocks.map { "\($0)" }.joined(separator: "\n"))\n\n"
    }

}

struct HeadingBlock: MyBlock {
    let attributedString: NSAttributedString
    let level: Int

    var description: String {
        "Heading Block: level: \(level): \(attributedString.string)"
    }

}

struct ParagraphBlock: MyBlock {
    let attributedString: NSAttributedString

    var description: String {
        "Paragraph Block: \(attributedString.string)"
    }

}

struct ImageBlock: MyBlock {
    let title: String?
    let url: String?

    var description: String {
        "Image Block: title: \(title ?? "nil"), url: \(url ?? "nil")"
    }

}

struct ListBlock: MyBlock {
    let blocks: [MyBlock]

    var description: String {
        "List Block: \(blocks.count) blocks:\n\(blocks.map { "\($0)" }.joined(separator: "\n"))\n\n"
    }

}

struct ItemBlock: MyBlock {
    let attributedString: NSAttributedString

    var description: String {
        "Item Block: \(attributedString.string)"
    }

}

struct SimpleBlock: MyBlock {
    let attributedString: NSAttributedString
    let type: String

    var description: String {
        "Simple Block: [\(type)] \(attributedString.string)"
    }

}
