import Combine
import Foundation
import HsCryptoKit
import HsToolKit
import MarketKit
import RxRelay
import RxSwift
import ThorChainKit

protocol IThorChainEndpointConfigurationProvider {
    func configuration() throws -> ThorChainEndpointConfiguration
}

struct ThorChainEndpointConfiguration {
    let value: ThorChainKit.EndpointConfiguration
    let approvedMainnetHosts: Set<String>
}

final class ThorChainEndpointConfigurationProvider: IThorChainEndpointConfigurationProvider {
    func configuration() throws -> ThorChainEndpointConfiguration {
        let families = try [
            ThorChainKit.EndpointFamilyDescriptor(
                id: "Rorcual",
                cosmosRestURL: URL(string: "https://api-thorchain.rorcual.xyz")!,
                cometBftURL: URL(string: "https://rpc-thorchain.rorcual.xyz")!
            ),
            ThorChainKit.EndpointFamilyDescriptor(
                id: "IBS",
                cosmosRestURL: URL(string: "https://thorchain.ibs.team/api")!,
                cometBftURL: URL(string: "https://thorchain.ibs.team/rpc")!
            ),
            ThorChainKit.EndpointFamilyDescriptor(
                id: "Keplr",
                cosmosRestURL: URL(string: "https://lcd-thorchain.keplr.app")!,
                cometBftURL: URL(string: "https://rpc-thorchain.keplr.app")!
            ),
            // The THORNode endpoint thorchain-kit-android ships as its default. Android
            // reaches it through `thorchain_api` only; this kit also verifies chain
            // identity and height over CometBFT, which the same host serves under
            // `thorchain_rpc`. Listed last, not first: it intermittently answers the
            // account read with HTTP 500, and 500 is not a retryable status.
            ThorChainKit.EndpointFamilyDescriptor(
                id: "Liquify",
                cosmosRestURL: URL(string: "https://gateway.liquify.com/chain/thorchain_api")!,
                cometBftURL: URL(string: "https://gateway.liquify.com/chain/thorchain_rpc")!
            ),
        ]
        return try ThorChainEndpointConfiguration(
            value: ThorChainKit.EndpointConfiguration(
                families: families,
                midgardURLs: [URL(string: "https://gateway.liquify.com/chain/thorchain_midgard/")!]
            ),
            approvedMainnetHosts: [
                "api-thorchain.rorcual.xyz",
                "rpc-thorchain.rorcual.xyz",
                "thorchain.ibs.team",
                "lcd-thorchain.keplr.app",
                "rpc-thorchain.keplr.app",
                "gateway.liquify.com",
            ]
        )
    }
}

// Maya Protocol (mayanode, a thornode fork) served by the same kit; single public
// node family so far, mirroring thorchain-kit-android's MayaMainnet defaults.
final class MayaChainEndpointConfigurationProvider: IThorChainEndpointConfigurationProvider {
    func configuration() throws -> ThorChainEndpointConfiguration {
        let families = try [
            ThorChainKit.EndpointFamilyDescriptor(
                id: "Mayanode",
                cosmosRestURL: URL(string: "https://mayanode.mayachain.info")!,
                cometBftURL: URL(string: "https://tendermint.mayachain.info")!
            ),
        ]
        return try ThorChainEndpointConfiguration(
            value: ThorChainKit.EndpointConfiguration(
                families: families,
                midgardURLs: [URL(string: "https://midgard.mayachain.info/")!]
            ),
            approvedMainnetHosts: [
                "mayanode.mayachain.info",
                "tendermint.mayachain.info",
                "midgard.mayachain.info",
            ]
        )
    }
}

final class ThorChainKitWrapper {
    let thorChainKit: ThorChainKit.Kit
    private let signer: ThorChainKit.Signer?

    init(thorChainKit: ThorChainKit.Kit, signer: ThorChainKit.Signer?) {
        self.thorChainKit = thorChainKit
        self.signer = signer
    }

    func quote(to recipient: ThorChainKit.Address, amount: ThorChainKit.SendAmount, memo: String?, denom: ThorChainKit.Denom) async throws -> ThorChainKit.SendQuote {
        try await thorChainKit.quote(to: recipient, amount: amount, memo: memo, denom: denom)
    }

    func send(quote: ThorChainKit.SendQuote) async throws -> ThorChainKit.SendSubmission {
        guard let signer else {
            throw Error.signerNotSupported
        }

        let submission = try await thorChainKit.send(quote: quote, signer: signer)
        return submission
    }

    enum Error: Swift.Error {
        case signerNotSupported
    }
}

