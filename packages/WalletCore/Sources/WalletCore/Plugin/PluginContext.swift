import MarketKit

/// The generic managers a plugin may depend on while bootstrapping. Carries no account storage and no secret material.
public final class PluginContext {
    let marketKit: MarketKit.Kit
    let walletManager: WalletManager
    let coinManager: CoinManager
    let restoreStateManager: RestoreStateManager
    let restoreSettingsManager: RestoreSettingsManager
    let testNetManager: TestNetManager
    let blockchainSettingsStorage: BlockchainSettingsStorage
    let spamWrapper: SpamWrapper

    init(
        marketKit: MarketKit.Kit, walletManager: WalletManager, coinManager: CoinManager, restoreStateManager: RestoreStateManager,
        restoreSettingsManager: RestoreSettingsManager, testNetManager: TestNetManager, blockchainSettingsStorage: BlockchainSettingsStorage,
        spamWrapper: SpamWrapper
    ) {
        self.marketKit = marketKit
        self.walletManager = walletManager
        self.coinManager = coinManager
        self.restoreStateManager = restoreStateManager
        self.restoreSettingsManager = restoreSettingsManager
        self.testNetManager = testNetManager
        self.blockchainSettingsStorage = blockchainSettingsStorage
        self.spamWrapper = spamWrapper
    }
}
