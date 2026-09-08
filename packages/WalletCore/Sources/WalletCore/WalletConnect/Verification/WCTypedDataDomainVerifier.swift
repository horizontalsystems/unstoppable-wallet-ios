import WalletConnectUtils

class WCTypedDataDomainVerifier: IWCVerifier {
    func handles(_ context: WCVerificationContext) -> Bool {
        (context.payload as? IWCTypedDataRequest)?.typedDataDomain != nil
    }

    func verify(_ context: WCVerificationContext) -> WCVerificationVerdict {
        guard let chainId = (context.payload as? IWCTypedDataRequest)?.typedDataDomain?.chainId else {
            return .caution(reason: .typedDataDomainWithoutChain)
        }

        let namespace = context.payload.chainId.namespace
        let approved = context.approvedAccounts.contains { $0.namespace == namespace && $0.reference == String(chainId) }
        return approved ? .pass : .block(reason: .typedDataDomainChainNotApproved(chainId: chainId))
    }
}
