import Combine
import Foundation
import HdWalletKit
import MarketKit
import RxRelay
import RxSwift
import XrpKit

public class XrpKitManager {
    private let restoreStateManager: RestoreStateManager
    private let marketKit: MarketKit.Kit
    private let walletManager: WalletManager
    private let nodeManager: XrpNodeManager

    private var trustLinesCancellable: AnyCancellable?
    private var cancellables = Set<AnyCancellable>()

    private weak var _xrpKit: XrpKit.Kit?
    private var currentAccount: Account?

    private let queue = DispatchQueue(label: "\(AppConfig.label).xrp-kit-manager", qos: .userInitiated)
    private let kitStoppedRelay = PublishRelay<Void>()

    public init(restoreStateManager: RestoreStateManager, marketKit: MarketKit.Kit, walletManager: WalletManager, nodeManager: XrpNodeManager) {
        self.restoreStateManager = restoreStateManager
        self.marketKit = marketKit
        self.walletManager = walletManager
        self.nodeManager = nodeManager

        nodeManager.nodeUpdatedPublisher
            .receive(on: DispatchQueue.global(qos: .userInitiated))
            .sink { [weak self] _ in
                self?.handleNodeUpdate()
            }
            .store(in: &cancellables)
    }

    /// Drop the kit so the next adapter build reaches the new node (SolanaKitManager
    /// `handleRpcSourceUpdate`); AdapterManager recreates the adapters on the relay.
    private func handleNodeUpdate() {
        queue.async { [weak self] in
            guard let self else { return }

            _xrpKit = nil
            currentAccount = nil
            trustLinesCancellable?.cancel()
            trustLinesCancellable = nil
            kitStoppedRelay.accept(())
        }
    }

    private func _xrpKit(account: Account) throws -> XrpKit.Kit {
        if let _xrpKit, let currentAccount, currentAccount == account {
            return _xrpKit
        }

        let address = try Self.address(accountType: account.type)
        let network = Self.network

        let kit = try XrpKit.Kit.instance(
            address: address,
            network: network,
            rpcUrls: nodeManager.rpcUrls(network: network),
            walletId: account.id,
            minLogLevel: .error
        )

        kit.start()

        _xrpKit = kit
        currentAccount = account

        subscribe(xrpKit: kit, account: account)

        return kit
    }

    private func subscribe(xrpKit: XrpKit.Kit, account: Account) {
        // A trust line is opened by the holder, never pushed by a sender, so every held line with a
        // balance is the user's own token: the subscription stays for the kit's lifetime (Android
        // XrpAccountManager), unlike the one-shot Solana restore pass.
        trustLinesCancellable = xrpKit.trustLinesPublisher
            .receive(on: DispatchQueue.global(qos: .userInitiated))
            .sink { [weak self, restoreStateManager] trustLines in
                let restoreState = restoreStateManager.restoreState(account: account, blockchainType: .xrp)

                restoreStateManager.setInitialRestored(account: account, blockchainType: .xrp)

                if !restoreState.initialRestored, !restoreState.shouldRestore, !account.watchAccount {
                    return
                }

                self?.handle(trustLines: trustLines, account: account)
            }
    }

    private func handle(trustLines: [TrustLine], account: Account) {
        guard Core.shared.config.autoEnableTokensOnReceive else {
            return
        }

        let existingTokenTypeIds = walletManager.activeWallets.map(\.token.type.id)
        let newTrustLines = trustLines.filter { line in
            let tokenType = TokenType.xrpAsset(currency: line.currency, issuer: line.issuer)
            return line.balance > 0 && !existingTokenTypeIds.contains(tokenType.id)
        }

        guard !newTrustLines.isEmpty else {
            return
        }

        let enabledWallets = newTrustLines.map { line in
            let code = XrpKit.Kit.displayCurrencyCode(line.currency)
            return EnabledWallet(
                tokenQueryId: TokenQuery(blockchainType: .xrp, tokenType: .xrpAsset(currency: line.currency, issuer: line.issuer)).id,
                accountId: account.id,
                coinName: code,
                coinCode: code,
                tokenDecimals: Self.issuedTokenDecimals
            )
        }

        walletManager.save(enabledWallets: enabledWallets)
    }
}

extension XrpKitManager {
    /// Issued currencies carry 15 significant digits on the ledger; the catalog lists them with 8 decimals.
    static let issuedTokenDecimals = 8

    /// Follows the app-wide testnet switch, like Tron: the kit keeps a separate database per network.
    static var network: XrpKit.Network {
        Core.shared.testNetManager.testNetEnabled ? .testNet : .mainNet
    }

    var xrpKit: XrpKit.Kit? {
        queue.sync { _xrpKit }
    }

    func xrpKit(account: Account) throws -> XrpKit.Kit {
        try queue.sync { try _xrpKit(account: account) }
    }

    var kitStoppedObservable: Observable<Void> {
        kitStoppedRelay.asObservable()
    }

    var blockchain: Blockchain? {
        try? marketKit.blockchain(uid: BlockchainType.xrp.uid)
    }
}

extension XrpKitManager {
    static func address(accountType: AccountType) throws -> String {
        switch accountType {
        case .mnemonic:
            guard let seed = accountType.mnemonicSeed else {
                throw AdapterError.unsupportedAccount
            }
            return try XrpKit.Signer.address(seed: seed)
        case let .xrpAddress(address):
            return address
        default:
            throw AdapterError.unsupportedAccount
        }
    }

    static func signer(accountType: AccountType) throws -> XrpKit.Signer {
        guard let seed = accountType.mnemonicSeed else {
            throw AdapterError.unsupportedAccount
        }
        return try XrpKit.Signer.instance(seed: seed)
    }
}
