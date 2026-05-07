import Foundation
import MarketKit
import RxSwift
import ZanoKit

class ZanoKitManager {
    private let restoreSettingsManager: RestoreSettingsManager
    private let walletManager: WalletManager
    private let zanoNodeManager: ZanoNodeManager

    private weak var _kit: ZanoKit.Kit?
    private(set) var currentAccount: Account?

    let balancesSubject = PublishSubject<[BalanceInfo]>()
    let transactionsSubject = PublishSubject<[TransactionInfo]>()
    let walletStateSubject = PublishSubject<WalletState>()
    let assetsSubject = PublishSubject<[AssetInfo]>()

    private let queue = DispatchQueue(label: "\(AppConfig.label).zano-kit-manager", qos: .userInitiated)

    init(restoreSettingsManager: RestoreSettingsManager, walletManager: WalletManager, zanoNodeManager: ZanoNodeManager) {
        self.restoreSettingsManager = restoreSettingsManager
        self.walletManager = walletManager
        self.zanoNodeManager = zanoNodeManager
    }

    private func _kit(account: Account) throws -> ZanoKit.Kit {
        if let _kit, let currentAccount, currentAccount == account {
            return _kit
        }

        let restoreSettings = restoreSettingsManager.settings(accountId: account.id, blockchainType: .zano)

        switch account.type {
        case let .mnemonic(words, passphrase, _):
            let creationDate = RestoreHeight.getDate(height: Int64(restoreSettings.birthdayHeight ?? 0))
            let creationTimestamp = UInt64(creationDate.timeIntervalSince1970)
            let logger = Core.shared.logger.scoped(with: "ZanoKit")

            let kit = try ZanoKit.Kit(
                wallet: .bip39(seed: words, passphrase: passphrase, creationTimestamp: creationTimestamp),
                walletId: account.id,
                daemonAddress: zanoNodeManager.node(blockchainType: .zano).url.absoluteString,
                networkType: ZanoAdapter.networkType,
                reachabilityManager: Core.shared.reachabilityManager,
                logger: logger,
                zanoCoreLogLevel: -1
            )
            kit.delegate = self

            _kit = kit
            currentAccount = account

            kit.start()

            return kit

        default:
            throw AdapterError.unsupportedAccount
        }
    }

    private func handle(assets: [AssetInfo]) {
        guard let currentAccount else { return }

        let nonNativeAssets = assets.filter { !$0.isNative }
        guard !nonNativeAssets.isEmpty else { return }

        let existingWallets = walletManager.activeWallets
        let existingTokenTypes = Set(existingWallets.map(\.token.type))

        let newAssets = nonNativeAssets.filter { !existingTokenTypes.contains(.zanoAsset(id: $0.assetId)) }
        guard !newAssets.isEmpty else { return }

        let enabledWallets = newAssets.map { asset in
            EnabledWallet(
                tokenQueryId: TokenQuery(blockchainType: .zano, tokenType: .zanoAsset(id: asset.assetId)).id,
                accountId: currentAccount.id,
                coinName: asset.fullName,
                coinCode: asset.ticker,
                tokenDecimals: asset.decimalPoint
            )
        }

        walletManager.save(enabledWallets: enabledWallets)
    }
}

extension ZanoKitManager {
    var kit: ZanoKit.Kit? {
        _kit
    }

    func kit(account: Account) throws -> ZanoKit.Kit {
        try _kit(account: account)
    }

    func recreateKit() {
        _kit = nil
    }
}

extension ZanoKitManager: ZanoKitDelegate {
    func assetsDidChange(assets: [AssetInfo]) {
        queue.async {
            self.assetsSubject.onNext(assets)
            self.handle(assets: assets)
        }
    }

    func balancesDidChange(balances: [BalanceInfo]) {
        queue.async {
            self.balancesSubject.onNext(balances)
        }
    }

    func transactionsDidChange(transactions: [TransactionInfo]) {
        queue.async {
            self.transactionsSubject.onNext(transactions)
        }
    }

    func walletStateDidChange(state: WalletState) {
        queue.async {
            self.walletStateSubject.onNext(state)
        }
    }
}
