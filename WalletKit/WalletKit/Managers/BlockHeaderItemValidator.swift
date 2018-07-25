import Foundation
import BigInt

class BlockHeaderItemValidator {
    enum HeaderValidatorError: Error {
        case noCheckpointBlock
        case noPreviousBlock
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
        try validateHash(item: item, previousItem: previousItem)

        if isDifficultyTransitionPoint(height: previousHeight) {
            try validateDifficultyTransition(item: item, previousItem: previousItem, previousHeight: previousHeight)
        } else if item.bits != previousItem.bits {
            throw HeaderValidatorError.notEqualBits
        }
    }

    func validateHash(item: BlockHeaderItem, previousItem: BlockHeaderItem) throws {
        guard item.prevBlock == Crypto.sha256sha256(previousItem.serialized()) else {
            throw HeaderValidatorError.wrongPreviousHeaderHash
        }
    }

    func validateDifficultyTransition(item: BlockHeaderItem, previousItem: BlockHeaderItem, previousHeight: Int) throws {
        let realm = realmFactory.realm

        guard let lastBlock = realm.objects(Block.self).filter("height = %@", previousHeight - 2015).last else {
            throw HeaderValidatorError.noCheckpointBlock
        }

        if difficultyCalculator.difficultyAfter(item: previousItem, checkPointBlock: lastBlock, height: previousHeight) != item.bits {
            throw HeaderValidatorError.notDifficultyTransitionEqualBits
        }
    }

    func isDifficultyTransitionPoint(height: Int) -> Bool {
        return (height + 1) % difficultyCalculator.heightInterval == 0
    }

}
