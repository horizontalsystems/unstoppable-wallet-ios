import Foundation

class AppStatusManager {
    static let statusBitcoinCoreTypes: [CoinType] = [.bitcoin, .litecoin, .bitcoinCash, .dash]

    private let systemInfoManager: ISystemInfoManager
    private let localStorage: ILocalStorage
    private let logRecordManager: ILogRecordManager
    private let predefinedAccountTypeManager: IPredefinedAccountTypeManager
    private let walletManager: IWalletManager
    private let adapterManager: IAdapterManager
    private let ethereumKitManager: EthereumKitManager
    private let binanceKitManager: BinanceKitManager

    init(systemInfoManager: ISystemInfoManager, localStorage: ILocalStorage, predefinedAccountTypeManager: IPredefinedAccountTypeManager,
         walletManager: IWalletManager, adapterManager: IAdapterManager, ethereumKitManager: EthereumKitManager,
         binanceKitManager: BinanceKitManager, logRecordManager: ILogRecordManager) {
        self.systemInfoManager = systemInfoManager
        self.localStorage = localStorage
        self.predefinedAccountTypeManager = predefinedAccountTypeManager
        self.walletManager = walletManager
        self.adapterManager = adapterManager
        self.ethereumKitManager = ethereumKitManager
        self.binanceKitManager = binanceKitManager
        self.logRecordManager = logRecordManager
    }

    private var accountStatus: [(String, Any)] {
        predefinedAccountTypeManager.allTypes.compactMap {
            guard let account = predefinedAccountTypeManager.account(predefinedAccountType: $0) else {
                return nil
            }

            var status = [(String, Any)]()

            status.append(("origin", "\(account.origin)"))

            if case let .mnemonic(words, _) = account.type {
                status.append(("type", "mnemonic (\(words.count) words)"))
            }
            if case let .zcash(words, birthdayHeight) = account.type {
                status.append(("type", "Zcash (\(words.count) words) : \(birthdayHeight?.description  ?? "N/A") birthday"))
            }

            return ($0.title, status)
        }
    }

    private var blockchainStatus: [(String, Any)] {
        var status = [(String, Any)]()

        let bitcoinBaseWallets = AppStatusManager.statusBitcoinCoreTypes.compactMap { coinType in
            walletManager.wallets.first { $0.coin.type == coinType }
        }
        status.append(contentsOf: bitcoinBaseWallets.compactMap {
            guard let adapter = adapterManager.adapter(for: $0) as? BitcoinBaseAdapter else {
                return nil
            }
            return ($0.coin.title, adapter.statusInfo)
        })

        if let ethereumStatus = ethereumKitManager.statusInfo {
            status.append(("Ethereum", ethereumStatus))
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
                ("App Version", systemInfoManager.appVersion),
                ("Phone Model", systemInfoManager.deviceModel),
                ("OS Version", systemInfoManager.osVersion)
            ]),
            ("App Log", logRecordManager.logsGroupedBy(context: "Send")),
            ("Version History", localStorage.appVersions.map { ($0.version, $0.date) }),
            ("Wallets Status", accountStatus),
            ("Blockchains Status", blockchainStatus)
        ]
    }

}
