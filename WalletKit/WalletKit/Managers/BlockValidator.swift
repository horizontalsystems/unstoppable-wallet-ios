import Foundation
import BigInt

class BlockValidator {

    enum ValidatorError: Error {
        case noCheckpointBlock
        case noPreviousBlock
        case wrongPreviousHeaderHash
        case notEqualBits
        case notDifficultyTransitionEqualBits
    }

    let calculator: DifficultyCalculator

    init(calculator: DifficultyCalculator = .shared) {
        self.calculator = calculator
    }

    func validate(block: Block) throws {
        try validateHash(block: block)

        if isDifficultyTransitionPoint(height: block.height) {
            try validateDifficultyTransition(block: block)
        } else if block.header.bits != block.previousBlock?.header.bits {
            throw ValidatorError.notEqualBits
        }
    }

    func validateHash(block: Block) throws {
        guard let previousBlock = block.previousBlock else {
            throw ValidatorError.noPreviousBlock
        }

        guard block.header.previousBlockHeaderHash == previousBlock.headerHash else {
            throw ValidatorError.wrongPreviousHeaderHash
        }
    }

    func validateDifficultyTransition(block: Block) throws {
        var lastCheckPointBlock = block

        for i in 0..<2016 {
            if let block = lastCheckPointBlock.previousBlock {
                lastCheckPointBlock = block
            } else {
                throw i == 2015 ? ValidatorError.noCheckpointBlock : ValidatorError.noPreviousBlock
            }
        }

        guard let previousBlock = block.previousBlock else {
            throw ValidatorError.noPreviousBlock
        }
        if try calculator.difficultyAfter(block: previousBlock, lastCheckPointBlock: lastCheckPointBlock) != block.header.bits {
            throw ValidatorError.notDifficultyTransitionEqualBits
        }
    }

    func isDifficultyTransitionPoint(height: Int) -> Bool {
        return (height) % calculator.heightInterval == 0
    }

}
