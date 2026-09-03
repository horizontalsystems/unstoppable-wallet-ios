import BigInt

// Bug-bounty #4: a token swap must not carry native value hidden behind the swap decoration
class WCNSwapNativeValueVerifier: IWCNVerifier {
    func handles(_ context: WCNVerificationContext) -> Bool {
        context.parsed.kind == .transaction && context.parsed.decodedSwapInfo != nil
    }

    func verify(_ context: WCNVerificationContext) -> WCNVerificationVerdict {
        guard let swapInfo = context.parsed.decodedSwapInfo, let value = context.parsed.value else {
            return .pass
        }

        if !swapInfo.tokenInIsNative, value > 0 {
            return .block(reason: "Token swap carries native value")
        }

        return .pass
    }
}
