import Foundation

class BlockCreator {
    static let shared = BlockCreator()

    func create(fromHeaders headers: [BlockHeader], initialBlock: Block) -> [Block] {
        var blocks = [Block]()
        var previousBlock = initialBlock

        for header in headers {
            let block = Block(header: header, previousBlock: previousBlock)
            blocks.append(block)

            previousBlock = block
        }

        return blocks
    }

}
