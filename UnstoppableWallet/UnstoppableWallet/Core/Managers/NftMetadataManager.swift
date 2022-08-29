import RxSwift
import HsToolKit
import MarketKit

class NftMetadataManager {
    private let networkManager: NetworkManager

    init(networkManager: NetworkManager) {
        self.networkManager = networkManager
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

    func nftAssetMetadataSingle(providerCollectionUid: String, nftUid: NftUid) -> Single<NftAssetMetadata> {
        guard let provider = provider(blockchainType: nftUid.blockchainType) else {
            return Single.error(ProviderError.noProviderForBlockchainType)
        }

        return provider.nftAssetMetadataSingle(providerCollectionUid: providerCollectionUid, nftUid: nftUid)
    }

}

extension NftMetadataManager {

    enum ProviderError: Error {
        case noProviderForBlockchainType
    }

}




protocol INftProvider {
    func nftAssetMetadataSingle(providerCollectionUid: String, nftUid: NftUid) -> Single<NftAssetMetadata>
}

struct NftCollectionShortMetadata {
    let providerUid: String
    let name: String
    let thumbnailImageUrl: String?
    let averagePrice7d: NftPrice?
    let averagePrice30d: NftPrice?
}

struct NftAssetShortMetadata {
    let uid: NftUid
    let name: String?
    let imageUrl: String?
    let onSale: Bool
    let lastSalePrice: NftPrice?
}

struct NftAssetMetadata {
    let name: String?
    let imageUrl: String?
    let description: String?
    let nftType: String
    let websiteLink: String?
    let providerLink: ProviderLink?

    let traits: [Trait]
    let providerTraitLink: String?

    let lastSalePrice: NftPrice?
    let bestOffer: NftPrice?
    let saleInfo: SaleInfo?

    let providerCollectionUid: String
    let collectionName: String
    let collectionTotalSupply: Int
    let collectionDiscordLink: String?
    let collectionTwitterUsername: String?
    let collectionAveragePrice7d: NftPrice?
    let collectionAveragePrice30d: NftPrice?
    let collectionFloorPrice: NftPrice?

    struct ProviderLink {
        let title: String
        let url: String
    }

    struct SaleInfo {
        let untilDate: Date
        let type: SalePriceType
        let price: NftPrice?
    }

    enum SalePriceType {
        case buyNow
        case topBid
        case minimumBid
    }

    struct Trait {
        let type: String
        let value: String
        let count: Int
    }

}
