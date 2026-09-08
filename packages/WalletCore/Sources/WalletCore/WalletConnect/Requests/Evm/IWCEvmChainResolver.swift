protocol IWCEvmChainResolver: AnyObject {
    func isKnown(chainId: Int) -> Bool
}

class WCEvmChainResolver: IWCEvmChainResolver {
    private let evmBlockchainManager: EvmBlockchainManager

    init(evmBlockchainManager: EvmBlockchainManager) {
        self.evmBlockchainManager = evmBlockchainManager
    }

    func isKnown(chainId: Int) -> Bool {
        evmBlockchainManager.blockchain(chainId: chainId) != nil
    }
}
