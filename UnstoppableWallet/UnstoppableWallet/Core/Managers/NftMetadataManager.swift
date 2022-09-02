import RxSwift
import RxRelay
import HsToolKit
import MarketKit
import ObjectMapper

class NftMetadataManager {
    private let storage: NftStorage
    private let providerMap: [BlockchainType: INftProvider]

    private let addressMetadataRelay = PublishRelay<(NftKey, NftAddressMetadata)>()

    init(networkManager: NetworkManager, marketKit: MarketKit.Kit, storage: NftStorage) {
        self.storage = storage

        providerMap = [
            .ethereum: OpenSeaNftProvider(networkManager: networkManager, marketKit: marketKit)
        ]
    }

}

extension NftMetadataManager {

    var addressMetadataObservable: Observable<(NftKey, NftAddressMetadata)> {
        addressMetadataRelay.asObservable()
    }

    func collectionLink(blockchainType: BlockchainType, providerUid: String) -> ProviderLink? {
        guard let provider = providerMap[blockchainType] else {
            return nil
        }

        return provider.collectionLink(providerUid: providerUid)
    }

    func addressMetadataSingle(blockchainType: BlockchainType, address: String) -> Single<NftAddressMetadata> {
        guard let provider = providerMap[blockchainType] else {
            return Single.error(ProviderError.noProviderForBlockchainType)
        }

        return provider.addressMetadataSingle(blockchainType: blockchainType, address: address)
    }

    func assetMetadataSingle(nftUid: NftUid) -> Single<NftAssetMetadata> {
        guard let provider = providerMap[nftUid.blockchainType] else {
            return Single.error(ProviderError.noProviderForBlockchainType)
        }

        return provider.assetMetadataSingle(nftUid: nftUid)
    }

    func collectionAssetsMetadataSingle(blockchainType: BlockchainType, providerCollectionUid: String, paginationData: PaginationData? = nil) -> Single<([NftAssetMetadata], PaginationData?)> {
        guard let provider = providerMap[blockchainType] else {
            return Single.error(ProviderError.noProviderForBlockchainType)
        }

        return provider.collectionAssetsMetadataSingle(blockchainType: blockchainType, providerCollectionUid: providerCollectionUid, paginationData: paginationData)
    }

    func collectionMetadataSingle(blockchainType: BlockchainType, providerUid: String) -> Single<NftCollectionMetadata> {
        guard let provider = providerMap[blockchainType] else {
            return Single.error(ProviderError.noProviderForBlockchainType)
        }

        return provider.collectionMetadataSingle(blockchainType: blockchainType, providerUid: providerUid)
    }

    func addressMetadata(nftKey: NftKey) -> NftAddressMetadata? {
        storage.addressMetadata(nftKey: nftKey)
    }

    func handle(addressMetadata: NftAddressMetadata, nftKey: NftKey) {
        storage.save(addressMetadata: addressMetadata, nftKey: nftKey)
        addressMetadataRelay.accept((nftKey, addressMetadata))
    }

}

extension NftMetadataManager {

    enum ProviderError: Error {
        case noProviderForBlockchainType
    }

}

enum PaginationData {
    case cursor(value: String)
    case page(value: Int)

    var cursor: String? {
        switch self {
        case .cursor(let value): return value
        default: return nil
        }
    }

    var page: Int? {
        switch self {
        case .page(let value): return value
        default: return nil
        }
    }
}
