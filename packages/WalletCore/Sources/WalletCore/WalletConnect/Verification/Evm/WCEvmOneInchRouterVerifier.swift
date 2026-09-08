import WalletConnectUtils

class WCEvmOneInchRouterVerifier: IWCVerifier {
    private let routerProvider: IWCSwapRouterProvider

    init(routerProvider: IWCSwapRouterProvider) {
        self.routerProvider = routerProvider
    }

    func handles(_ context: WCVerificationContext) -> Bool {
        context.payload.chainId.namespace == WCNamespace.eip155 && context.payload.kind == .transaction && context.payload.decodedSwapInfo?.provider == .oneInch
    }

    func verify(_ context: WCVerificationContext) -> WCVerificationVerdict {
        guard let router = routerProvider.routerAddress(provider: .oneInch, chainId: context.payload.chainId) else {
            return .block(reason: .swapRouterUnsupported(chain: context.payload.chainId.absoluteString))
        }

        guard let to = context.payload.to, to.lowercased() == router.lowercased() else {
            return .block(reason: .swapNotToCanonicalRouter)
        }

        return .pass
    }
}
