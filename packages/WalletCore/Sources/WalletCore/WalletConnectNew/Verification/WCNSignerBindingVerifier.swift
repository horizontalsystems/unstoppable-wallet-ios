import WalletConnectUtils

// Bug-bounty #2 defense-in-depth: request.from must be an account approved for the exact request chain
class WCNSignerBindingVerifier: IWCNVerifier {
    private let requireSigner: Bool

    init(requireSigner: Bool = true) {
        self.requireSigner = requireSigner
    }

    func handles(_ context: WCNVerificationContext) -> Bool {
        context.parsed.kind != .direct
    }

    func verify(_ context: WCNVerificationContext) -> WCNVerificationVerdict {
        guard let from = context.parsed.from else {
            return requireSigner ? .block(reason: "Request does not specify the signing address") : .pass
        }

        guard let signer = try? WalletConnectUtils.Account(blockchain: context.parsed.chainId, accountAddress: from) else {
            return .block(reason: "Signing address is malformed")
        }

        let approved = context.approvedAccounts.contains {
            $0.blockchainIdentifier == signer.blockchainIdentifier && $0.address.lowercased() == signer.address.lowercased()
        }
        return approved ? .pass : .block(reason: "Signing address is not approved for \(context.parsed.chainId.absoluteString)")
    }
}
