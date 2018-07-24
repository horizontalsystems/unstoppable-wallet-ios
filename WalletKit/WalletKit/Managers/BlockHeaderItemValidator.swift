import Foundation
import BigInt

class BlockHeaderItemValidator {
    static let shared = BlockHeaderItemValidator()

    enum HeaderValidatorError: Error {
        case noCheckpointBlock
        case wrongPreviousHeaderHash
        case notEqualBits
        case notDifficultyTransitionEqualBits
    }

    let realmFactory: RealmFactory
    let difficultyCalculator: DifficultyCalculator

    init(realmFactory: RealmFactory = .shared, difficultyCalculator: DifficultyCalculator = .shared) {
        self.realmFactory = realmFactory
        self.difficultyCalculator = difficultyCalculator
    }

    func validate(item: BlockHeaderItem, previousItem: BlockHeaderItem, previousHeight: Int) throws {
        guard item.prevBlock == Crypto.sha256sha256(previousItem.serialized()) else {
            throw HeaderValidatorError.wrongPreviousHeaderHash
        }

        if isDifficultyTransitionPoint(height: previousHeight) {
            let realm = realmFactory.realm

            guard let lastBlock = realm.objects(Block.self).filter("height = %@", previousHeight - 2015).last else {
                throw HeaderValidatorError.noCheckpointBlock
            }

            if difficultyCalculator.difficultyAfter(item: previousItem, checkPointBlock: lastBlock, height: previousHeight) != item.bits {
                throw HeaderValidatorError.notDifficultyTransitionEqualBits
            }
        } else if item.bits != previousItem.bits {
            throw HeaderValidatorError.notEqualBits
        }
    }

    private func isDifficultyTransitionPoint(height: Int) -> Bool {
        return (height + 1) % DifficultyCalculator.shared.heightInterval == 0
    }

}
