import OneInchKit
import WalletConnectUtils

class WCNEvmSwapRouterProvider: IWCNSwapRouterProvider {
    private let evmBlockchainManager: EvmBlockchainManager

    init(evmBlockchainManager: EvmBlockchainManager) {
        self.evmBlockchainManager = evmBlockchainManager
    }

    func routerAddress(provider: WCNSwapInfo.Provider, chainId: WalletConnectUtils.Blockchain) -> String? {
        guard provider == .oneInch, let id = Int(chainId.reference), let chain = evmBlockchainManager.chain(chainId: id) else {
            return nil
        }
        return try? OneInchKit.Kit.routerAddress(chain: chain).eip55
    }
}
