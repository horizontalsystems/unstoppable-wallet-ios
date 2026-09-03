import WalletConnectSign

protocol IWCNSwapRouterProvider: AnyObject {
    func routerAddress(provider: WCNSwapInfo.Provider, chainId: Blockchain) -> String?
}
