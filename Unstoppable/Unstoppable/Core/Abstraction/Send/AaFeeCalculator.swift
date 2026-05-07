import BigInt
import Foundation

/// Two fee numbers for AA UserOps under Pimlico ERC-20 paymaster:
///
///   • `estimatedFeeInToken` — close to what the user actually pays. Built from
///     `paidWei` (real `actualGasCost` from EntryPoint.simulateHandleOp) plus the
///     paymaster postOp tail. Postpaid via `transferFrom` after inclusion.
///
///   • `requiredPrefundInToken` — what EntryPoint reserves and Pimlico checks
///     against allowance. Uses the prefund formula with ×3 verifGas multiplier
///     on the BUFFERED gas limits we'll submit. Larger than estimated by design;
///     the user must hold at least this allowance/balance to pass validation.
enum AaFeeCalculator {
    static func breakdown(
        paidWei: BigUInt,
        postOpGas: BigUInt,
        bufferedGas: PimlicoProvider.GasEstimate,
        gasPrices: PimlicoProvider.GasPrices.Tier,
        exchangeRate: BigUInt,
        scenario: AaSendFeeBreakdown.Scenario
    ) -> AaSendFeeBreakdown {
        let postOpTailWei = postOpGas * gasPrices.maxFeePerGas
        let estimatedWei = paidWei + postOpTailWei

        let prefundGas = bufferedGas.callGasLimit + bufferedGas.verificationGasLimit * 3 + bufferedGas.preVerificationGas
        let prefundWei = prefundGas * gasPrices.maxFeePerGas

        return AaSendFeeBreakdown(
            estimatedFeeInToken: applyExchangeRate(weiAmount: estimatedWei, exchangeRate: exchangeRate),
            requiredPrefundInToken: applyExchangeRate(weiAmount: prefundWei, exchangeRate: exchangeRate),
            exchangeRate: exchangeRate,
            scenario: scenario
        )
    }

    /// Pimlico SingletonPaymaster postOp formula (raw, on-chain):
    ///   tokenCharge_raw = (gasCostWei × exchangeRate) / 1e18
    ///
    /// `exchangeRate` is a fixed-point number signed by Pimlico per UserOp; the token's
    /// decimals are ALREADY baked into it (e.g. BSC-USD with 18 decimals at 691 USDT/BNB
    /// → rate ≈ 6.91e20; Ethereum USDT with 6 decimals at 2500 USDT/ETH → rate ≈ 2.5e9).
    /// The /1e18 is fixed-point scaling, not a decimals conversion. Output is raw token-units
    /// (whatever decimals the destination token has) — display layer applies token.decimals
    /// separately when formatting to a human Decimal.
    private static func applyExchangeRate(weiAmount: BigUInt, exchangeRate: BigUInt) -> BigUInt {
        weiAmount * exchangeRate / BigUInt(10).power(18)
    }
}
