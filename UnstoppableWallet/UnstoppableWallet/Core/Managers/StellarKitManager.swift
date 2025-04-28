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
    private var jettonBalanceCancellable: AnyCancellable?
    private var eventCancellable: AnyCancellable?

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
        case let .mnemonic(words, salt, _):
            let keyPair = try Self.keyPair(accountType: account.type)
            accountId = keyPair.accountId
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

        return stellarKit
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
