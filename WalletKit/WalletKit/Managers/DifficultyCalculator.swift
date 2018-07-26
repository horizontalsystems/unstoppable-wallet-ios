import Foundation
import BigInt

class DifficultyCalculator {
    static let shared = DifficultyCalculator()

    enum DifficultyCalculatorError: Error { case noHeader, noCheckPointHeader }

    private let maxTargetBits: Int = 0x1d00ffff                   // Maximum difficulty.
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

    func difficultyAfter(block: Block, lastCheckPointBlock: Block) throws -> Int {
        guard let item = block.header else {
            throw DifficultyCalculatorError.noHeader
        }
        guard let checkPointItem = lastCheckPointBlock.header else {
            throw DifficultyCalculatorError.noCheckPointHeader
        }

        let timeSpan = limit(timeSpan: item.timestamp - checkPointItem.timestamp)

        var bigIntDifficulty = difficultyEncoder.decodeCompact(bits: item.bits)
        bigIntDifficulty *= BigInt(timeSpan)
        bigIntDifficulty /= BigInt(targetTimeSpan)
        let newDifficulty = min(difficultyEncoder.encodeCompact(from: bigIntDifficulty), maxTargetBits)

        return newDifficulty
    }

}
