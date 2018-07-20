import Foundation

class MerkleBlockValidator {
    static let shared = MerkleBlockValidator()

    func isValid(message: MerkleBlockMessage) -> Bool {
        let blockHeaderItem = message.blockHeaderItem

        return true
    }

}
