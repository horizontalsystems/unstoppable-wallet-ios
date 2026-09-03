import BigInt

// Bug-bounty #4: a token swap must not carry native value hidden behind the swap decoration
class WCNSwapNativeValueVerifier: IWCNVerifier {
    func handles(_ context: WCNVerificationContext) -> Bool {
        context.payload.kind == .transaction && context.payload.decodedSwapInfo != nil
    }

    func verify(_ context: WCNVerificationContext) -> WCNVerificationVerdict {
        guard let swapInfo = context.payload.decodedSwapInfo, let value = context.payload.value else {
            return .pass
        }

        if !swapInfo.tokenInIsNative, value > 0 {
            return .block(reason: .tokenSwapCarriesNativeValue)
        }

        return .pass
    }
}
