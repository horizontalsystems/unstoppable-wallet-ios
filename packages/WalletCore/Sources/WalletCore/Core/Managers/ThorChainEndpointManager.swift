import MarketKit
import RxRelay
import RxSwift
import ThorChainKit

final class ThorChainEndpointManager {
    private let blockchainSettingsStorage: BlockchainSettingsStorage?
    private let endpointProvider: IThorChainEndpointConfigurationProvider
    private let blockchainType: BlockchainType
    private let endpointRelay = PublishRelay<Void>()
    private var transientEndpointFamilyId: String?

    init(blockchainSettingsStorage: BlockchainSettingsStorage, endpointProvider: IThorChainEndpointConfigurationProvider, blockchainType: BlockchainType = .thorChain) {
        self.blockchainSettingsStorage = blockchainSettingsStorage
        self.endpointProvider = endpointProvider
        self.blockchainType = blockchainType
    }

    convenience init(endpointProvider: IThorChainEndpointConfigurationProvider, blockchainType: BlockchainType = .thorChain) {
        self.init(blockchainSettingsStorage: nil, endpointProvider: endpointProvider, blockchainType: blockchainType)
    }

    private init(blockchainSettingsStorage: BlockchainSettingsStorage?, endpointProvider: IThorChainEndpointConfigurationProvider, blockchainType: BlockchainType) {
        self.blockchainSettingsStorage = blockchainSettingsStorage
        self.endpointProvider = endpointProvider
        self.blockchainType = blockchainType
    }

    var endpointObservable: Observable<Void> {
        endpointRelay.asObservable()
    }

    func endpointFamilies() throws -> [ThorChainKit.EndpointFamilyDescriptor] {
        try endpointProvider.configuration().value.families
    }

    func endpointFamily() throws -> ThorChainKit.EndpointFamilyDescriptor {
        try endpointFamily(configuration: endpointProvider.configuration())
    }

    private func endpointFamily(configuration: ThorChainEndpointConfiguration) throws -> ThorChainKit.EndpointFamilyDescriptor {
        let endpointFamilies = configuration.value.families

        if let savedId = blockchainSettingsStorage?.thorChainEndpointFamilyId(blockchainType: blockchainType) ?? transientEndpointFamilyId,
           let endpointFamily = endpointFamilies.first(where: { $0.id == savedId })
        {
            return endpointFamily
        }

        guard let endpointFamily = endpointFamilies.first else {
            throw ThorChainEndpointManagerError.noEndpointFamilies
        }
        return endpointFamily
    }

    func endpointConfiguration() throws -> ThorChainEndpointConfiguration {
        let configuration = try endpointProvider.configuration()
        let endpointFamily = try endpointFamily(configuration: configuration)

        return try ThorChainEndpointConfiguration(
            value: ThorChainKit.EndpointConfiguration(
                families: [endpointFamily],
                midgardURLs: configuration.value.midgardURLs
            ),
            approvedMainnetHosts: configuration.approvedMainnetHosts
        )
    }

    var backup: EndpointBackup {
        .init(familyId: try? endpointFamily().id)
    }

    func setCurrent(endpointFamily: ThorChainKit.EndpointFamilyDescriptor) throws {
        guard try endpointFamilies().contains(endpointFamily) else {
            throw ThorChainEndpointManagerError.unknownEndpointFamily
        }

        blockchainSettingsStorage?.save(thorChainEndpointFamilyId: endpointFamily.id, blockchainType: blockchainType)
        transientEndpointFamilyId = endpointFamily.id
        endpointRelay.accept(())
    }

    func restore(backup: EndpointBackup) {
        guard let familyId = backup.familyId,
              let endpointFamily = try? endpointFamilies().first(where: { $0.id == familyId })
        else {
            return
        }

        try? setCurrent(endpointFamily: endpointFamily)
    }
}

enum ThorChainEndpointManagerError: Error {
    case noEndpointFamilies
    case unknownEndpointFamily
}

extension ThorChainEndpointManager {
    struct EndpointBackup: Codable {
        let familyId: String?

        enum CodingKeys: String, CodingKey {
            case familyId = "family_id"
        }
    }
}
