import UIKit
import ThemeKit
import Down

class MarkdownParser {

    func viewItems(content: String, url: URL?, configuration: DownStylerConfiguration) -> [MarkdownBlockViewItem] {
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

//            print(block)
//            print(document.accept(DebugVisitor()))

            guard let documentBlock = block as? MarkdownVisitor.DocumentBlock else {
                return []
            }

            var viewItems = [MarkdownBlockViewItem]()

            for (blockIndex, block) in documentBlock.blocks.enumerated() {
                if let headingBlock = block as? MarkdownVisitor.HeadingBlock {
                    viewItems.append(.header(attributedString: headingBlock.attributedString, level: headingBlock.level))
                }

                if let paragraphBlock = block as? MarkdownVisitor.ParagraphBlock {
                    viewItems.append(.text(attributedString: paragraphBlock.attributedString))
                }

                if let listBlock = block as? MarkdownVisitor.ListBlock {
                    var order = listBlock.startOrder

                    for (itemIndex, itemBlock) in listBlock.itemBlocks.enumerated() {
                        let prefix = order.map { "\($0)." } ?? "•"

                        for (paragraphIndex, paragraphBlock) in itemBlock.paragraphBlocks.enumerated() {
                            viewItems.append(.listItem(
                                    attributedString: paragraphBlock.attributedString,
                                    prefix: paragraphIndex == 0 ? prefix : nil,
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
                                attributedString: paragraphBlock.attributedString,
                                tightTop: paragraphIndex != 0,
                                tightBottom: paragraphIndex != blockQuoteBlock.paragraphBlocks.count - 1
                        ))
                    }
                }

                if let imageBlock = block as? MarkdownVisitor.ImageBlock, let urlString = imageBlock.url, let url = URL(string: urlString, relativeTo: url) {
                    var type: MarkdownImageType = .square

                    if let letter = url.deletingPathExtension().lastPathComponent.split(separator: "-").last {
                        if letter == "l" {
                            type = .landscape
                        } else if letter == "p" {
                            type = .portrait
                        }
                    }

                    viewItems.append(.image(url: url, type: type, tight: blockIndex == 0))

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

}
