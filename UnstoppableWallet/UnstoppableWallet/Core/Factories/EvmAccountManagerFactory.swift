import Foundation
import MarketKit

class EvmAccountManagerFactory {
    private let accountManager: AccountManager
    private let walletManager: WalletManager
    private let evmAccountRestoreStateManager: EvmAccountRestoreStateManager
    private let marketKit: MarketKit.Kit

    init(accountManager: AccountManager, walletManager: WalletManager, evmAccountRestoreStateManager: EvmAccountRestoreStateManager, marketKit: MarketKit.Kit) {
        self.accountManager = accountManager
        self.walletManager = walletManager
        self.evmAccountRestoreStateManager = evmAccountRestoreStateManager
        self.marketKit = marketKit
    }

}

extension EvmAccountManagerFactory {

    func evmAccountManager(blockchainType: BlockchainType, evmKitManager: EvmKitManager) -> EvmAccountManager {
        EvmAccountManager(
                blockchainType: blockchainType,
                accountManager: accountManager,
                walletManager: walletManager,
                marketKit: marketKit,
                evmKitManager: evmKitManager,
                evmAccountRestoreStateManager: evmAccountRestoreStateManager
        )
    }

}
