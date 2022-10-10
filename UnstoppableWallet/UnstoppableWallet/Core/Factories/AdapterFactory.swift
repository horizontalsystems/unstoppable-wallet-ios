import BitcoinCore
import RxSwift
import RxRelay
import EvmKit
import MarketKit

class AdapterFactory {
    private let appConfigProvider: AppConfigProvider
    private let evmBlockchainManager: EvmBlockchainManager
    private let evmSyncSourceManager: EvmSyncSourceManager
    private let binanceKitManager: BinanceKitManager
    private let btcBlockchainManager: BtcBlockchainManager
    private let restoreSettingsManager: RestoreSettingsManager
    private let coinManager: CoinManager
    private let evmLabelManager: EvmLabelManager

    init(appConfigProvider: AppConfigProvider, evmBlockchainManager: EvmBlockchainManager, evmSyncSourceManager: EvmSyncSourceManager, binanceKitManager: BinanceKitManager, btcBlockchainManager: BtcBlockchainManager, restoreSettingsManager: RestoreSettingsManager, coinManager: CoinManager, evmLabelManager: EvmLabelManager) {
        self.appConfigProvider = appConfigProvider
        self.evmBlockchainManager = evmBlockchainManager
        self.evmSyncSourceManager = evmSyncSourceManager
        self.binanceKitManager = binanceKitManager
        self.btcBlockchainManager = btcBlockchainManager
        self.restoreSettingsManager = restoreSettingsManager
        self.coinManager = coinManager
        self.evmLabelManager = evmLabelManager
    }

    private func evmAdapter(wallet: Wallet) -> IAdapter? {
        guard let blockchainType = evmBlockchainManager.blockchain(token: wallet.token)?.type else {
            return nil
        }
        guard let evmKitWrapper = try? evmBlockchainManager.evmKitManager(blockchainType: blockchainType).evmKitWrapper(account: wallet.account, blockchainType: blockchainType) else {
            return nil
        }

        return EvmAdapter(evmKitWrapper: evmKitWrapper)
    }

    private func eip20Adapter(address: String, wallet: Wallet, coinManager: CoinManager) -> IAdapter? {
        guard let blockchainType = evmBlockchainManager.blockchain(token: wallet.token)?.type else {
            return nil
        }
        guard let evmKitWrapper = try? evmBlockchainManager.evmKitManager(blockchainType: blockchainType).evmKitWrapper(account: wallet.account, blockchainType: blockchainType) else {
            return nil
        }
        guard let baseToken = evmBlockchainManager.baseToken(blockchainType: blockchainType) else {
            return nil
        }

        return try? Eip20Adapter(evmKitWrapper: evmKitWrapper, contractAddress: address, wallet: wallet, baseToken: baseToken, coinManager: coinManager, evmLabelManager: evmLabelManager)
    }

}

extension AdapterFactory {

    func evmTransactionsAdapter(transactionSource: TransactionSource) -> ITransactionsAdapter? {
        let blockchainType = transactionSource.blockchainType

        if let evmKitWrapper = evmBlockchainManager.evmKitManager(blockchainType: blockchainType).evmKitWrapper,
           let baseToken = evmBlockchainManager.baseToken(blockchainType: blockchainType) {
            let syncSource = evmSyncSourceManager.syncSource(blockchainType: blockchainType)
            return EvmTransactionsAdapter(evmKitWrapper: evmKitWrapper, source: transactionSource, baseToken: baseToken, evmTransactionSource: syncSource.transactionSource, coinManager: coinManager, evmLabelManager: evmLabelManager)
        }

        return nil
    }

    func adapter(wallet: Wallet) -> IAdapter? {
        switch (wallet.token.type, wallet.token.blockchain.type) {

        case (.native, .bitcoin):
            let syncMode = btcBlockchainManager.syncMode(blockchainType: .bitcoin, accountOrigin: wallet.account.origin)
            return try? BitcoinAdapter(wallet: wallet, syncMode: syncMode, testMode: appConfigProvider.testMode)

        case (.native, .bitcoinCash):
            let syncMode = btcBlockchainManager.syncMode(blockchainType: .bitcoinCash, accountOrigin: wallet.account.origin)
            return try? BitcoinCashAdapter(wallet: wallet, syncMode: syncMode, testMode: appConfigProvider.testMode)

        case (.native, .litecoin):
            let syncMode = btcBlockchainManager.syncMode(blockchainType: .litecoin, accountOrigin: wallet.account.origin)
            return try? LitecoinAdapter(wallet: wallet, syncMode: syncMode, testMode: appConfigProvider.testMode)

        case (.native, .dash):
            let syncMode = btcBlockchainManager.syncMode(blockchainType: .dash, accountOrigin: wallet.account.origin)
            return try? DashAdapter(wallet: wallet, syncMode: syncMode, testMode: appConfigProvider.testMode)

        case (.native, .zcash):
            let restoreSettings = restoreSettingsManager.settings(account: wallet.account, blockchainType: .zcash)
            return try? ZcashAdapter(wallet: wallet, restoreSettings: restoreSettings, testMode: appConfigProvider.testMode)

        case (.native, .binanceChain), (.bep2, .binanceChain):
            let query = TokenQuery(blockchainType: .binanceChain, tokenType: .native)
            if let binanceKit = try? binanceKitManager.binanceKit(account: wallet.account), let feeToken = try? coinManager.token(query: query) {
                return BinanceAdapter(binanceKit: binanceKit, feeToken: feeToken, wallet: wallet)
            }

        case (.native, .ethereum), (.native, .binanceSmartChain), (.native, .polygon), (.native, .avalanche), (.native, .optimism), (.native, .arbitrumOne):
            return evmAdapter(wallet: wallet)

        case (.eip20(let address), .ethereum), (.eip20(let address), .binanceSmartChain), (.eip20(let address), .polygon), (.eip20(let address), .avalanche), (.eip20(let address), .optimism), (.eip20(let address), .arbitrumOne):
            return eip20Adapter(address: address, wallet: wallet, coinManager: coinManager)

        default: ()
        }

        return nil
    }

}
