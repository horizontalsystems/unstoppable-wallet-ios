import Foundation

class BlockHeaderItemValidator {
    static let shared = BlockHeaderItemValidator()

    func filterValidItems(initialHash: Data, items: [BlockHeaderItem]) -> [BlockHeaderItem] {
        var validItems = [BlockHeaderItem]()

        for item in items {
            let previousHash = validItems.last.map { Crypto.sha256sha256($0.serialized()) } ?? initialHash

            if previousHash == item.prevBlock {
                validItems.append(item)
            } else {
                break
            }
        }

        return validItems
    }

}
