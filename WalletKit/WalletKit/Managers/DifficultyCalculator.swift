import Foundation
import BigInt

class DifficultyCalculator {
    static let shared = DifficultyCalculator()

    private let maxTargetBits: UInt32 = 0x1d00ffff                   // Maximum difficulty.
    var maxTargetDifficulty: BigInt { return difficultyEncoder.decodeCompact(bits: maxTargetBits) }

    private let targetTimeSpan: Int = 14 * 24 * 60 * 60      // 2 weeks per difficulty cycle, on average.
    let targetSpacing: Int = 10 * 60                         // 10 minutes per block.
    let heightInterval: Int

    let difficultyEncoder: DifficultyEncoder

    init(difficultyEncoder: DifficultyEncoder = .shared) {
        self.difficultyEncoder = difficultyEncoder
        heightInterval = targetTimeSpan / targetSpacing
    }

    private func limit(timeSpan: Int) -> Int {
        return min(max(timeSpan, targetTimeSpan / 4), targetTimeSpan * 4)
    }

    func difficultyAfter(header: BlockHeader, checkPointBlock: Block, height: Int) -> UInt32 {
//        let checkPointItem = BlockHeaderItem.deserialize(byteStream: ByteStream(checkPointBlock.rawHeader))
//        let timeSpan = limit(timeSpan: Int(item.timestamp - checkPointItem.timestamp))
//
//        var bigIntDifficulty = difficultyEncoder.decodeCompact(bits: item.bits)
//        bigIntDifficulty *= BigInt(timeSpan)
//        bigIntDifficulty /= BigInt(targetTimeSpan)
//        let newDifficulty = min(difficultyEncoder.encodeCompact(from: bigIntDifficulty), maxTargetBits)
//
//        return UInt32(newDifficulty)
        return 0
    }

}
