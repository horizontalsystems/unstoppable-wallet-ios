import Foundation
import MarketKit

class AppStatusManager {
    private let systemInfoManager: SystemInfoManager
    private let storage: AppVersionStorage
    private let logRecordManager: LogRecordManager
    private let accountManager: AccountManager
    private let walletManager: WalletManager
    private let adapterManager: AdapterManager
    private let restoreSettingsManager: RestoreSettingsManager
    private let evmBlockchainManager: EvmBlockchainManager
    private let binanceKitManager: BinanceKitManager
    private let marketKit: MarketKit.Kit

    init(systemInfoManager: SystemInfoManager, storage: AppVersionStorage, accountManager: AccountManager,
         walletManager: WalletManager, adapterManager: AdapterManager, logRecordManager: LogRecordManager, restoreSettingsManager: RestoreSettingsManager,
         evmBlockchainManager: EvmBlockchainManager, binanceKitManager: BinanceKitManager, marketKit: MarketKit.Kit) {
        self.systemInfoManager = systemInfoManager
        self.storage = storage
        self.accountManager = accountManager
        self.walletManager = walletManager
        self.adapterManager = adapterManager
        self.logRecordManager = logRecordManager
        self.restoreSettingsManager = restoreSettingsManager
        self.evmBlockchainManager = evmBlockchainManager
        self.binanceKitManager = binanceKitManager
        self.marketKit = marketKit
    }

    private var marketLastSyncTimestamps: [(String, Any)] {
        let syncInfo = marketKit.syncInfo()

        return [
            ("Coins", syncInfo.coinsTimestamp ?? "nil"),
            ("Blockchains", syncInfo.blockchainsTimestamp ?? "nil"),
            ("Tokens", syncInfo.tokensTimestamp ?? "nil")
        ]
    }

    private var accountStatus: [(String, Any)] {
        accountManager.accounts.compactMap { account in
            var status = [(String, Any)]()

            status.append(("origin", "\(account.origin)"))

            if case let .mnemonic(words, salt) = account.type {
                status.append(("type", "mnemonic (\(words.count) words\(salt.isEmpty ? "" : " with passphrase"))"))
            }

            let restoreSettingsInfo = restoreSettingsManager.accountSettingsInfo(account: account)

            if !restoreSettingsInfo.isEmpty {
                var restoreSettings = [(String, Any)]()

                for info in restoreSettingsInfo {
                    let coinType = info.0
                    let settingType = info.1
                    let value = info.2.isEmpty ? "not set" : info.2
                    restoreSettings.append(("\(coinType) - \(settingType)", "\(value)"))
                }

                status.append(("Restore Settings", restoreSettings))
            }

            return (account.name, status)
        }
    }

    private var blockchainStatus: [(String, Any)] {
        var status = [(String, Any)]()

        for wallet in walletManager.activeWallets {
            let blockchain = wallet.token.blockchain

            switch blockchain.type {
            case .bitcoin, .bitcoinCash, .litecoin, .dash, .zcash:
                if let adapter = adapterManager.adapter(for: wallet) {
                    status.append((blockchain.name, adapter.statusInfo))
                }
            default:
                ()
            }
        }

        for blockchain in evmBlockchainManager.allBlockchains {
            if let evmKitWrapper = evmBlockchainManager.evmKitManager(blockchainType: blockchain.type).evmKitWrapper {
                status.append((blockchain.name, evmKitWrapper.evmKit.statusInfo()))
            }
        }

        if let binanceKit = binanceKitManager.binanceKit {
            status.append(("Binance Chain", binanceKit.statusInfo))
        }

        return status
    }

}

extension AppStatusManager {

    var status: [(String, Any)] {
        [
            ("App Info", [
                ("Current Time", Date()),
                ("App Version", systemInfoManager.appVersion.description),
                ("Phone Model", systemInfoManager.deviceModel),
                ("OS Version", systemInfoManager.osVersion)
            ]),
            ("App Log", logRecordManager.logsGroupedBy(context: "Send")),
            ("Version History", storage.appVersions.map { ($0.description, $0.date) }),
            ("Market Last Sync Timestamps", marketLastSyncTimestamps),
            ("Wallets Status", accountStatus),
            ("Blockchains Status", blockchainStatus)
        ]
    }

}