final class ThorChainKitManager {
    private let disposeBag = DisposeBag()
    private weak var _wrapper: ThorChainKitWrapper?
    private var currentIdentity: CacheIdentity?
    private let queue: DispatchQueue
    private let endpointManager: ThorChainEndpointManager
    private let network: ThorChainKit.Network
    // Auto-enable dependencies; nil leaves held-token auto-enable off (tests, factory convenience path)
    private let restoreStateManager: RestoreStateManager?
    private let marketKit: MarketKit.Kit?
    private let walletManager: WalletManager?
    private let kitUpdatedRelay = PublishRelay<Void>()
    private var balanceCancellable: AnyCancellable?
    private var transactionsCancellable: AnyCancellable?

    init(endpointManager: ThorChainEndpointManager, restoreStateManager: RestoreStateManager? = nil, marketKit: MarketKit.Kit? = nil, walletManager: WalletManager? = nil, network: ThorChainKit.Network = .mainnet) {
        self.endpointManager = endpointManager
        self.restoreStateManager = restoreStateManager
        self.marketKit = marketKit
        self.walletManager = walletManager
        self.network = network
        queue = DispatchQueue(label: "\(AppConfig.label).thor-chain-kit-manager.\(network.chain.rawValue)", qos: .userInitiated)

        subscribe(disposeBag, endpointManager.endpointObservable) { [weak self] in
            self?.handleUpdatedEndpoint()
        }
    }

    convenience init(endpointProvider: IThorChainEndpointConfigurationProvider, network: ThorChainKit.Network = .mainnet) {
        self.init(
            endpointManager: ThorChainEndpointManager(endpointProvider: endpointProvider, blockchainType: network.chain == .maya ? .mayaChain : .thorChain),
            network: network
        )
    }

    private func handleUpdatedEndpoint() {
        queue.sync {
            guard _wrapper != nil else { return }

            _wrapper = nil
            currentIdentity = nil
            kitUpdatedRelay.accept(())
        }
    }

    var thorChainKitWrapper: ThorChainKitWrapper? {
        queue.sync { _wrapper }
    }

    var kitUpdatedObservable: Observable<Void> {
        kitUpdatedRelay.asObservable()
    }

    func thorChainKitWrapper(account: Account) throws -> ThorChainKitWrapper {
        try queue.sync {
            try _kitWrapper(account: account)
        }
    }

    private func _kitWrapper(account: Account) throws -> ThorChainKitWrapper {
        guard case let .mnemonic(words, _, _) = account.type else {
            throw ThorChainKitManagerError.unsupportedAccount
        }
        // `mnemonicSeed` is PBKDF2 over the joined words, so an empty list still
        // yields 64 bytes rather than nil. Reject it here: deriving from it would
        // produce a publicly computable address and signing key.
        guard !words.isEmpty, account.type.mnemonicSeed != nil else {
            throw ThorChainKitManagerError.mnemonicNoSeed
        }

        let address = try AccountAddress.thorChainAddress(account: account, network: network)
        let endpointConfiguration = try endpointManager.endpointConfiguration()
        try validate(endpointConfiguration: endpointConfiguration)

        let identity = CacheIdentity(
            accountId: account.id,
            address: address.raw,
            network: address.network,
            endpointFamilyIds: endpointConfiguration.value.families.map(\.id),
            midgardURLs: endpointConfiguration.value.midgardURLs
        )
        if let wrapper = _wrapper, currentIdentity == identity {
            return wrapper
        }

        let signer = try signer(account: account)
        let kit = try ThorChainKit.Kit.instance(
            address: address,
            walletId: account.id,
            endpoints: endpointConfiguration.value
        )
        kit.start()
        subscribeToAutoEnable(kit: kit, address: address, account: account)
        let wrapper = ThorChainKitWrapper(thorChainKit: kit, signer: signer)
        _wrapper = wrapper
        currentIdentity = identity
        return wrapper
    }

    // Auto-enable of held denoms (TCY, secured assets, …), mirroring TonKitManager's
    // dual pattern: a one-shot balances pass for restore, then tx-driven enabling.
    // Re-subscription is free: a new kit (endpoint or account switch) passes here again.
    private func subscribeToAutoEnable(kit: ThorChainKit.Kit, address: ThorChainKit.Address, account: Account) {
        guard let restoreStateManager else { return }

        let blockchainType = blockchainType
        let restoreState = restoreStateManager.restoreState(account: account, blockchainType: blockchainType)

        if restoreState.shouldRestore || account.watchAccount, !restoreState.initialRestored {
            balanceCancellable = kit.accountStatePublisher
                .sink { [weak self] accountState in
                    guard let balances = accountState?.balances, !balances.isEmpty else { return }

                    self?.handle(denoms: balances.filter { $0.value > 0 }.map(\.key), account: account)

                    restoreStateManager.setInitialRestored(account: account, blockchainType: blockchainType)

                    self?.balanceCancellable?.cancel()
                    self?.balanceCancellable = nil
                }
        }

        // allTransactionsPublisher emits only unprocessed transactions, so a manually
        // disabled token is not re-enabled by unchanged history.
        transactionsCancellable = kit.allTransactionsPublisher
            .sink { [weak self] transactions, initial in
                self?.handle(transactions: transactions, initial: initial, address: address, account: account)
            }
    }

