import Foundation
import BigInt

class TestNetBlockHeaderItemValidator: BlockHeaderItemValidator {
    private static let testNetDiffDate = 1329264000 // February 16th 2012

    override func validate(block: Block) throws {
        guard let blockHeader = block.header else {
            throw HeaderValidatorError.noHeader
        }
        guard let previousBlock = block.previousBlock, let previousHeader = previousBlock.header else {
            throw HeaderValidatorError.noPreviousBlock
        }
        if !isDifficultyTransitionPoint(height: previousBlock.height), previousHeader.timestamp > TestNetBlockHeaderItemValidator.testNetDiffDate {
            try validateHash(block: block)

            let timeDelta = blockHeader.timestamp - previousHeader.timestamp
            if timeDelta >= 0, timeDelta <= difficultyCalculator.targetSpacing * 2 {
                var cursorBlock = previousBlock
                let maxDifficulty = difficultyCalculator.maxTargetDifficulty

                while cursorBlock.height != 0 && !isDifficultyTransitionPoint(height: cursorBlock.height) && difficultyCalculator.difficultyEncoder.decodeCompact(bits: cursorBlock.header?.bits ?? 0) == maxDifficulty {
                    guard let previousBlock = cursorBlock.previousBlock else {
                        throw HeaderValidatorError.noPreviousBlock
                    }
                    cursorBlock = previousBlock
                }
                let cursorDifficulty = difficultyCalculator.difficultyEncoder.decodeCompact(bits: cursorBlock.header?.bits ?? 0)
                let itemDifficulty = difficultyCalculator.difficultyEncoder.decodeCompact(bits: block.header?.bits ?? 0)

                if cursorDifficulty != itemDifficulty {
                    throw HeaderValidatorError.notEqualBits
                }
            }
        } else {
            try super.validate(block: block)
        }
    }

}
