import EvmKit

protocol IWCEvmSignerProvider: AnyObject {
    func signer(chainId: Int) -> EvmKit.Signer?
}

class WCEvmSignerProvider: IWCEvmSignerProvider {
    private let evmBlockchainManager: EvmBlockchainManager
    private let accountManager: AccountManager

    init(evmBlockchainManager: EvmBlockchainManager, accountManager: AccountManager) {
        self.evmBlockchainManager = evmBlockchainManager
        self.accountManager = accountManager
    }

    func signer(chainId: Int) -> EvmKit.Signer? {
        accountManager.activeAccount.flatMap { evmBlockchainManager.kitWrapper(chainId: chainId, account: $0)?.signer }
    }
}
