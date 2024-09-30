import Combine
import Foundation
import HdWalletKit
import MarketKit
import TonKit
import TonSwift
import TweetNacl

class TonKitManager {
    private let restoreStateManager: RestoreStateManager
    private let marketKit: MarketKit.Kit
    private let walletManager: WalletManager
    private var jettonBalanceCancellable: AnyCancellable?
    private var eventCancellable: AnyCancellable?

    private weak var _tonKit: TonKit.Kit?
    private var currentAccount: Account?

    private let queue = DispatchQueue(label: "\(AppConfig.label).ton-kit-manager", qos: .userInitiated)

    init(restoreStateManager: RestoreStateManager, marketKit: MarketKit.Kit, walletManager: WalletManager) {
        self.restoreStateManager = restoreStateManager
        self.walletManager = walletManager
        self.marketKit = marketKit
    }

    private func _tonKit(account: Account) throws -> TonKit.Kit {
        if let _tonKit, let currentAccount, currentAccount == account {
            return _tonKit
        }

        let address: TonSwift.Address

        switch account.type {
        case .mnemonic:
            let (publicKey, _) = try Self.keyPair(accountType: account.type)
            let contract = Self.contract(publicKey: publicKey)
            address = try contract.address()
        case let .tonAddress(_address):
            address = try TonSwift.Address.parse(_address)
        default:
            throw AdapterError.unsupportedAccount
        }

        let tonKit = try TonKit.Kit.instance(
            address: address,
            network: .mainNet,
            walletId: account.id,
            minLogLevel: .error
        )

        tonKit.sync()
        tonKit.startListener()

        _tonKit = tonKit
        currentAccount = account

        subscribe(tonKit: tonKit, account: account)

        return tonKit
    }

    private func subscribe(tonKit: TonKit.Kit, account: Account) {
        let restoreState = restoreStateManager.restoreState(account: account, blockchainType: .ton)

        // print("RESTORE STATE: shouldRestore: \(restoreState.shouldRestore), initialRestored: \(restoreState.initialRestored)")

        if restoreState.shouldRestore || account.watchAccount, !restoreState.initialRestored {
            jettonBalanceCancellable = tonKit.jettonBalanceMapPublisher
                .sink { [weak self, restoreStateManager] in
                    self?.handle(jettons: $0.values.map { $0.jetton }, account: account)

                    restoreStateManager.setInitialRestored(account: account, blockchainType: .ton)

                    self?.jettonBalanceCancellable?.cancel()
                    self?.jettonBalanceCancellable = nil
                }
        }

        let address = tonKit.receiveAddress

        eventCancellable = tonKit.eventPublisher(tagQuery: .init())
            .sink { [weak self] in self?.handle(events: $0.events, initial: $0.initial, address: address, account: account) }
    }

    private func handle(events: [Event], initial: Bool, address: TonSwift.Address, account: Account) {
        guard !initial else {
            // print("ignore initial events: \(events.count)")
            return
        }

        // print("HANDLE EVENTS: \(events.count)")

        var jettons = Set<Jetton>()

        for event in events {
            for action in event.actions {
                switch action.type {
                case let .jettonTransfer(action):
                    if action.recipient?.address == address {
                        jettons.insert(action.jetton)
                    }
                case let .jettonMint(action):
                    if action.recipient.address == address {
                        jettons.insert(action.jetton)
                    }
                case let .jettonSwap(action):
                    if let jetton = action.jettonMasterIn {
                        jettons.insert(jetton)
                    }
                default: ()
                }
            }
        }

        handle(jettons: Array(jettons), account: account)
    }

    private func handle(jettons: [Jetton], account: Account) {
        // print("HANDLE JETTONS: \(jettons.map { $0.name })")

        guard !jettons.isEmpty else {
            return
        }

        let existingWallets = walletManager.activeWallets
        let existingTokenTypeIds = existingWallets.map(\.token.type.id)
        let newJettons = jettons.filter { !existingTokenTypeIds.contains($0.tokenType.id) }

        // print("new jettons: \(newJettons.map { $0.name })")

        guard !newJettons.isEmpty else {
            return
        }

        let enabledWallets = newJettons.map { jetton in
            EnabledWallet(
                tokenQueryId: TokenQuery(blockchainType: .ton, tokenType: jetton.tokenType).id,
                accountId: account.id,
                coinName: jetton.name,
                coinCode: jetton.symbol,
                coinImage: jetton.image,
                tokenDecimals: jetton.decimals
            )
        }

        walletManager.save(enabledWallets: enabledWallets)
    }
}

extension TonKitManager {
    var tonKit: TonKit.Kit? {
        queue.sync { _tonKit }
    }

    func tonKit(account: Account) throws -> TonKit.Kit {
        try queue.sync { try _tonKit(account: account) }
    }
}

extension TonKitManager {
    static func contract(publicKey: Data) -> WalletContract {
        WalletV4R2(publicKey: publicKey)
    }

    static func keyPair(accountType: AccountType) throws -> (publicKey: Data, secretKey: Data) {
        guard let seed = accountType.mnemonicSeed else {
            throw AdapterError.unsupportedAccount
        }

        let hdWallet = HDWallet(seed: seed, coinType: 607, xPrivKey: 0, curve: .ed25519)
        let privateKey = try hdWallet.privateKey(account: 0)
        let privateRaw = Data(privateKey.raw.bytes)
        return try TweetNacl.NaclSign.KeyPair.keyPair(fromSeed: privateRaw)
    }
}

extension Jetton {
    var tokenType: TokenType {
        .jetton(address: address.toString(bounceable: true))
    }
}
