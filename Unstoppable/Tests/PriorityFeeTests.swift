import EvmKit
import Testing
@testable import WalletCore

struct PriorityFeeTests {
    private func gasPrice(baseFee: [Int] = [100], ratio: [Double], reward: [[Int]], priority: EIP1559GasPriceProvider.Priority) throws -> GasPrice {
        try EIP1559GasPriceProvider.gasPrice(baseFeePerGas: baseFee, gasUsedRatio: ratio, reward: reward, priority: priority)
    }

    private func tip(_ gasPrice: GasPrice) -> Int? {
        if case let .eip1559(_, tip) = gasPrice {
            return tip
        }
        return nil
    }

    // MARK: EIP-1559 priority

    @Test func standardPriorityKeepsMeanFormula() throws {
        let result = try gasPrice(baseFee: [100, 200, 160], ratio: [0.5, 0, 0.3], reward: [[10], [0], [20]], priority: .standard)

        // tip = (10 + 0 + 20) / 3, zero-ratio row included; max fee = max(200, 160) * 125 / 100 + tip
        #expect(result == .eip1559(maxFeePerGas: 260, maxPriorityFeePerGas: 10))
    }

    @Test func highPriorityUsesMedianOddCount() throws {
        let result = try gasPrice(ratio: [0.5, 0.5, 0.5], reward: [[10, 30], [10, 50], [10, 40]], priority: .high)

        #expect(result == .eip1559(maxFeePerGas: 165, maxPriorityFeePerGas: 40))
    }

    @Test func highPriorityUsesMedianEvenCount() throws {
        let result = try gasPrice(ratio: [0.5, 0.5, 0.5, 0.5], reward: [[10, 30], [10, 50], [10, 40], [10, 60]], priority: .high)

        #expect(tip(result) == 45)
    }

    @Test func medianOfNearMaxRewardsDoesNotOverflow() throws {
        // Base fee 0 keeps the max fee equal to the tip, so only the median arithmetic is exercised
        let result = try gasPrice(baseFee: [0], ratio: [0.5, 0.5], reward: [[1, Int.max], [1, Int.max - 2]], priority: .high)

        #expect(tip(result) == Int.max - 1)
    }

    @Test func zeroRatioBlockExcludedFromMedianIncludedInMean() throws {
        let ratio = [0.5, 0, 0.5, 0.5]
        let reward = [[20, 30], [0, 0], [20, 40], [20, 50]]

        // Median of 30, 40, 50 (the zero-ratio block would make it 35)
        #expect(try tip(gasPrice(ratio: ratio, reward: reward, priority: .high)) == 40)
        // Mean of 20, 0, 20, 20 (the zero-ratio block is counted)
        #expect(try tip(gasPrice(ratio: ratio, reward: reward, priority: .standard)) == 15)
    }

    @Test func outlierDoesNotMoveMedian() throws {
        let ratio = [0.5, 0.5, 0.5, 0.5, 0.5]
        let withOutlier = try gasPrice(ratio: ratio, reward: [[10, 30], [10, 40], [10, 50], [10, 45], [10, 10000]], priority: .high)
        let withoutOutlier = try gasPrice(ratio: ratio, reward: [[10, 30], [10, 40], [10, 50], [10, 45], [10, 46]], priority: .high)

        #expect(tip(withOutlier) == 45)
        #expect(withOutlier == withoutOutlier)
    }

    @Test func highTipIsFlooredAtStandardTip() throws {
        // Standard mean = (10 + 10 + 100) / 3 = 40; priority median = 20
        let result = try gasPrice(ratio: [0.5, 0.5, 0.5], reward: [[10, 20], [10, 20], [100, 200]], priority: .high)

        #expect(tip(result) == 40)
    }

    @Test func allZeroRatiosFallBackToStandardTip() throws {
        let result = try gasPrice(ratio: [0, 0, 0], reward: [[10, 30], [20, 50], [30, 40]], priority: .high)

        #expect(tip(result) == 20)
    }

    @Test func rowsWithoutHighColumnFallBackToStandardTip() throws {
        let result = try gasPrice(ratio: [0.5, 0.5], reward: [[10], [30]], priority: .high)

        #expect(tip(result) == 20)
    }

    @Test func emptyRewardThrows() {
        #expect(throws: EIP1559GasPriceProvider.FeeHistoryError.notAvailable) {
            try gasPrice(ratio: [], reward: [], priority: .high)
        }
        #expect(throws: EIP1559GasPriceProvider.FeeHistoryError.notAvailable) {
            try gasPrice(ratio: [], reward: [], priority: .standard)
        }
    }

    @Test func emptyBaseFeeThrows() {
        #expect(throws: EIP1559GasPriceProvider.FeeHistoryError.notAvailable) {
            try gasPrice(baseFee: [], ratio: [0.5], reward: [[10, 20]], priority: .high)
        }
        #expect(throws: EIP1559GasPriceProvider.FeeHistoryError.notAvailable) {
            try gasPrice(baseFee: [], ratio: [0.5], reward: [[10]], priority: .standard)
        }
    }

    @Test func baseFeeHeadroomIsSameForBothPriorities() throws {
        let baseFee = [1000, 1200, 1100]
        let ratio = [0.5, 0.5, 0.5]
        let reward = [[10, 30], [20, 50], [30, 40]]

        let standard = try gasPrice(baseFee: baseFee, ratio: ratio, reward: reward, priority: .standard)
        let priority = try gasPrice(baseFee: baseFee, ratio: ratio, reward: reward, priority: .high)

        guard case let .eip1559(standardMax, standardTip) = standard, case let .eip1559(priorityMax, priorityTip) = priority else {
            Issue.record("Expected EIP-1559 gas prices")
            return
        }

        #expect(priorityTip > standardTip)
        #expect(standardMax - standardTip == priorityMax - priorityTip)
    }

    // MARK: EvmTransactionService

    @Test func prioritizedLegacy() {
        #expect(EvmTransactionService.prioritizedLegacy(gasPrice: .legacy(gasPrice: 100), feePriority: .standard) == .legacy(gasPrice: 100))
        #expect(EvmTransactionService.prioritizedLegacy(gasPrice: .legacy(gasPrice: 100), feePriority: .priority) == .legacy(gasPrice: 120))
        #expect(EvmTransactionService.prioritizedLegacy(gasPrice: .legacy(gasPrice: 1), feePriority: .priority) == .legacy(gasPrice: 2))
        // Scaling would overflow: the price is returned unscaled instead of trapping
        #expect(EvmTransactionService.prioritizedLegacy(gasPrice: .legacy(gasPrice: Int.max / 100), feePriority: .priority) == .legacy(gasPrice: Int.max / 100))

        let eip1559 = GasPrice.eip1559(maxFeePerGas: 200, maxPriorityFeePerGas: 10)
        #expect(EvmTransactionService.prioritizedLegacy(gasPrice: eip1559, feePriority: .priority) == eip1559)
    }

    @Test func eip1559Priority() {
        #expect(EvmTransactionService.eip1559Priority(feePriority: .standard) == .standard)
        #expect(EvmTransactionService.eip1559Priority(feePriority: .priority) == .high)
    }

    // MARK: Bitcoin

    @Test func bitcoinRecommendedRate() {
        #expect(BitcoinFeeRateProvider.recommendedRate(fastest: 20, halfHour: 10) == 20)
        #expect(BitcoinFeeRateProvider.recommendedRate(fastest: 0, halfHour: 10) == 10)
        #expect(BitcoinFeeRateProvider.recommendedRate(fastest: 8, halfHour: 10) == 10)
    }
}
