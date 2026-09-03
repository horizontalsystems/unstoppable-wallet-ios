import WalletConnectUtils

class WCNEvmOneInchRouterVerifier: IWCNVerifier {
    private let routerProvider: IWCNSwapRouterProvider

    init(routerProvider: IWCNSwapRouterProvider) {
        self.routerProvider = routerProvider
    }

    func handles(_ context: WCNVerificationContext) -> Bool {
        context.parsed.chainId.namespace == WCNNamespace.eip155 && context.parsed.kind == .transaction && context.parsed.decodedSwapInfo?.provider == .oneInch
    }

    func verify(_ context: WCNVerificationContext) -> WCNVerificationVerdict {
        guard let router = routerProvider.routerAddress(provider: .oneInch, chainId: context.parsed.chainId) else {
            return .block(reason: "1inch is not supported on \(context.parsed.chainId.absoluteString)")
        }

        guard let to = context.parsed.to, to.lowercased() == router.lowercased() else {
            return .block(reason: "1inch swap is not addressed to the canonical router")
        }

        return .pass
    }
}
