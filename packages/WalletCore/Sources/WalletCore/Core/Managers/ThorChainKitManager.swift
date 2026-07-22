import BigInt
import Combine
import Foundation
import HsToolKit
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
        let host = "thornode.ninerealms.com"
        let family = try ThorChainKit.EndpointFamilyDescriptor(
            id: "ninerealms-mainnet",
            cosmosRestURL: URL(string: "https://\(host)")!,
            cometBftURL: URL(string: "https://\(host)")!
        )
        return ThorChainEndpointConfiguration(
            value: try ThorChainKit.EndpointConfiguration(families: [family]),
            approvedMainnetHosts: [host]
        )
    }
}

protocol IThorChainKit: AnyObject {
    var address: ThorChainKit.Address { get }
    var network: ThorChainKit.Network { get }
    var lastBlockHeight: Int64? { get }
    var syncState: ThorChainKit.SyncState { get }
    var accountState: ThorChainKit.AccountState? { get }
    var runeBalance: BigUInt { get }
    var accountExists: Bool { get }

    var lastBlockHeightPublisher: AnyPublisher<Int64?, Never> { get }
    var syncStatePublisher: AnyPublisher<ThorChainKit.SyncState, Never> { get }
    var accountStatePublisher: AnyPublisher<ThorChainKit.AccountState?, Never> { get }

    func start()
    func stop()
    func refresh()
}

extension ThorChainKit.Kit: IThorChainKit {}

protocol IThorChainKitFactory {
    func kit(
        address: ThorChainKit.Address,
        walletId: String,
        endpoints: ThorChainKit.EndpointConfiguration
    ) throws -> any IThorChainKit
}

enum ThorChainDiagnostic: Equatable {
    case constructionFailed
}

protocol IThorChainDiagnosticLogger {
    func log(_ diagnostic: ThorChainDiagnostic)
}

final class ThorChainDiagnosticLogger: IThorChainDiagnosticLogger {
    private let logger: Logger

    init(logger: Logger) {
        self.logger = logger
    }

    func log(_ diagnostic: ThorChainDiagnostic) {
        switch diagnostic {
        case .constructionFailed:
            logger.error("thorchain_adapter_construction_failed", save: false)
        }
    }
}

final class ThorChainKitFactory: IThorChainKitFactory {
    func kit(
        address: ThorChainKit.Address,
        walletId: String,
        endpoints: ThorChainKit.EndpointConfiguration
    ) throws -> any IThorChainKit {
        try ThorChainKit.Kit.instance(address: address, walletId: walletId, endpoints: endpoints)
    }
}

final class ThorChainKitWrapper {
    let thorChainKit: any IThorChainKit

    init(thorChainKit: any IThorChainKit) {
        self.thorChainKit = thorChainKit
    }
}

final class ThorChainKitManager {
    private weak var _wrapper: ThorChainKitWrapper?
    private var currentIdentity: CacheIdentity?
    private let queue = DispatchQueue(label: "\(AppConfig.label).thor-chain-kit-manager", qos: .userInitiated)
    private let endpointProvider: IThorChainEndpointConfigurationProvider
    private let kitFactory: IThorChainKitFactory

    init(
        endpointProvider: IThorChainEndpointConfigurationProvider,
        kitFactory: IThorChainKitFactory
    ) {
        self.endpointProvider = endpointProvider
        self.kitFactory = kitFactory
    }

    var thorChainKitWrapper: ThorChainKitWrapper? {
        queue.sync { _wrapper }
    }

    func thorChainKitWrapper(account: Account) throws -> ThorChainKitWrapper {
        try queue.sync {
            try makeWrapper(account: account)
        }
    }

    private func makeWrapper(account: Account) throws -> ThorChainKitWrapper {
        guard case .mnemonic = account.type else {
            throw ThorChainKitManagerError.unsupportedAccount
        }
        guard account.type.mnemonicSeed != nil else {
            throw ThorChainKitManagerError.mnemonicNoSeed
        }

        let address = try AccountAddress.thorChainAddress(account: account)
        let endpointConfiguration = try endpointProvider.configuration()
        try validate(endpointConfiguration: endpointConfiguration)

        let identity = CacheIdentity(
            accountId: account.id,
            address: address.raw,
            network: address.network,
            endpointFamilyIds: endpointConfiguration.value.families.map(\.id)
        )
        if let wrapper = _wrapper, currentIdentity == identity {
            return wrapper
        }

        let kit = try kitFactory.kit(
            address: address,
            walletId: account.id,
            endpoints: endpointConfiguration.value
        )
        let wrapper = ThorChainKitWrapper(thorChainKit: kit)
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
    }

    private struct CacheIdentity: Equatable {
        let accountId: String
        let address: String
        let network: ThorChainKit.Network
        let endpointFamilyIds: [String]
    }
}

enum ThorChainKitManagerError: Error, Equatable {
    case unsupportedAccount
    case mnemonicNoSeed
    case unapprovedEndpointHost(String)
}
