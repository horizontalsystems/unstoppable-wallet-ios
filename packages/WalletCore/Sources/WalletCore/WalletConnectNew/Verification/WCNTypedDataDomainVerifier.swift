import WalletConnectUtils

class WCNTypedDataDomainVerifier: IWCNVerifier {
    func handles(_ context: WCNVerificationContext) -> Bool {
        (context.payload as? IWCNTypedDataRequest)?.typedDataDomain != nil
    }

    func verify(_ context: WCNVerificationContext) -> WCNVerificationVerdict {
        guard let chainId = (context.payload as? IWCNTypedDataRequest)?.typedDataDomain?.chainId else {
            return .caution(reason: .typedDataDomainWithoutChain)
        }

        let namespace = context.payload.chainId.namespace
        let approved = context.approvedAccounts.contains { $0.namespace == namespace && $0.reference == String(chainId) }
        return approved ? .pass : .block(reason: .typedDataDomainChainNotApproved(chainId: chainId))
    }
}
