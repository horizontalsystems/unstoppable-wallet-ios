import Foundation

class AppStatusManager {
    static let statusBitcoinCoreIds = ["BTC", "BCH", "DASH"]

    private let systemInfoManager: ISystemInfoManager
    private let localStorage: ILocalStorage
    private let predefinedAccountTypeManager: IPredefinedAccountTypeManager
    private let walletManager: IWalletManager
    private let adapterManager: IAdapterManager

    init(systemInfoManager: ISystemInfoManager, localStorage: ILocalStorage, predefinedAccountTypeManager: IPredefinedAccountTypeManager, walletManager: IWalletManager, adapterManager: IAdapterManager) {
        self.systemInfoManager = systemInfoManager
        self.localStorage = localStorage
        self.predefinedAccountTypeManager = predefinedAccountTypeManager
        self.walletManager = walletManager
        self.adapterManager = adapterManager
    }

    private var accountStatus: [(String, Any)] {
        predefinedAccountTypeManager.allTypes.compactMap {
            guard let account = predefinedAccountTypeManager.account(predefinedAccountType: $0) else {
                return nil
            }

            var status = [(String, Any)]()

            if case let .mnemonic(words, derivation, _) = account.type {
                status.append(("type", "mnemonic (\(words.count) words)"))
                status.append(("derivation", derivation.rawValue))
            }
            if case let .eos(account, _) = account.type {
                status.append(("name", account))
            }
            if let syncMode = account.defaultSyncMode {
                status.append(("sync mode", syncMode.rawValue))
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
//todo add eth, binance and eos from kit managers

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
