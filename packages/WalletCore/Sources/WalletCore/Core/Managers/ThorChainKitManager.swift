import Foundation
import HsCryptoKit
import HsToolKit
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
            // Matches the THORNode endpoint thorchain-kit-android ships as its
            // default. Android reaches it through `thorchain_api` only; the kit
            // here also verifies chain identity and height over CometBFT, which
            // the same host serves under `thorchain_rpc`.
            ThorChainKit.EndpointFamilyDescriptor(
                id: "liquify-mainnet",
                cosmosRestURL: URL(string: "https://gateway.liquify.com/chain/thorchain_api")!,
                cometBftURL: URL(string: "https://gateway.liquify.com/chain/thorchain_rpc")!
            ),
            ThorChainKit.EndpointFamilyDescriptor(
                id: "rorcual-mainnet",
                cosmosRestURL: URL(string: "https://api-thorchain.rorcual.xyz")!,
                cometBftURL: URL(string: "https://rpc-thorchain.rorcual.xyz")!
            ),
            ThorChainKit.EndpointFamilyDescriptor(
                id: "ibs-mainnet",
                cosmosRestURL: URL(string: "https://thorchain.ibs.team/api")!,
                cometBftURL: URL(string: "https://thorchain.ibs.team/rpc")!
            ),
            ThorChainKit.EndpointFamilyDescriptor(
                id: "keplr-mainnet",
                cosmosRestURL: URL(string: "https://lcd-thorchain.keplr.app")!,
                cometBftURL: URL(string: "https://rpc-thorchain.keplr.app")!
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

final class ThorChainKitWrapper {
    let thorChainKit: ThorChainKit.Kit
    private let signer: ThorChainKit.Signer?

    init(thorChainKit: ThorChainKit.Kit, signer: ThorChainKit.Signer?) {
        self.thorChainKit = thorChainKit
        self.signer = signer
    }

    func quote(to recipient: ThorChainKit.Address, amount: ThorChainKit.SendAmount, memo: String?) async throws -> ThorChainKit.SendQuote {
        try await thorChainKit.quote(to: recipient, amount: amount, memo: memo)
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
    private let queue = DispatchQueue(label: "\(AppConfig.label).thor-chain-kit-manager", qos: .userInitiated)
    private let endpointManager: ThorChainEndpointManager
    private let kitUpdatedRelay = PublishRelay<Void>()

    init(endpointManager: ThorChainEndpointManager) {
        self.endpointManager = endpointManager

        subscribe(disposeBag, endpointManager.endpointObservable) { [weak self] in
            self?.handleUpdatedEndpoint()
        }
    }

    convenience init(endpointProvider: IThorChainEndpointConfigurationProvider) {
        self.init(endpointManager: ThorChainEndpointManager(endpointProvider: endpointProvider))
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

        let address = try AccountAddress.thorChainAddress(account: account)
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
        let wrapper = ThorChainKitWrapper(thorChainKit: kit, signer: signer)
        _wrapper = wrapper
        currentIdentity = identity
        return wrapper
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
