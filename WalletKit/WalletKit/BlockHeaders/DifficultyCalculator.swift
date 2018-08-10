import Foundation
import BigInt

class DifficultyCalculator {
    private let maxTargetBits: Int = 0x1d00ffff                   // Maximum difficulty.
    var maxTargetDifficulty: BigInt { return difficultyEncoder.decodeCompact(bits: maxTargetBits) }

    private let targetTimeSpan: Int = 14 * 24 * 60 * 60      // 2 weeks per difficulty cycle, on average.
    let targetSpacing: Int = 10 * 60                         // 10 minutes per block.
    let heightInterval: Int

    let difficultyEncoder: DifficultyEncoder

    init(difficultyEncoder: DifficultyEncoder) {
        self.difficultyEncoder = difficultyEncoder
        heightInterval = targetTimeSpan / targetSpacing
    }

    private func limit(timeSpan: Int) -> Int {
        return min(max(timeSpan, targetTimeSpan / 4), targetTimeSpan * 4)
    }

    func difficultyAfter(block: Block, lastCheckPointBlock: Block) throws -> Int {
        let timeSpan = limit(timeSpan: block.header.timestamp - lastCheckPointBlock.header.timestamp)

        var bigIntDifficulty = difficultyEncoder.decodeCompact(bits: block.header.bits)
        bigIntDifficulty *= BigInt(timeSpan)
        bigIntDifficulty /= BigInt(targetTimeSpan)
        let newDifficulty = min(difficultyEncoder.encodeCompact(from: bigIntDifficulty), maxTargetBits)

        return newDifficulty
    }

}
