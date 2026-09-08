import WalletConnectSign

protocol IWCSwapRouterProvider: AnyObject {
    func routerAddress(provider: WCSwapInfo.Provider, chainId: Blockchain) -> String?
}
