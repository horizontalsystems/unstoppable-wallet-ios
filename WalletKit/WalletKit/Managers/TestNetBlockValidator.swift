import Foundation
import BigInt

class TestNetBlockValidator: BlockValidator {
    private static let testNetDiffDate = 1329264000 // February 16th 2012

    override func validate(block: Block) throws {
        guard let previousBlock = block.previousBlock else {
            throw ValidatorError.noPreviousBlock
        }

        if !isDifficultyTransitionPoint(height: block.height), previousBlock.header.timestamp > TestNetBlockValidator.testNetDiffDate {
            try validateHash(block: block)

            let timeDelta = block.header.timestamp - previousBlock.header.timestamp
            if timeDelta >= 0, timeDelta <= calculator.targetSpacing * 2 {
                var cursorBlock = previousBlock
                let maxDifficulty = calculator.maxTargetDifficulty

                while cursorBlock.height != 0 && !isDifficultyTransitionPoint(height: cursorBlock.height) && calculator.difficultyEncoder.decodeCompact(bits: cursorBlock.header.bits) == maxDifficulty {
                    guard let previousBlock = cursorBlock.previousBlock else {
                        throw ValidatorError.noPreviousBlock
                    }
                    cursorBlock = previousBlock
                }
                let cursorDifficulty = calculator.difficultyEncoder.decodeCompact(bits: cursorBlock.header.bits)
                let itemDifficulty = calculator.difficultyEncoder.decodeCompact(bits: block.header.bits)

                if cursorDifficulty != itemDifficulty {
                    throw ValidatorError.notEqualBits
                }
            }
        } else {
            try super.validate(block: block)
        }
    }

}