    private func handle(transactions: [ThorChainKit.Transaction], initial: Bool, address: ThorChainKit.Address, account: Account) {
        if initial, account.origin == .restored, !account.watchAccount,
           let restoreStateManager, !restoreStateManager.shouldRestore(account: account, blockchainType: blockchainType)
        {
            return
        }

        let denoms = Self.incomingDenoms(transactions: transactions, address: address.raw, chain: network.chain)

        handle(denoms: Array(denoms), account: account)
    }

    private func handle(denoms: [ThorChainKit.Denom], account: Account) {
        guard let marketKit, let walletManager, Core.shared.config.autoEnableTokensOnReceive else {
            return
        }

        let queries = Self.autoEnableQueries(
            denoms: denoms,
            nativeDenom: network.nativeDenom,
            existingTokenTypeIds: walletManager.activeWallets.map(\.token.type.id),
            blockchainType: blockchainType
        )

        guard !queries.isEmpty, let tokens = try? marketKit.tokens(queries: queries), !tokens.isEmpty else {
            return
        }

        let enabledWallets = tokens.map { token in
            EnabledWallet(
                tokenQueryId: token.tokenQuery.id,
                accountId: account.id,
                coinName: token.coin.name,
                coinCode: token.coin.code,
                tokenDecimals: token.decimals
            )
        }

        walletManager.save(enabledWallets: enabledWallets)
    }

    static func incomingDenoms(transactions: [ThorChainKit.Transaction], address: String, chain: ThorChainKit.Network.Chain) -> Set<ThorChainKit.Denom> {
        var denoms = Set<ThorChainKit.Denom>()

        for transaction in transactions {
            for transfer in transaction.incoming where transfer.address == address {
                guard let asset = try? chain.asset(for: transfer.asset),
                      let denom = try? ThorChainKit.Denom(rawValue: chain.denom(for: asset))
                else { continue }
                denoms.insert(denom)
            }
        }

        return denoms
    }

    static func autoEnableQueries(denoms: [ThorChainKit.Denom], nativeDenom: ThorChainKit.Denom, existingTokenTypeIds: [String], blockchainType: BlockchainType) -> [TokenQuery] {
        denoms
            .filter { $0 != nativeDenom }
            .map { TokenQuery(blockchainType: blockchainType, tokenType: .thorChainAsset(denom: $0.rawValue)) }
            .filter { !existingTokenTypeIds.contains($0.tokenType.id) }
    }

    private var blockchainType: BlockchainType {
        network.chain == .maya ? .mayaChain : .thorChain
    }

    private func validate(endpointConfiguration: ThorChainEndpointConfiguration) throws {
        for family in endpointConfiguration.value.families {
            for url in [family.cosmosRestURL, family.cometBftURL] {
                guard url.scheme?.lowercased() == "https",
                      let host = url.host,
                      endpointConfiguration.approvedMainnetHosts.contains(host)
                else {
                    throw ThorChainKitManagerError.unapprovedEndpointHost(url.host ?? "")
                }
            }
        }
        for url in endpointConfiguration.value.midgardURLs {
            guard url.scheme?.lowercased() == "https",
                  let host = url.host,
                  endpointConfiguration.approvedMainnetHosts.contains(host)
            else {
                throw ThorChainKitManagerError.unapprovedEndpointHost(url.host ?? "")
            }
        }
    }

    private func signer(account: Account) throws -> ThorChainKit.Signer {
        guard let seed = account.type.mnemonicSeed else {
            throw ThorChainKitManagerError.mnemonicNoSeed
        }

        return try ThorChainKit.Signer.instance(seed: seed)
    }

    private struct CacheIdentity: Equatable {
        let accountId: String
        let address: String
        let network: ThorChainKit.Network
        let endpointFamilyIds: [String]
        let midgardURLs: [URL]
    }
}

enum ThorChainKitManagerError: Error, Equatable {
    case unsupportedAccount
    case mnemonicNoSeed
    case unapprovedEndpointHost(String)
}
