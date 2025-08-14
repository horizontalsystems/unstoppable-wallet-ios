import BitcoinCore
import EvmKit
import MarketKit
import RxRelay
import RxSwift
import StellarKit

class AdapterFactory {
    private let evmBlockchainManager: EvmBlockchainManager
    private let evmSyncSourceManager: EvmSyncSourceManager
    private let moneroNodeManager: MoneroNodeManager
    private let btcBlockchainManager: BtcBlockchainManager
    private let tronKitManager: TronKitManager
    private let tonKitManager: TonKitManager
    private let stellarKitManager: StellarKitManager
    private let restoreSettingsManager: RestoreSettingsManager
    private let coinManager: CoinManager
    private let evmLabelManager: EvmLabelManager

    init(evmBlockchainManager: EvmBlockchainManager, evmSyncSourceManager: EvmSyncSourceManager, moneroNodeManager: MoneroNodeManager,
         btcBlockchainManager: BtcBlockchainManager, tronKitManager: TronKitManager, tonKitManager: TonKitManager, stellarKitManager: StellarKitManager,
         restoreSettingsManager: RestoreSettingsManager, coinManager: CoinManager, evmLabelManager: EvmLabelManager)
    {
        self.evmBlockchainManager = evmBlockchainManager
        self.evmSyncSourceManager = evmSyncSourceManager
        self.moneroNodeManager = moneroNodeManager
        self.btcBlockchainManager = btcBlockchainManager
        self.tronKitManager = tronKitManager
        self.tonKitManager = tonKitManager
        self.stellarKitManager = stellarKitManager
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

    private func tronAdapter(wallet: Wallet) -> IAdapter? {
        guard let tronKitWrapper = try? tronKitManager.tronKitWrapper(account: wallet.account) else {
            return nil
        }

        return TronAdapter(tronKitWrapper: tronKitWrapper)
    }

    private func trc20Adapter(address: String, wallet: Wallet) -> IAdapter? {
        guard let tronKitWrapper = try? tronKitManager.tronKitWrapper(account: wallet.account),
              let baseToken = try? coinManager.token(query: .init(blockchainType: .tron, tokenType: .native))
        else {
            return nil
        }

        return try? Trc20Adapter(
            tronKitWrapper: tronKitWrapper,
            contractAddress: address,
            wallet: wallet,
            baseToken: baseToken,
            coinManager: coinManager,
            evmLabelManager: evmLabelManager
        )
    }
}

extension AdapterFactory {
    func evmTransactionsAdapter(transactionSource: TransactionSource) -> ITransactionsAdapter? {
        let blockchainType = transactionSource.blockchainType

        if let evmKitWrapper = evmBlockchainManager.evmKitManager(blockchainType: blockchainType).evmKitWrapper,
           let baseToken = evmBlockchainManager.baseToken(blockchainType: blockchainType)
        {
            let syncSource = evmSyncSourceManager.syncSource(blockchainType: blockchainType)
            return EvmTransactionsAdapter(evmKitWrapper: evmKitWrapper, source: transactionSource, baseToken: baseToken, evmTransactionSource: syncSource.transactionSource, coinManager: coinManager, evmLabelManager: evmLabelManager)
        }

        return nil
    }

    func tronTransactionsAdapter(transactionSource: TransactionSource) -> ITransactionsAdapter? {
        let query = TokenQuery(blockchainType: .tron, tokenType: .native)

        if let tronKitWrapper = tronKitManager.tronKitWrapper, let baseToken = try? coinManager.token(query: query) {
            return TronTransactionsAdapter(tronKitWrapper: tronKitWrapper, source: transactionSource, baseToken: baseToken, coinManager: coinManager, evmLabelManager: evmLabelManager)
        }

        return nil
    }

    func tonTransactionAdapter(transactionSource: TransactionSource) -> ITransactionsAdapter? {
        let query = TokenQuery(blockchainType: .ton, tokenType: .native)

        if let tonKit = tonKitManager.tonKit, let baseToken = try? coinManager.token(query: query) {
            return TonTransactionAdapter(tonKit: tonKit, source: transactionSource, baseToken: baseToken, coinManager: coinManager)
        }

        return nil
    }

