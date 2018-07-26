import Foundation
import BigInt

class TestNetBlockHeaderItemValidator: BlockHeaderItemValidator {
    private static let testNetDiffDate = 1329264000 // February 16th 2012

//    override func validate(item: BlockHeaderItem, previousItem: BlockHeaderItem, previousHeight: Int) throws {
//        if !isDifficultyTransitionPoint(height: previousHeight), item.timestamp > TestNetBlockHeaderItemValidator.testNetDiffDate {
//            try validateHash(item: item, previousItem: previousItem)
//
//            let timeDelta = item.timestamp - previousItem.timestamp
//            if timeDelta >= 0, timeDelta <= difficultyCalculator.targetSpacing * 2 {
//                let realm = realmFactory.realm
//
//                var height = previousHeight
//                var cursorItem = previousItem
//                let maxDifficulty = difficultyCalculator.maxTargetDifficulty
//
//                while height != 0 && !isDifficultyTransitionPoint(height: height - 1) && difficultyCalculator.difficultyEncoder.decodeCompact(bits: cursorItem.bits) == maxDifficulty {
//                    height -= 1
//                    guard let cursorBlock = realm.objects(Block.self).filter("height = %@", height).last else {
//                        throw HeaderValidatorError.noPreviousBlock
//                    }
////                    cursorItem = BlockHeaderItem.deserialize(byteStream: ByteStream(cursorBlock.rawHeader))
//                }
//                let cursorDifficulty = difficultyCalculator.difficultyEncoder.decodeCompact(bits: cursorItem.bits)
//                let itemDifficulty = difficultyCalculator.difficultyEncoder.decodeCompact(bits: item.bits)
//
//                if cursorDifficulty != itemDifficulty {
//                    throw HeaderValidatorError.notEqualBits
//                }
//            }
//        } else {
//            try super.validate(item: item, previousItem: previousItem, previousHeight: previousHeight)
//        }
//    }

}
