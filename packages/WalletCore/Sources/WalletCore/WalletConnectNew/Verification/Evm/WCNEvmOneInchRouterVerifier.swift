import WalletConnectUtils

class WCNEvmOneInchRouterVerifier: IWCNVerifier {
    private let routerProvider: IWCNSwapRouterProvider

    init(routerProvider: IWCNSwapRouterProvider) {
        self.routerProvider = routerProvider
    }

    func handles(_ context: WCNVerificationContext) -> Bool {
        context.payload.chainId.namespace == WCNNamespace.eip155 && context.payload.kind == .transaction && context.payload.decodedSwapInfo?.provider == .oneInch
    }

    func verify(_ context: WCNVerificationContext) -> WCNVerificationVerdict {
        guard let router = routerProvider.routerAddress(provider: .oneInch, chainId: context.payload.chainId) else {
            return .block(reason: .swapRouterUnsupported(chain: context.payload.chainId.absoluteString))
        }

        guard let to = context.payload.to, to.lowercased() == router.lowercased() else {
            return .block(reason: .swapNotToCanonicalRouter)
        }

        return .pass
    }
}
