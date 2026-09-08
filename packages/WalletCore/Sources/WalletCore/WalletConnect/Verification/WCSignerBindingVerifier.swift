import WalletConnectUtils

// Bug-bounty #2 defense-in-depth: request.from must be an account approved for the exact request chain
class WCSignerBindingVerifier: IWCVerifier {
    private let requireSigner: Bool

    init(requireSigner: Bool = true) {
        self.requireSigner = requireSigner
    }

    func handles(_ context: WCVerificationContext) -> Bool {
        context.payload.kind != .direct
    }

    func verify(_ context: WCVerificationContext) -> WCVerificationVerdict {
        guard let from = context.payload.from else {
            return requireSigner ? .block(reason: .missingSigner) : .pass
        }

        guard let signer = try? WalletConnectUtils.Account(blockchain: context.payload.chainId, accountAddress: from) else {
            return .block(reason: .malformedSigner)
        }

        let approved = context.approvedAccounts.contains {
            $0.blockchainIdentifier == signer.blockchainIdentifier && $0.address.lowercased() == signer.address.lowercased()
        }
        return approved ? .pass : .block(reason: .signerNotApproved(chain: context.payload.chainId.absoluteString))
    }
}
