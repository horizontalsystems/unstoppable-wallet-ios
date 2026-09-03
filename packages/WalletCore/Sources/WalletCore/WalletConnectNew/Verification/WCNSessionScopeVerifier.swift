import WalletConnectUtils

class WCNSessionScopeVerifier: IWCNVerifier {
    func handles(_: WCNVerificationContext) -> Bool {
        true
    }

    func verify(_ context: WCNVerificationContext) -> WCNVerificationVerdict {
        let chainId = context.payload.chainId.absoluteString
        let inScope = context.approvedAccounts.contains { $0.blockchainIdentifier == chainId }

        return inScope ? .pass : .block(reason: .chainNotInSession(chain: chainId))
    }
}
