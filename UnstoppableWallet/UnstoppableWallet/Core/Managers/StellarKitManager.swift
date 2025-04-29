import Combine
import Foundation
import HdWalletKit
import MarketKit
import StellarKit
import stellarsdk

class StellarKitManager {
    private let restoreStateManager: RestoreStateManager
    private let marketKit: MarketKit.Kit
    private let walletManager: WalletManager
    private var addedAssetCancellable: AnyCancellable?

    private weak var _stellarKit: StellarKit.Kit?
    private var currentAccount: Account?

    private let queue = DispatchQueue(label: "\(AppConfig.label).stellar-kit-manager", qos: .userInitiated)

    init(restoreStateManager: RestoreStateManager, marketKit: MarketKit.Kit, walletManager: WalletManager) {
        self.restoreStateManager = restoreStateManager
        self.walletManager = walletManager
        self.marketKit = marketKit
    }

    private func _stellarKit(account: Account) throws -> StellarKit.Kit {
        if let _stellarKit, let currentAccount, currentAccount == account {
            return _stellarKit
        }

        let accountId: String

        switch account.type {
        case .mnemonic:
            let keyPair = try Self.keyPair(accountType: account.type)
            accountId = keyPair.accountId
        case let .stellarAccount(_accountId):
            accountId = _accountId
        default:
            throw AdapterError.unsupportedAccount
        }

        let stellarKit = try StellarKit.Kit.instance(
            accountId: accountId,
            testNet: false,
            walletId: account.id,
            minLogLevel: .error
        )

        stellarKit.sync()

        _stellarKit = stellarKit
        currentAccount = account

        subscribe(stellarKit: stellarKit, account: account)

        return stellarKit
    }

    private func subscribe(stellarKit: StellarKit.Kit, account: Account) {
        addedAssetCancellable = stellarKit.addedAssetPublisher
            .sink { [weak self, restoreStateManager] assets in
                let restoreState = restoreStateManager.restoreState(account: account, blockchainType: .stellar)

                // print("RESTORE STATE: shouldRestore: \(restoreState.shouldRestore), initialRestored: \(restoreState.initialRestored)")

                restoreStateManager.setInitialRestored(account: account, blockchainType: .stellar)

                if !restoreState.initialRestored, !restoreState.shouldRestore, !account.watchAccount {
                    return
                }

                self?.handle(assets: assets, account: account)
            }
    }

    private func handle(assets: [StellarKit.Asset], account: Account) {
        // print("HANDLE ASSETS: \(assets.map(\.code))")

        guard !assets.isEmpty else {
            return
        }

        let existingWallets = walletManager.activeWallets
        let existingTokenTypes = existingWallets.map(\.token.type)
        let newAssets = assets.filter { !existingTokenTypes.contains($0.tokenType) }

        // print("NEW ASSETS: \(newAssets.map { $0.code })")

        guard !newAssets.isEmpty else {
            return
        }

        let enabledWallets = newAssets.map { asset in
            EnabledWallet(
                tokenQueryId: TokenQuery(blockchainType: .stellar, tokenType: asset.tokenType).id,
                accountId: account.id,
                coinName: asset.code,
                coinCode: asset.code,
                tokenDecimals: 7
            )
        }

        walletManager.save(enabledWallets: enabledWallets)
    }
}

extension StellarKitManager {
    var stellarKit: StellarKit.Kit? {
        queue.sync { _stellarKit }
    }

    func stellarKit(account: Account) throws -> StellarKit.Kit {
        try queue.sync { try _stellarKit(account: account) }
    }
}

extension StellarKitManager {
    static func keyPair(accountType: AccountType) throws -> KeyPair {
        switch accountType {
        case let .mnemonic(words, salt, _):
            return try WalletUtils.createKeyPair(mnemonic: words.joined(separator: " "), passphrase: salt, index: 0)
        default:
            throw AdapterError.unsupportedAccount
        }
    }
}

extension StellarKit.Asset {
    var tokenType: TokenType {
        switch self {
        case .native: return .native
        case let .asset(code, issuer): return .stellar(code: code, issuer: issuer)
        }
    }
}
