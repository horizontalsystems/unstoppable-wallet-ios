import Foundation

class BlockHeaderItemValidator {
    static let shared = BlockHeaderItemValidator()

    func isValid(item: BlockHeaderItem, previousBlock: BlockHeaderItem) -> Bool {
        return item.prevBlock == Crypto.sha256sha256(previousBlock.serialized())
    }

}
