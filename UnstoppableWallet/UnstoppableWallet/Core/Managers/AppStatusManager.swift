import Foundation
import CoinKit

class AppStatusManager {
    private let systemInfoManager: ISystemInfoManager
    private let storage: IAppVersionStorage
    private let logRecordManager: ILogRecordManager
    private let accountManager: IAccountManager
    private let walletManager: IWalletManager
    private let ethereumKitManager: EvmKitManager
    private let binanceSmartChainKitManager: EvmKitManager
    private let binanceKitManager: BinanceKitManager
    private let restoreSettingsManager: RestoreSettingsManager

    init(systemInfoManager: ISystemInfoManager, storage: IAppVersionStorage, accountManager: IAccountManager,
         walletManager: IWalletManager, ethereumKitManager: EvmKitManager, binanceSmartChainKitManager: EvmKitManager,
         binanceKitManager: BinanceKitManager, logRecordManager: ILogRecordManager, restoreSettingsManager: RestoreSettingsManager) {
        self.systemInfoManager = systemInfoManager
        self.storage = storage
        self.accountManager = accountManager
        self.walletManager = walletManager
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

        var ethereumStatus: [(String, Any)]?
        var binanceSmartChainStatus: [(String, Any)]?
        var binanceStatus: [(String, Any)]?

        for activeWallet in walletManager.activeWallets {
            switch activeWallet.wallet.coin.type {
            case .ethereum, .erc20:
                if ethereumStatus == nil {
                    ethereumStatus = activeWallet.statusInfo
                }
            case .binanceSmartChain, .bep20:
                if binanceSmartChainStatus == nil {
                    binanceSmartChainStatus = activeWallet.statusInfo
                }
            case .bep2:
                if binanceStatus == nil {
                    binanceStatus = activeWallet.statusInfo
                }
            default:
                status.append((activeWallet.wallet.coin.title, activeWallet.statusInfo))
            }
        }

        if let ethereumStatus = ethereumStatus {
            status.append(("Ethereum", ethereumStatus))
        }
        if let binanceSmartChainStatus = binanceSmartChainStatus {
            status.append(("Binance Smart Chain", binanceSmartChainStatus))
        }
        if let binanceStatus = binanceStatus {
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
