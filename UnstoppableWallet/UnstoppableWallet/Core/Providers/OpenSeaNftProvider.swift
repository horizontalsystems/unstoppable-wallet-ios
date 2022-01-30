import Foundation
import RxSwift
import ObjectMapper
import HsToolKit
import Alamofire
import MarketKit

class OpenSeaNftProvider {
    private let ethereumAddress = "0x0000000000000000000000000000000000000000"
    private let apiUrl = "https://api.opensea.io/api"
    private let headers = HTTPHeaders([
        HTTPHeader.userAgent("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_11_5) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/50.0.2661.102 Safari/537.36")
    ])
    private let collectionLimit = 300
    private let assetLimit = 50

    private let networkManager: NetworkManager
    private let marketKit: MarketKit.Kit

    init(networkManager: NetworkManager, marketKit: MarketKit.Kit) {
        self.networkManager = networkManager
        self.marketKit = marketKit
    }

    private func coinType(address: String) -> CoinType {
        if address == ethereumAddress {
            return .ethereum
        } else {
            return .erc20(address: address)
        }
    }

    private func platformCoinMap(addresses: [String]) -> [String: PlatformCoin] {
        do {
            var map = [String: PlatformCoin]()
            let coinTypes = addresses.map { coinType(address: $0) }
            let platformCoins = try marketKit.platformCoins(coinTypes: coinTypes)

            for platformCoin in platformCoins {
                switch platformCoin.coinType {
                case .ethereum:
                    map[ethereumAddress] = platformCoin
                case .erc20(let address):
                    map[address.lowercased()] = platformCoin
                default:
                    ()
                }
            }

            return map
        } catch {
            return [:]
        }
    }

    private func nftPrice(platformCoin: PlatformCoin?, value: Decimal, shift: Bool) -> NftPrice? {
        guard let platformCoin = platformCoin else {
            return nil
        }

        return NftPrice(
                platformCoin: platformCoin,
                value: shift ? Decimal(sign: .plus, exponent: -platformCoin.decimals, significand: value) : value
        )
    }

    private func collections(responses: [CollectionResponse]) -> [NftCollection] {
        let ethereumPlatformCoin = try? marketKit.platformCoin(coinType: .ethereum)

        return responses.map { response in
            NftCollection(
                    contracts: response.contracts.map { NftCollection.Contract(address: $0.address, schemaName: $0.schemaName) },
                    slug: response.slug,
                    name: response.name,
                    description: response.description,
                    imageUrl: response.imageUrl,
                    featuredImageUrl: response.featuredImageUrl,
                    externalUrl: response.externalUrl,
                    discordUrl: response.discordUrl,
                    twitterUsername: response.twitterUsername,
                    averagePrice7d: nftPrice(platformCoin: ethereumPlatformCoin, value: response.averagePrice7d, shift: false),
                    averagePrice30d: nftPrice(platformCoin: ethereumPlatformCoin, value: response.averagePrice30d, shift: false),
                    totalSupply: response.totalSupply
            )
        }
    }

    private func assets(responses: [AssetResponse]) -> [NftAsset] {
        var addresses = [String]()

        for response in responses {
            if let lastSale = response.lastSale {
                addresses.append(lastSale.paymentTokenAddress)
            }
        }

        let platformCoinMap = platformCoinMap(addresses: addresses)

        return responses.map { response in
            NftAsset(
                    contract: NftCollection.Contract(address: response.contract.address, schemaName: response.contract.schemaName),
                    collectionSlug: response.collectionSlug,
                    tokenId: response.tokenId,
                    name: response.name,
                    imageUrl: response.imageUrl,
                    imagePreviewUrl: response.imagePreviewUrl,
                    description: response.description,
                    externalLink: response.externalLink,
                    permalink: response.permalink,
                    traits: response.traits.map { NftAsset.Trait(type: $0.type, value: $0.value, count: $0.count) },
                    lastSalePrice: response.lastSale.flatMap { nftPrice(platformCoin: platformCoinMap[$0.paymentTokenAddress], value: $0.totalPrice, shift: true) }
            )
        }
    }

    private func collectionsSingle(address: String, offset: Int) -> Single<[CollectionResponse]> {
        let parameters: Parameters = [
            "format": "json",
            "limit": collectionLimit,
            "offset": offset,
            "asset_owner": address
        ]

        let request = networkManager.session.request("\(apiUrl)/v1/collections", parameters: parameters, headers: headers)
        return networkManager.single(request: request)
    }

    private func recursiveCollectionsSingle(address: String, offset: Int = 0, allCollections: [CollectionResponse] = []) -> Single<[CollectionResponse]> {
        collectionsSingle(address: address, offset: offset).flatMap { [unowned self] collections in
            if collections.count == collectionLimit {
                return recursiveCollectionsSingle(address: address, offset: offset + collectionLimit, allCollections: allCollections + collections)
            } else {
                return Single.just(collections)
            }
        }
    }

