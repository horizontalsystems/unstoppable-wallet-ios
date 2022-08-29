import RxSwift
import HsToolKit
import MarketKit

class OpenSeaNftProvider {
    private let networkManager: NetworkManager
    private let marketKit = App.shared.marketKit

    init(networkManager: NetworkManager) {
        self.networkManager = networkManager
    }
}

extension OpenSeaNftProvider: INftProvider {

    func nftAssetMetadataSingle(providerCollectionUid: String, nftUid: NftUid) -> Single<NftAssetMetadata> {
        Single.zip(marketKit.nftCollectionSingle(uid: providerCollectionUid), marketKit.nftAssetSingle(contractAddress: nftUid.contractAddress, tokenId: nftUid.tokenId))
                .map { collection, asset in
                    var bestOffer: NftPrice?
                    var saleInfo: NftAssetMetadata.SaleInfo?

                    let orders = asset.orders
                    var hasTopBid = false
                    let auctionOrders = orders.filter { $0.side == 1 && $0.v == nil }.sorted { $0.ethValue < $1.ethValue }

                    if let order = auctionOrders.first {
                        let bidOrders = orders.filter { $0.side == 0 && !$0.emptyTaker }.sorted { $0.ethValue > $1.ethValue }

                        let type: NftAssetMetadata.SalePriceType
                        var nftPrice: NftPrice?

                        if let bidOrder = bidOrders.first {
                            type = .topBid
                            nftPrice = bidOrder.price
                            hasTopBid = true
                        } else {
                            type = .minimumBid
                            nftPrice = order.price
                        }

                        saleInfo = NftAssetMetadata.SaleInfo(untilDate: order.closingDate, type: type, price: nftPrice)
                    } else {
                        let buyNowOrders = orders.filter { $0.side == 1 && $0.v != nil }.sorted { $0.ethValue < $1.ethValue }

                        if let order = buyNowOrders.first {
                            saleInfo = NftAssetMetadata.SaleInfo(untilDate: order.closingDate, type: .buyNow, price: order.price)
                        }
                    }

                    if !hasTopBid {
                        let offerOrders = orders.filter { $0.side == 0 }.sorted { $0.ethValue > $1.ethValue }

                        if let order = offerOrders.first {
                            bestOffer = order.price
                        }
                    }

                    return NftAssetMetadata(
                            name: asset.name,
                            imageUrl: asset.imageUrl,
                            description: asset.description,
                            nftType: asset.contract.schemaName,
                            websiteLink: asset.externalLink,
                            providerLink: asset.permalink.map { NftAssetMetadata.ProviderLink(title: "OpenSea", url: $0) },
                            traits: asset.traits.map { NftAssetMetadata.Trait(type: $0.type, value: $0.value, count: $0.count) },
                            providerTraitLink: "https://opensea.io/assets/\(collection.uid)?search[stringTraits][0][name]=$traitName&search[stringTraits][0][values][0]=$traitValue&search[sortAscending]=true&search[sortBy]=PRICE",
                            lastSalePrice: asset.lastSalePrice,
                            bestOffer: bestOffer,
                            saleInfo: saleInfo,
                            providerCollectionUid: providerCollectionUid,
                            collectionName: collection.name,
                            collectionTotalSupply: collection.stats.totalSupply,
                            collectionDiscordLink: collection.discordUrl,
                            collectionTwitterUsername: collection.twitterUsername,
                            collectionAveragePrice7d: collection.stats.averagePrice7d,
                            collectionAveragePrice30d: collection.stats.averagePrice30d,
                            collectionFloorPrice: collection.stats.floorPrice
                    )
                }
    }

}
