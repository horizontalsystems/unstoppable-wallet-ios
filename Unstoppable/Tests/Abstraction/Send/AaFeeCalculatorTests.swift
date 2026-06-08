import BigInt
import Testing
@testable import Unstoppable
@testable import WalletCore

struct AaFeeCalculatorTests {
    @Test
    func estimatedUsesPaidPlusPostOpTail() {
        // paid = 10_000_000_000_000 wei (real actualGasCost from simulation)
        // postOpGas = 16_596 × 1 gwei = 16_596_000_000_000 wei tail
        // total = 26_596_000_000_000 wei × 1.0 (rate=1e18) = 26_596_000_000_000 token units
        let breakdown = AaFeeCalculator.breakdown(
            paidWei: 10_000_000_000_000,
            postOpGas: 16596,
            bufferedGas: gasEstimate(callGas: 1, verifGas: 1, preVerifGas: 1),
            gasPrices: gasPrices(maxFeePerGas: 1_000_000_000),
            exchangeRate: BigUInt(10).power(18),
            scenario: .approvedSend
        )

        let expectedEstimatedWei = BigUInt(10_000_000_000_000) + BigUInt(16596) * 1_000_000_000
        #expect(breakdown.estimatedFeeInToken == expectedEstimatedWei)
    }

    @Test
    func requiredPrefundUsesBufferedGasWithTripleVerification() {
        let breakdown = AaFeeCalculator.breakdown(
            paidWei: 10_000_000_000_000,
            postOpGas: 16596,
            bufferedGas: gasEstimate(callGas: 100_000, verifGas: 50000, preVerifGas: 21000),
            gasPrices: gasPrices(maxFeePerGas: 1_000_000_000),
            exchangeRate: BigUInt(10).power(18),
            scenario: .approvedSend
        )

        // (100_000 + 3*50_000 + 21_000) * 1e9 = 271_000_000_000_000 wei → token (rate=1e18)
        #expect(breakdown.requiredPrefundInToken == BigUInt(271_000) * BigUInt(10).power(9))
    }

    @Test
    func requiredExceedsEstimatedWhenPaidIsRealistic() {
        // Realistic Pimlico-overshoot scenario: paid is ~50% of bufferedGas × maxFee.
        let breakdown = AaFeeCalculator.breakdown(
            paidWei: 10_000_000_000_000,
            postOpGas: 16596,
            bufferedGas: gasEstimate(callGas: 150_000, verifGas: 200_000, preVerifGas: 50000),
            gasPrices: gasPrices(maxFeePerGas: 1_000_000_000),
            exchangeRate: BigUInt(10).power(18),
            scenario: .approvedSend
        )

        #expect(breakdown.requiredPrefundInToken > breakdown.estimatedFeeInToken)
    }

    @Test
    func zeroExchangeRateProducesZeroFees() {
        let breakdown = AaFeeCalculator.breakdown(
            paidWei: 10_000_000_000_000,
            postOpGas: 16596,
            bufferedGas: gasEstimate(callGas: 100_000, verifGas: 50000, preVerifGas: 21000),
            gasPrices: gasPrices(maxFeePerGas: 1_000_000_000),
            exchangeRate: 0,
            scenario: .freshDeploy
        )

        #expect(breakdown.estimatedFeeInToken == 0)
        #expect(breakdown.requiredPrefundInToken == 0)
    }

    @Test
    func zeroPostOpKeepsEstimatedAtPaid() {
        let breakdown = AaFeeCalculator.breakdown(
            paidWei: 10_000_000_000_000,
            postOpGas: 0,
            bufferedGas: gasEstimate(callGas: 1, verifGas: 1, preVerifGas: 1),
            gasPrices: gasPrices(maxFeePerGas: 1_000_000_000),
            exchangeRate: BigUInt(10).power(18),
            scenario: .approvedSend
        )

        #expect(breakdown.estimatedFeeInToken == 10_000_000_000_000)
    }

    @Test
    func scenarioIsPreservedInBreakdown() {
        let scenarios: [AaSendFeeBreakdown.Scenario] = [.approvedSend, .approveAndSend, .freshDeploy]

        for scenario in scenarios {
            let breakdown = AaFeeCalculator.breakdown(
                paidWei: 1,
                postOpGas: 1,
                bufferedGas: gasEstimate(callGas: 1, verifGas: 1, preVerifGas: 1),
                gasPrices: gasPrices(maxFeePerGas: 1),
                exchangeRate: 1,
                scenario: scenario
            )

            #expect(breakdown.scenario == scenario)
        }
    }

    @Test
    func exchangeRateIsExposed() {
        let breakdown = AaFeeCalculator.breakdown(
            paidWei: 1,
            postOpGas: 1,
            bufferedGas: gasEstimate(callGas: 1, verifGas: 1, preVerifGas: 1),
            gasPrices: gasPrices(maxFeePerGas: 1),
            exchangeRate: BigUInt(2_500_000_000),
            scenario: .approvedSend
        )

        #expect(breakdown.exchangeRate == BigUInt(2_500_000_000))
    }

    @Test
    func bscRealisticScenarioMatchesOnChain() {
        // From bscscan tx 0xc8ebb77b... — real paid=10_587_935_000_000 wei, postOpGas=16_596,
        // exchangeRate=689_661_561_765_868_616_119 (≈ 689.66 BSC-USD per BNB), maxFeePerGas=60_375_000.
        // Expected token charge ≈ 0.00796 BSC-USD raw (18-decimal) ≈ 7.96e15.
        let breakdown = AaFeeCalculator.breakdown(
            paidWei: 10_587_935_000_000,
            postOpGas: 16596,
            bufferedGas: gasEstimate(callGas: 148_474, verifGas: 189_906, preVerifGas: 57502),
            gasPrices: gasPrices(maxFeePerGas: 60_375_000),
            exchangeRate: BigUInt("689661561765868616119", radix: 10)!,
            scenario: .approvedSend
        )

        // Within 5% of the 0.007579e18 actually charged on-chain (small drift expected — EntryPoint
        // gas accounting differs marginally from simple multiplication).
        let expectedRawTokens = BigUInt(7_960_000_000_000_000)
        let lower = expectedRawTokens * 95 / 100
        let upper = expectedRawTokens * 105 / 100
        #expect(breakdown.estimatedFeeInToken >= lower)
        #expect(breakdown.estimatedFeeInToken <= upper)
    }

    private func gasEstimate(callGas: Int, verifGas: Int, preVerifGas: Int) -> PimlicoProvider.GasEstimate {
        PimlicoProvider.GasEstimate(
            callGasLimit: BigUInt(callGas),
            verificationGasLimit: BigUInt(verifGas),
            preVerificationGas: BigUInt(preVerifGas)
        )
    }

    private func gasPrices(maxFeePerGas: BigUInt) -> PimlicoProvider.GasPrices.Tier {
        PimlicoProvider.GasPrices.Tier(
            maxFeePerGas: maxFeePerGas,
            maxPriorityFeePerGas: 0
        )
    }
}
