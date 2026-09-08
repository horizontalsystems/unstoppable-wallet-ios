import WalletConnectUtils

class WCSessionScopeVerifier: IWCVerifier {
    func handles(_: WCVerificationContext) -> Bool {
        true
    }

    func verify(_ context: WCVerificationContext) -> WCVerificationVerdict {
        let chainId = context.payload.chainId.absoluteString
        let inScope = context.approvedAccounts.contains { $0.blockchainIdentifier == chainId }

        return inScope ? .pass : .block(reason: .chainNotInSession(chain: chainId))
    }
}
