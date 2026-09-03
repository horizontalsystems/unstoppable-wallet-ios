import WalletConnectUtils

class WCNSessionScopeVerifier: IWCNVerifier {
    func handles(_: WCNVerificationContext) -> Bool {
        true
    }

    func verify(_ context: WCNVerificationContext) -> WCNVerificationVerdict {
        let chainId = context.parsed.chainId.absoluteString
        let inScope = context.approvedAccounts.contains { $0.blockchainIdentifier == chainId }

        return inScope ? .pass : .block(reason: "Chain \(chainId) is not part of the approved session")
    }
}
