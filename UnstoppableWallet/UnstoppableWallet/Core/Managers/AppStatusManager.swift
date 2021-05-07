import Foundation
import CoinKit

class AppStatusManager {
    static let statusBitcoinCoreTypes: [CoinType] = [.bitcoin, .litecoin, .bitcoinCash, .dash]

    private let systemInfoManager: ISystemInfoManager
    private let storage: IAppVersionStorage
    private let logRecordManager: ILogRecordManager
    private let accountManager: IAccountManager
    private let walletManager: IWalletManager
    private let adapterManager: IAdapterManager
    private let ethereumKitManager: EthereumKitManager
    private let binanceSmartChainKitManager: BinanceSmartChainKitManager
    private let binanceKitManager: BinanceKitManager
    private let restoreSettingsManager: RestoreSettingsManager

    init(systemInfoManager: ISystemInfoManager, storage: IAppVersionStorage, accountManager: IAccountManager,
         walletManager: IWalletManager, adapterManager: IAdapterManager, ethereumKitManager: EthereumKitManager, binanceSmartChainKitManager: BinanceSmartChainKitManager,
         binanceKitManager: BinanceKitManager, logRecordManager: ILogRecordManager, restoreSettingsManager: RestoreSettingsManager) {
        self.systemInfoManager = systemInfoManager
        self.storage = storage
        self.accountManager = accountManager
        self.walletManager = walletManager
        self.adapterManager = adapterManager
        self.ethereumKitManager = ethereumKitManager
        self.binanceSmartChainKitManager = binanceSmartChainKitManager
        self.binanceKitManager = binanceKitManager
        self.logRecordManager = logRecordManager
        self.restoreSettingsManager = restoreSettingsManager
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

        let bitcoinBaseWallets = walletManager.activeWallets.filter { AppStatusManager.statusBitcoinCoreTypes.contains($0.coin.type) }

        status.append(contentsOf: bitcoinBaseWallets.compactMap {
            guard let adapter = adapterManager.adapter(for: $0) as? BitcoinBaseAdapter else {
                return nil
            }
            return ($0.coin.title, adapter.statusInfo)
        })

        if let ethereumStatus = ethereumKitManager.statusInfo {
            status.append(("Ethereum", ethereumStatus))
        }
        if let binanceSmartChainStatus = binanceSmartChainKitManager.statusInfo {
            status.append(("Binance Smart Chain", binanceSmartChainStatus))
        }
        if let binanceStatus = binanceKitManager.statusInfo {
            status.append(("Binance", binanceStatus))
        }

        return status
    }

}

extension AppStatusManager: IAppStatusManager {

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
            ("Wallets Status", accountStatus),
            ("Blockchains Status", blockchainStatus)
        ]
    }

}
