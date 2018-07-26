import Foundation
import BigInt

class BlockHeaderItemValidator {
    enum HeaderValidatorError: Error {
        case noCheckpointBlock
        case noPreviousBlock
        case noHeader
        case wrongPreviousHeaderHash
        case notEqualBits
        case notDifficultyTransitionEqualBits
    }

    let difficultyCalculator: DifficultyCalculator

    init(difficultyCalculator: DifficultyCalculator = .shared) {
        self.difficultyCalculator = difficultyCalculator
    }

    func validate(block: Block) throws {
        try validateHash(block: block)

        if isDifficultyTransitionPoint(height: block.height) {
            try validateDifficultyTransition(block: block)
        } else if block.header?.bits != block.previousBlock?.header?.bits {
            throw HeaderValidatorError.notEqualBits
        }
    }

    func validateHash(block: Block) throws {
        guard let previousHeader = block.previousBlock?.header else {
            throw HeaderValidatorError.noPreviousBlock
        }

        guard let header = block.header, header.previousBlockHeaderHash == Crypto.sha256sha256(previousHeader.serialized()) else {
            throw HeaderValidatorError.wrongPreviousHeaderHash
        }
    }

    func validateDifficultyTransition(block: Block) throws {
        var lastCheckPointBlock = block

        for i in 0..<2016 {
            if let block = lastCheckPointBlock.previousBlock {
                lastCheckPointBlock = block
            } else {
                throw i == 2015 ? HeaderValidatorError.noCheckpointBlock : HeaderValidatorError.noPreviousBlock
            }
        }

        guard let previousBlock = block.previousBlock else {
            throw HeaderValidatorError.noPreviousBlock
        }
        if try difficultyCalculator.difficultyAfter(block: previousBlock, lastCheckPointBlock: lastCheckPointBlock) != block.header?.bits {
            throw HeaderValidatorError.notDifficultyTransitionEqualBits
        }
    }

    func isDifficultyTransitionPoint(height: Int) -> Bool {
        return (height) % difficultyCalculator.heightInterval == 0
    }

}