    private func assetsSingle(address: String, offset: Int) -> Single<[AssetResponse]> {
        let parameters: Parameters = [
            "format": "json",
            "limit": assetLimit,
            "offset": offset,
            "owner": address
        ]

        let request = networkManager.session.request("\(apiUrl)/v1/assets", parameters: parameters, headers: headers)
        return networkManager.single(request: request).map { (response: AssetsResponse) in
            response.assets
        }
    }

    private func recursiveAssetsSingle(address: String, offset: Int = 0, allAssets: [AssetResponse] = []) -> Single<[AssetResponse]> {
        assetsSingle(address: address, offset: offset).flatMap { [unowned self] assets in
            if assets.count == assetLimit {
                return recursiveAssetsSingle(address: address, offset: offset + assetLimit, allAssets: allAssets + assets)
            } else {
                return Single.just(assets)
            }
        }
    }

}

extension OpenSeaNftProvider: INftProvider {

    func assetCollection(address: String) -> Single<NftAssetCollection> {
        let collectionsSingle = recursiveCollectionsSingle(address: address).map { [weak self] responses in
            self?.collections(responses: responses) ?? []
        }

        let assetsSingle = recursiveAssetsSingle(address: address).map { [weak self] responses in
            self?.assets(responses: responses) ?? []
        }

        return Single.zip(collectionsSingle, assetsSingle).map { collections, assets in
            NftAssetCollection(collections: collections, assets: assets)
        }
    }

}

extension OpenSeaNftProvider {

    private struct CollectionResponse: ImmutableMappable {
        let contracts: [AssetContractResponse]
        let slug: String
        let name: String
        let description: String?
        let imageUrl: String?
        let featuredImageUrl: String?
        let externalUrl: String?
        let discordUrl: String?
        let twitterUsername: String?

        let averagePrice7d: Decimal
        let averagePrice30d: Decimal
        let totalSupply: Int

        init(map: Map) throws {
            contracts = try map.value("primary_asset_contracts")
            slug = try map.value("slug")
            name = try map.value("name")
            description = try? map.value("description")
            imageUrl = try? map.value("image_url")
            featuredImageUrl = try? map.value("featured_image_url")
            externalUrl = try? map.value("external_url")
            discordUrl = try? map.value("discord_url")
            twitterUsername = try? map.value("twitter_username")
            averagePrice7d = try map.value("stats.seven_day_average_price", using: OpenSeaNftProvider.doubleToDecimalTransform)
            averagePrice30d = try map.value("stats.thirty_day_average_price", using: OpenSeaNftProvider.doubleToDecimalTransform)
            totalSupply = try map.value("stats.total_supply")
        }
    }

    private struct AssetContractResponse: ImmutableMappable {
        let address: String
        let schemaName: String

        init(map: Map) throws {
            address = try map.value("address")
            schemaName = try map.value("schema_name")
        }
    }

    private struct AssetsResponse: ImmutableMappable {
        let assets: [AssetResponse]

        init(map: Map) throws {
            assets = try map.value("assets")
        }
    }

    private struct AssetResponse: ImmutableMappable {
        let contract: AssetContractResponse
        let collectionSlug: String
        let tokenId: String
        let name: String?
        let imageUrl: String?
        let imagePreviewUrl: String?
        let description: String?
        let externalLink: String?
        let permalink: String?
        let traits: [TraitResponse]
        let lastSale: SaleResponse?

        init(map: Map) throws {
            contract = try map.value("asset_contract")
            collectionSlug = try map.value("collection.slug")
            tokenId = try map.value("token_id")
            name = try? map.value("name")
            imageUrl = try? map.value("image_url")
            imagePreviewUrl = try? map.value("image_preview_url")
            description = try? map.value("description")
            externalLink = try? map.value("external_link")
            permalink = try? map.value("permalink")
            traits = try map.value("traits")
            lastSale = try? map.value("last_sale")
        }
    }

    private struct TraitResponse: ImmutableMappable {
        let type: String
        let value: String
        let count: Int

        init(map: Map) throws {
            type = try map.value("trait_type")

            if let value: String = try? map.value("value") {
                self.value = value
            } else if let value: Int = try? map.value("value") {
                self.value = "\(value)"
            } else {
                value = ""
            }

            count = try map.value("trait_count")
        }
    }

    private struct SaleResponse: ImmutableMappable {
        let totalPrice: Decimal
        let paymentTokenAddress: String

        init(map: Map) throws {
            totalPrice = try map.value("total_price", using: OpenSeaNftProvider.stringToDecimalTransform)
            paymentTokenAddress = try map.value("payment_token.address")
        }
    }

    private static let stringToDecimalTransform: TransformOf<Decimal, String> = TransformOf(fromJSON: { string -> Decimal? in
        guard let string = string else { return nil }
        return Decimal(string: string)
    }, toJSON: { (value: Decimal?) in
        guard let value = value else { return nil }
        return value.description
    })

    private static let doubleToDecimalTransform: TransformOf<Decimal, Double> = TransformOf(fromJSON: { double -> Decimal? in
        guard let double = double else { return nil }
        return Decimal(double)
    }, toJSON: { (value: Decimal?) in
        guard let value = value else { return nil }
        return (value as NSDecimalNumber).doubleValue
    })

}
