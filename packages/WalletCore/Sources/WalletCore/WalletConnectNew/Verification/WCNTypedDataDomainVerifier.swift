import WalletConnectUtils

class WCNTypedDataDomainVerifier: IWCNVerifier {
    func handles(_ context: WCNVerificationContext) -> Bool {
        (context.parsed as? IWCNTypedDataRequest)?.typedDataDomain != nil
    }

    func verify(_ context: WCNVerificationContext) -> WCNVerificationVerdict {
        guard let chainId = (context.parsed as? IWCNTypedDataRequest)?.typedDataDomain?.chainId else {
            return .caution(reason: "Typed data domain has no chainId, signature is replayable across chains")
        }

        let namespace = context.parsed.chainId.namespace
        let approved = context.approvedAccounts.contains { $0.namespace == namespace && $0.reference == String(chainId) }
        return approved ? .pass : .block(reason: "Typed data domain chainId \(chainId) is not approved")
    }
}
