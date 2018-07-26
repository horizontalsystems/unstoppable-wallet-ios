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

    func validate(block: Block) throws {
//        try validateHash(header: header, previousHeader: previousHeader)
//
//        if isDifficultyTransitionPoint(height: previousHeight) {
//            try validateDifficultyTransition(header: header, previousHeader: previousHeader, previousHeight: previousHeight)
//        } else if header.bits != previousHeader.bits {
//            throw HeaderValidatorError.notEqualBits
//        }
    }

//    func validateHash(header: BlockHeader, previousHeader: BlockHeader) throws {
//        guard header.previousBlockHeaderHash == Crypto.sha256sha256(previousHeader.serialized()) else {
//            throw HeaderValidatorError.wrongPreviousHeaderHash
//        }
//    }
//
//    func validateDifficultyTransition(header: BlockHeader, previousHeader: BlockHeader, previousHeight: Int) throws {
//        let realm = realmFactory.realm
//
//        guard let lastBlock = realm.objects(Block.self).filter("height = %@", previousHeight - 2015).last else {
//            throw HeaderValidatorError.noCheckpointBlock
//        }
//
//        if difficultyCalculator.difficultyAfter(header: previousHeader, checkPointBlock: lastBlock, height: previousHeight) != header.bits {
//            throw HeaderValidatorError.notDifficultyTransitionEqualBits
//        }
//    }

    func isDifficultyTransitionPoint(height: Int) -> Bool {
        return (height + 1) % difficultyCalculator.heightInterval == 0
    }

}
