import RxSwift
import RxRelay
import HsToolKit
import MarketKit
import ObjectMapper

class NftMetadataManager {
    private let networkManager: NetworkManager
    private let storage: NftStorage

    private let addressMetadataRelay = PublishRelay<(NftKey, NftAddressMetadata)>()

    init(networkManager: NetworkManager, storage: NftStorage) {
        self.networkManager = networkManager
        self.storage = storage
    }

    private func provider(blockchainType: BlockchainType) -> INftProvider? {
        switch blockchainType {
        case .ethereum:
            return OpenSeaNftProvider(networkManager: networkManager)
        default:
            return nil
        }
    }

}

extension NftMetadataManager {

    var addressMetadataObservable: Observable<(NftKey, NftAddressMetadata)> {
        addressMetadataRelay.asObservable()
    }

    func addressMetadataSingle(blockchainType: BlockchainType, address: String) -> Single<NftAddressMetadata> {
        guard let provider = provider(blockchainType: blockchainType) else {
            return Single.error(ProviderError.noProviderForBlockchainType)
        }

        return provider.addressMetadataSingle(blockchainType: blockchainType, address: address)
    }

    func assetMetadataSingle(providerCollectionUid: String, nftUid: NftUid) -> Single<NftAssetMetadata> {
        guard let provider = provider(blockchainType: nftUid.blockchainType) else {
            return Single.error(ProviderError.noProviderForBlockchainType)
        }

        return provider.assetMetadataSingle(providerCollectionUid: providerCollectionUid, nftUid: nftUid)
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