    func stellarTransactionAdapter(transactionSource: TransactionSource) -> ITransactionsAdapter? {
        let query = TokenQuery(blockchainType: .stellar, tokenType: .native)

        if let stellarKit = stellarKitManager.stellarKit, let baseToken = try? coinManager.token(query: query) {
            return StellarTransactionAdapter(stellarKit: stellarKit, source: transactionSource, baseToken: baseToken, coinManager: coinManager)
        }

        return nil
    }

    func adapter(wallet: Wallet) -> IAdapter? {
        switch (wallet.token.type, wallet.token.blockchain.type) {
        case (.derived, .bitcoin):
            let syncMode = btcBlockchainManager.syncMode(blockchainType: .bitcoin, accountOrigin: wallet.account.origin)
            return try? BitcoinAdapter(wallet: wallet, syncMode: syncMode)

        case (.addressType, .bitcoinCash):
            let syncMode = btcBlockchainManager.syncMode(blockchainType: .bitcoinCash, accountOrigin: wallet.account.origin)
            return try? BitcoinCashAdapter(wallet: wallet, syncMode: syncMode)

        case (.native, .ecash):
            let syncMode = btcBlockchainManager.syncMode(blockchainType: .ecash, accountOrigin: wallet.account.origin)
            return try? ECashAdapter(wallet: wallet, syncMode: syncMode)

        case (.derived, .litecoin):
            let syncMode = btcBlockchainManager.syncMode(blockchainType: .litecoin, accountOrigin: wallet.account.origin)
            return try? LitecoinAdapter(wallet: wallet, syncMode: syncMode)

        case (.native, .dash):
            let syncMode = btcBlockchainManager.syncMode(blockchainType: .dash, accountOrigin: wallet.account.origin)
            return try? DashAdapter(wallet: wallet, syncMode: syncMode)

        case (.native, .zcash):
            let restoreSettings = restoreSettingsManager.settings(accountId: wallet.account.id, blockchainType: .zcash)
            return try? ZcashAdapter(wallet: wallet, restoreSettings: restoreSettings)

        case (.native, .monero):
            let restoreSettings = restoreSettingsManager.settings(accountId: wallet.account.id, blockchainType: .monero)
            let moneroNode = moneroNodeManager.node(blockchainType: .monero)
            return try? MoneroAdapter(wallet: wallet, restoreSettings: restoreSettings, node: moneroNode.node)

        case (.native, .ethereum), (.native, .binanceSmartChain), (.native, .polygon), (.native, .avalanche), (.native, .optimism), (.native, .arbitrumOne), (.native, .gnosis), (.native, .fantom), (.native, .base), (.native, .zkSync):
            return evmAdapter(wallet: wallet)

        case let (.eip20(address), .ethereum), let (.eip20(address), .binanceSmartChain), let (.eip20(address), .polygon), let (.eip20(address), .avalanche), let (.eip20(address), .optimism), let (.eip20(address), .arbitrumOne), let (.eip20(address), .gnosis), let (.eip20(address), .fantom), let (.eip20(address), .base), let (.eip20(address), .zkSync):
            return eip20Adapter(address: address, wallet: wallet, coinManager: coinManager)

        case (.native, .tron):
            return tronAdapter(wallet: wallet)

        case let (.eip20(address), .tron):
            return trc20Adapter(address: address, wallet: wallet)

        case (.native, .ton):
            if let tonKit = try? tonKitManager.tonKit(account: wallet.account) {
                return TonAdapter(tonKit: tonKit)
            }

        case let (.jetton(address), .ton):
            do {
                let tonKit = try tonKitManager.tonKit(account: wallet.account)
                return try JettonAdapter(tonKit: tonKit, address: address)
            } catch {}

        case (.native, .stellar):
            if let stellarKit = try? stellarKitManager.stellarKit(account: wallet.account) {
                return StellarAdapter(stellarKit: stellarKit, asset: .native)
            }

        case let (.stellar(code, issuer), .stellar):
            if let stellarKit = try? stellarKitManager.stellarKit(account: wallet.account) {
                return StellarAdapter(stellarKit: stellarKit, asset: .asset(code: code, issuer: issuer))
            }

        default: ()
        }

        return nil
    }
}
