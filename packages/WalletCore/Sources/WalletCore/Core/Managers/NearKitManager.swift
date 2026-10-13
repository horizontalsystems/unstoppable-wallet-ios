import Combine
import Foundation
import MarketKit
import NearKit
import RxRelay
import RxSwift

public class NearKitManager {
    private let restoreStateManager: RestoreStateManager
    private let restoreSettingsManager: RestoreSettingsManager
    private let marketKit: MarketKit.Kit
    private let walletManager: WalletManager
    private let nodeManager: NearNodeManager
    private let testNetManager: TestNetManager

    private var ftBalancesCancellable: AnyCancellable?
    private var cancellables = Set<AnyCancellable>()

    private weak var _nearKit: NearKit.Kit?
    private var currentAccount: Account?
    private var currentAccountId: String?
    private var watchedContractIds = Set<String>()

    private let queue = DispatchQueue(label: "\(AppConfig.label).near-kit-manager", qos: .userInitiated)
    private let kitStoppedRelay = PublishRelay<Void>()

    public init(
        restoreStateManager: RestoreStateManager, restoreSettingsManager: RestoreSettingsManager, marketKit: MarketKit.Kit, walletManager: WalletManager,
        nodeManager: NearNodeManager, testNetManager: TestNetManager
    ) {
        self.restoreStateManager = restoreStateManager
        self.restoreSettingsManager = restoreSettingsManager
        self.marketKit = marketKit
        self.walletManager = walletManager
        self.nodeManager = nodeManager
        self.testNetManager = testNetManager

        nodeManager.nodeUpdatedPublisher
            .receive(on: DispatchQueue.global(qos: .userInitiated))
            .sink { [weak self] _ in
                self?.dropKit()
            }
            .store(in: &cancellables)

        testNetManager.$testNetEnabled
            .receive(on: DispatchQueue.global(qos: .userInitiated))
            .sink { [weak self] _ in
                self?.dropKit()
            }
            .store(in: &cancellables)
    }

    private func dropKit() {
        queue.async { [weak self] in
            guard let self else { return }

            _nearKit = nil
            currentAccount = nil
            currentAccountId = nil
            watchedContractIds = []
            ftBalancesCancellable?.cancel()
            ftBalancesCancellable = nil
            kitStoppedRelay.accept(())
        }
    }

    private func _nearKit(account: Account) throws -> NearKit.Kit {
        let accountId = try address(account: account)

        if let _nearKit, let currentAccount, currentAccount == account, currentAccountId == accountId {
            return _nearKit
        }

        // the same wallet now opens another of its phrase's accounts: the old kit must stop syncing
        if let _nearKit, currentAccount == account {
            _nearKit.stop()
        }

        let network = Self.network

        let kit = try NearKit.Kit.instance(
            accountId: accountId,
            network: network,
            rpcUrls: nodeManager.rpcUrls(network: network),
            fastNearApiKey: AppConfig.fastNearApiKey,
            walletId: account.id,
            minLogLevel: .error
        )

        kit.start()

        _nearKit = kit
        currentAccount = account
        currentAccountId = accountId
        watchedContractIds = []

        subscribe(nearKit: kit, account: account)

        return kit
    }

    private func subscribe(nearKit: NearKit.Kit, account: Account) {
        ftBalancesCancellable = nearKit.ftBalancesPublisher
            .receive(on: DispatchQueue.global(qos: .userInitiated))
            .sink { [weak self, restoreStateManager] ftBalances in
                let restoreState = restoreStateManager.restoreState(account: account, blockchainType: .near)

                restoreStateManager.setInitialRestored(account: account, blockchainType: .near)

                if !restoreState.initialRestored, !restoreState.shouldRestore, !account.watchAccount {
                    return
                }

                self?.handle(ftBalances: ftBalances, account: account)
            }
    }

    // the index lists every token the account ever touched, so only tokens known to the coin list are enabled
    private func handle(ftBalances: [FtBalance], account: Account) {
        guard Core.shared.config.autoEnableTokensOnReceive else {
            return
        }

        let existingTokenTypeIds = walletManager.activeWallets.map(\.token.type.id)
        let queries = ftBalances
            .filter { $0.balance > 0 }
            .map { TokenQuery(blockchainType: .near, tokenType: .nep141(contractId: $0.contractId)) }
            .filter { !existingTokenTypeIds.contains($0.tokenType.id) }

        guard !queries.isEmpty, let tokens = try? marketKit.tokens(queries: queries), !tokens.isEmpty else {
            return
        }

        let enabledWallets = tokens.map { token in
            EnabledWallet(tokenQueryId: token.tokenQuery.id, accountId: account.id)
        }

        walletManager.save(enabledWallets: enabledWallets)
    }
}

extension NearKitManager {
    var network: NearKit.Network {
        testNetManager.testNetEnabled ? .testNet : .mainNet
    }

    static var network: NearKit.Network {
        Core.shared.nearKitManager.network
    }

    var nearKit: NearKit.Kit? {
        queue.sync { _nearKit }
    }

    func nearKit(account: Account) throws -> NearKit.Kit {
        try queue.sync { try _nearKit(account: account) }
    }

    var kitStoppedObservable: Observable<Void> {
        kitStoppedRelay.asObservable()
    }

    // an adapter of a dropped kit may stop after the new kit started; it must not touch the new kit's set
    func watch(contractId: String, nearKit: NearKit.Kit) {
        queue.async { [weak self] in
            guard let self, let _nearKit, _nearKit === nearKit else { return }

            watchedContractIds.insert(contractId)
            nearKit.watchTokens(contractIds: watchedContractIds)
        }
    }

    func unwatch(contractId: String, nearKit: NearKit.Kit) {
        queue.async { [weak self] in
            guard let self, let _nearKit, _nearKit === nearKit else { return }

            watchedContractIds.remove(contractId)
            nearKit.watchTokens(contractIds: watchedContractIds)
        }
    }
}

extension NearKitManager {
    /// The account the wallet opens: for a restored phrase the one chosen on restore (mainnet only),
    /// otherwise the phrase's implicit account; for a watch account its address.
    func address(account: Account) throws -> String {
        if case .mnemonic = account.type, network == .mainNet,
           let chosen = restoreSettingsManager.settings(accountId: account.id, blockchainType: .near).nearAccountId
        {
            return chosen
        }

        return try Self.implicitAddress(accountType: account.type)
    }

    private static func implicitAddress(accountType: AccountType) throws -> String {
        switch accountType {
        case .mnemonic:
            guard let seed = accountType.mnemonicSeed else {
                throw AdapterError.unsupportedAccount
            }
            return try NearKit.Signer.address(seed: seed)
        case let .nearAddress(address):
            return address
        default:
            throw AdapterError.unsupportedAccount
        }
    }

    static func signer(accountType: AccountType) throws -> NearKit.Signer {
        guard let seed = accountType.mnemonicSeed else {
            throw AdapterError.unsupportedAccount
        }
        return try NearKit.Signer.instance(seed: seed)
    }
}
