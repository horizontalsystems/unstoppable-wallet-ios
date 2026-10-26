import Down
import UIKit

enum MarkdownParser {
    static func viewItems(content: String, url: URL?, configuration: DownStylerConfiguration) -> [MarkdownBlockViewItem] {
        let down = Down(markdownString: content)

        let styler = DownStyler(configuration: configuration)

        do {
            let tree = try down.toAST().wrap()

            guard let document = tree as? Document else {
                throw DownErrors.astRenderingError
            }

            let attributedStringVisitor = AttributedStringVisitor(styler: styler)
            let visitor = MarkdownVisitor(attributedStringVisitor: attributedStringVisitor, styler: styler)
            let block = document.accept(visitor)

            guard let documentBlock = block as? MarkdownVisitor.DocumentBlock else {
                return []
            }

            var viewItems = [MarkdownBlockViewItem]()

            for (blockIndex, block) in documentBlock.blocks.enumerated() {
                if let headingBlock = block as? MarkdownVisitor.HeadingBlock {
                    viewItems.append(.header(attributedString: convert(headingBlock.attributedString), level: headingBlock.level))
                }

                if let paragraphBlock = block as? MarkdownVisitor.ParagraphBlock {
                    viewItems.append(.text(attributedString: convert(paragraphBlock.attributedString)))
                }

                if let listBlock = block as? MarkdownVisitor.ListBlock {
                    var order = listBlock.startOrder

                    for (itemIndex, itemBlock) in listBlock.itemBlocks.enumerated() {
                        let prefix = order.map { "\($0)." } ?? "•"
                        let prefixAttributedString = MarkdownAttributedStringConverter.attributedString(
                            string: prefix,
                            font: configuration.fonts.body,
                            color: configuration.colors.body
                        )

                        for (paragraphIndex, paragraphBlock) in itemBlock.paragraphBlocks.enumerated() {
                            viewItems.append(.listItem(
                                attributedString: convert(paragraphBlock.attributedString),
                                prefix: paragraphIndex == 0 ? prefixAttributedString : nil,
                                tightTop: listBlock.tight && itemIndex != 0,
                                tightBottom: listBlock.tight && itemIndex != listBlock.itemBlocks.count - 1
                            ))
                        }

                        order? += 1
                    }
                }

                if let blockQuoteBlock = block as? MarkdownVisitor.BlockQuoteBlock {
                    for (paragraphIndex, paragraphBlock) in blockQuoteBlock.paragraphBlocks.enumerated() {
                        viewItems.append(.blockQuote(
                            attributedString: convert(paragraphBlock.attributedString),
                            tightTop: paragraphIndex != 0,
                            tightBottom: paragraphIndex != blockQuoteBlock.paragraphBlocks.count - 1
                        ))
                    }
                }

                if let imageBlock = block as? MarkdownVisitor.ImageBlock, let urlString = imageBlock.url, let imageUrl = URL(string: urlString, relativeTo: url) {
                    var type: MarkdownImageType = .square

                    if let letter = imageUrl.deletingPathExtension().lastPathComponent.split(separator: "-").last {
                        if letter == "l" {
                            type = .landscape
                        } else if letter == "p" {
                            type = .portrait
                        }
                    }

                    viewItems.append(.image(url: imageUrl, type: type, tight: blockIndex == 0))

                    if let title = imageBlock.title {
                        viewItems.append(.imageTitle(text: title))
                    }
                }
            }

            return viewItems
        } catch {
            return []
        }
    }

    private static func convert(_ nsAttributedString: NSAttributedString) -> AttributedString {
        MarkdownAttributedStringConverter.attributedString(from: nsAttributedString)
    }
}
