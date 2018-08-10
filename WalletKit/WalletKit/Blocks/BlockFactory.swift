import Foundation

class BlockFactory {

    func block(withHeader header: BlockHeader, previousBlock: Block) -> Block {
        let block = self.block(withHeader: header)
        block.height = previousBlock.height + 1
        block.previousBlock = previousBlock
        return block
    }

    func block(withHeader header: BlockHeader, height: Int) -> Block {
        let block = self.block(withHeader: header)
        block.height = height
        return block
    }

    func blocks(fromHeaders headers: [BlockHeader], initialBlock: Block) -> [Block] {
        var blocks = [Block]()
        var previousBlock = initialBlock

        for header in headers {
            let block = self.block(withHeader: header, previousBlock: previousBlock)
            blocks.append(block)

            previousBlock = block
        }

        return blocks
    }

    private func block(withHeader header: BlockHeader) -> Block {
        let block = Block()

        block.header = header
        block.headerHash = Crypto.sha256sha256(header.serialized())
        block.reversedHeaderHashHex = block.headerHash.reversedHex

        return block
    }

}
