import Foundation

class AppStatusManager {
    static let statusBitcoinCoreIds = ["BTC", "BCH", "DASH"]

    private let systemInfoManager: ISystemInfoManager
    private let localStorage: ILocalStorage
    private let predefinedAccountTypeManager: IPredefinedAccountTypeManager
    private let walletManager: IWalletManager
    private let adapterManager: IAdapterManager
    private let ethereumKitManager: EthereumKitManager
    private let eosKitManager: EosKitManager
    private let binanceKitManager: BinanceKitManager

    init(systemInfoManager: ISystemInfoManager, localStorage: ILocalStorage, predefinedAccountTypeManager: IPredefinedAccountTypeManager, walletManager: IWalletManager, adapterManager: IAdapterManager, ethereumKitManager: EthereumKitManager, eosKitManager: EosKitManager, binanceKitManager: BinanceKitManager) {
        self.systemInfoManager = systemInfoManager
        self.localStorage = localStorage
        self.predefinedAccountTypeManager = predefinedAccountTypeManager
        self.walletManager = walletManager
        self.adapterManager = adapterManager
        self.ethereumKitManager = ethereumKitManager
        self.eosKitManager = eosKitManager
        self.binanceKitManager = binanceKitManager
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
            if case let .eos(account, _) = account.type {
                status.append(("name", account))
            }

            return ($0.title, status)
        }
    }

    private var blockchainStatus: [(String, Any)] {
        var status = [(String, Any)]()

        let bitcoinBaseWallets = AppStatusManager.statusBitcoinCoreIds.compactMap { coinId in
            walletManager.wallets.first { $0.coin.id == coinId }
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
        if let eosStatus = eosKitManager.statusInfo {
            status.append(("EOS", eosStatus))
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
            ("Version History", localStorage.appVersions.map { ($0.version, $0.date) }),
            ("Wallets Status", accountStatus),
            ("Blockchains Status", blockchainStatus)
        ]
    }

}
