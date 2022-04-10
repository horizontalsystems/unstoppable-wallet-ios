import Foundation
import RxSwift
import ObjectMapper
import HsToolKit
import Alamofire
import MarketKit

class HsNftProvider {
    private let zeroAddress = "0x0000000000000000000000000000000000000000"
    private let collectionLimit = 300
    private let assetLimit = 50

    private let networkManager: NetworkManager
    private let marketKit: MarketKit.Kit
    private let apiUrl: String
    private let headers: HTTPHeaders?
    private let encoding: ParameterEncoding = URLEncoding(boolEncoding: .literal)

    init(networkManager: NetworkManager, marketKit: MarketKit.Kit, appConfigProvider: AppConfigProvider) {
        self.networkManager = networkManager
        self.marketKit = marketKit
        apiUrl = appConfigProvider.marketApiUrl

        headers = appConfigProvider.hsProviderApiKey.flatMap { HTTPHeaders([HTTPHeader(name: "apikey", value: $0)]) }
    }

    private func coinType(address: String) -> CoinType {
        if address == zeroAddress {
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
                    map[zeroAddress] = platformCoin
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

    private func nftPrice(platformCoin: PlatformCoin?, value: Decimal?, shift: Bool) -> NftPrice? {
        guard let platformCoin = platformCoin, let value = value else {
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
            collection(response: response, ethereumPlatformCoin: ethereumPlatformCoin)
        }
    }

    private func collection(response: CollectionResponse, ethereumPlatformCoin: PlatformCoin? = nil) -> NftCollection {
        let ethereumPlatformCoin = ethereumPlatformCoin ?? (try? marketKit.platformCoin(coinType: .ethereum))

        return NftCollection(
                contracts: response.contracts.map { NftCollection.Contract(address: $0.address, schemaName: $0.type) },
                uid: response.uid,
                name: response.name,
                description: response.description,
                imageUrl: response.imageUrl,
                featuredImageUrl: response.featuredImageUrl,
                externalUrl: response.externalUrl,
                discordUrl: response.discordUrl,
                twitterUsername: response.twitterUsername,
                stats: collectionStats(response: response.stats, ethereumPlatformCoin: ethereumPlatformCoin)
        )
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
                    contract: NftCollection.Contract(address: response.contract.address, schemaName: response.contract.type),
                    collectionUid: response.collectionUid,
                    tokenId: response.tokenId,
                    name: response.name,
                    imageUrl: response.imageUrl,
                    imagePreviewUrl: response.imagePreviewUrl,
                    description: response.description,
                    externalLink: response.externalLink,
                    permalink: response.permalink,
                    traits: response.traits.map { NftAsset.Trait(type: $0.type, value: $0.value, count: $0.count) },
                    lastSalePrice: response.lastSale.flatMap { nftPrice(platformCoin: platformCoinMap[$0.paymentTokenAddress], value: $0.totalPrice, shift: true) },
                    onSale: !response.sellOrders.isEmpty
            )
        }
    }

    private func collectionStats(response: CollectionStatsResponse, ethereumPlatformCoin: PlatformCoin? = nil) -> NftCollectionStats {
        let ethereumPlatformCoin = ethereumPlatformCoin ?? (try? marketKit.platformCoin(coinType: .ethereum))

        return NftCollectionStats(
                totalSupply: response.totalSupply,
                averagePrice7d: nftPrice(platformCoin: ethereumPlatformCoin, value: response.averagePrice7d, shift: false),
                averagePrice30d: nftPrice(platformCoin: ethereumPlatformCoin, value: response.averagePrice30d, shift: false),
                floorPrice: nftPrice(platformCoin: ethereumPlatformCoin, value: response.floorPrice, shift: false),
                totalVolume: response.totalVolume,
                priceChange: response.oneDayChange,
                marketCap: response.marketCap
        )
    }

    private func assetOrders(responses: [OrderResponse]) -> [NftAssetOrder] {
        let map = platformCoinMap(addresses: responses.map { $0.paymentToken.address })

        return responses.map { response in
            NftAssetOrder(
                    closingDate: response.closingDate,
                    price: map[response.paymentToken.address].flatMap { nftPrice(platformCoin: $0, value: response.currentPrice, shift: true) },
                    emptyTaker: response.takerAddress == zeroAddress,
                    side: response.side,
                    v: response.v,
                    ethValue: Decimal(sign: .plus, exponent: -response.paymentToken.decimals, significand: response.currentPrice) / response.paymentToken.ethPrice
            )
        }
    }

    private func collectionsSingle(address: String, page: Int) -> Single<[CollectionResponse]> {
        let parameters: Parameters = [
            "asset_owner": address,
            "limit": collectionLimit,
            "page": page
        ]

        let request = networkManager.session.request("\(apiUrl)/v1/nft/collections", parameters: parameters, encoding: encoding, headers: headers)
        return networkManager.single(request: request)
    }

    private func recursiveCollectionsSingle(address: String, page: Int = 1, allCollections: [CollectionResponse] = []) -> Single<[CollectionResponse]> {
        collectionsSingle(address: address, page: page).flatMap { [unowned self] collections in
            let allCollections = allCollections + collections

            if collections.count == collectionLimit {
                return recursiveCollectionsSingle(address: address, page: page + 1, allCollections: allCollections)
            } else {
                return Single.just(allCollections)
            }
        }
    }

    private func _assetsSingle(address: String? = nil, collectionUid: String? = nil, cursor: String?) -> Single<AssetsResponse> {
        var parameters: Parameters = [
            "include_orders": true,
            "limit": assetLimit
        ]

        if let address = address {
            parameters["owner"] = address
        }

        if let collectionUid = collectionUid {
            parameters["collection_uid"] = collectionUid
        }

        if let cursor = cursor {
            parameters["cursor"] = cursor
        }

        let request = networkManager.session.request("\(apiUrl)/v1/nft/assets", parameters: parameters, encoding: encoding, headers: headers)
        return networkManager.single(request: request)
    }

    private func recursiveAssetsSingle(address: String, cursor: String? = nil, allAssets: [AssetResponse] = []) -> Single<[AssetResponse]> {
        _assetsSingle(address: address, cursor: cursor).flatMap { [unowned self] response in
            let allAssets = allAssets + response.assets

            if let cursor = response.cursor {
                return recursiveAssetsSingle(address: address, cursor: cursor, allAssets: allAssets)
            } else {
                return Single.just(allAssets)
            }
        }
    }

}

extension HsNftProvider: INftProvider {

    func assetCollectionSingle(address: String) -> Single<NftAssetCollection> {
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

    func collectionSingle(uid: String) -> Single<NftCollection> {
        let parameters: Parameters = [
            "include_stats_chart": true,
        ]

        let request = networkManager.session.request("\(apiUrl)/v1/nft/collection/\(uid)", parameters: parameters, encoding: encoding, headers: headers)
        return networkManager.single(request: request).map { [unowned self] response in
            collection(response: response)
        }
    }

    func collectionStatsSingle(uid: String) -> Single<NftCollectionStats> {
        let request = networkManager.session.request("\(apiUrl)/v1/nft/collection/\(uid)/stats", encoding: encoding, headers: headers)
        return networkManager.single(request: request).map { [unowned self] response in
            collectionStats(response: response)
        }
    }

    func assetOrdersSingle(contractAddress: String, tokenId: String) -> Single<[NftAssetOrder]> {
        let parameters: Parameters = [
            "include_orders": true,
        ]

        let request = networkManager.session.request("\(apiUrl)/v1/nft/asset/\(contractAddress)/\(tokenId)", parameters: parameters, encoding: encoding, headers: headers)
        return networkManager.single(request: request).map { [unowned self] (response: SingleAssetResponse) in
            assetOrders(responses: response.orders)
        }
    }

    func assetsSingle(collectionUid: String, cursor: String? = nil) -> Single<PagedNftAssets> {
        _assetsSingle(collectionUid: collectionUid, cursor: cursor).map { [unowned self] response in
            PagedNftAssets(
                    assets: assets(responses: response.assets),
                    cursor: response.cursor
            )
        }
    }

    func collectionsSingle(currencyCode: String) -> Single<[NftCollection]> {
        let parameters: Parameters = [
            "limit": collectionLimit,
//            "currency": currencyCode.lowercased()
        ]

        let request = networkManager.session.request("\(apiUrl)/v1/nft/collections", parameters: parameters, encoding: encoding, headers: headers)
        return networkManager.single(request: request).map { [unowned self] responses in
            collections(responses: responses)
        }
    }

}

extension HsNftProvider {

    private struct CollectionResponse: ImmutableMappable {
        let contracts: [AssetContractResponse]
        let uid: String
        let name: String
        let description: String?
        let imageUrl: String?
        let featuredImageUrl: String?
        let externalUrl: String?
        let discordUrl: String?
        let twitterUsername: String?
        let stats: CollectionStatsResponse

        init(map: Map) throws {
            contracts = (try? map.value("asset_contracts")) ?? []
            uid = try map.value("uid")
            name = try map.value("name")
            description = try? map.value("description")
            imageUrl = try? map.value("image_data.image_url")
            featuredImageUrl = try? map.value("image_data.featured_image_url")
            externalUrl = try? map.value("links.external_url")
            discordUrl = try? map.value("links.discord_url")
            twitterUsername = try? map.value("links.twitter_username")
            stats = try map.value("stats")
        }
    }

    private struct AssetContractResponse: ImmutableMappable {
        let address: String
        let type: String

        init(map: Map) throws {
            address = try map.value("address")
            type = try map.value("type")
        }
    }

    private struct AssetsResponse: ImmutableMappable {
        let cursor: String?
        let assets: [AssetResponse]

        init(map: Map) throws {
            cursor = try? map.value("cursor.next")
            assets = try map.value("assets")
        }
    }

    private struct AssetResponse: ImmutableMappable {
        let contract: AssetContractResponse
        let collectionUid: String
        let tokenId: String
        let name: String?
        let imageUrl: String?
        let imagePreviewUrl: String?
        let description: String?
        let externalLink: String?
        let permalink: String?
        let traits: [TraitResponse]
        let lastSale: SaleResponse?
        let sellOrders: [OrderResponse]

        init(map: Map) throws {
            contract = try map.value("contract")
            collectionUid = try map.value("collection_uid")
            tokenId = try map.value("token_id")
            name = try? map.value("name")
            imageUrl = try? map.value("image_data.image_url")
            imagePreviewUrl = try? map.value("image_data.image_preview_url")
            description = try? map.value("description")
            externalLink = try? map.value("links.external_link")
            permalink = try? map.value("links.permalink")
            traits = try map.value("attributes")
            lastSale = try? map.value("markets_data.last_sale")
            sellOrders = (try? map.value("markets_data.sell_orders")) ?? []
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
            } else if let value: Double = try? map.value("value") {
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
            totalPrice = try map.value("total_price", using: HsNftProvider.stringToDecimalTransform)
            paymentTokenAddress = try map.value("payment_token.address")
        }
    }

    private struct CollectionStatsResponse: ImmutableMappable {
        let totalSupply: Int
        let oneDayChange: Decimal
        let averagePrice7d: Decimal
        let averagePrice30d: Decimal
        let floorPrice: Decimal?
        let totalVolume: Decimal?
        let marketCap: Decimal

        init(map: Map) throws {
            totalSupply = try map.value("total_supply")
            totalVolume = try map.value("total_volume", using: HsNftProvider.doubleToDecimalTransform)
            marketCap = try map.value("market_cap", using: HsNftProvider.doubleToDecimalTransform)
            oneDayChange = try map.value("one_day_change", using: HsNftProvider.doubleToDecimalTransform)
            averagePrice7d = try map.value("seven_day_average_price", using: HsNftProvider.doubleToDecimalTransform)
            averagePrice30d = try map.value("thirty_day_average_price", using: HsNftProvider.doubleToDecimalTransform)
            floorPrice = try? map.value("floor_price", using: HsNftProvider.doubleToDecimalTransform)
        }
    }

    private struct SingleAssetResponse: ImmutableMappable {
        let orders: [OrderResponse]

        init(map: Map) throws {
            orders = (try? map.value("markets_data.orders")) ?? []
        }
    }

    private struct OrderResponse: ImmutableMappable {
        private static let reusableDateFormatter: DateFormatter = {
            let dateFormatter = DateFormatter(withFormat: "yyyy-MM-dd'T'HH:mm:ss", locale: "en_US_POSIX")
            dateFormatter.timeZone = TimeZone(abbreviation: "GMT")!
            return dateFormatter
        }()

        let closingDate: Date
        let currentPrice: Decimal
        let paymentToken: PaymentTokenResponse
        let takerAddress: String
        let side: Int
        let v: Int?

        init(map: Map) throws {
            closingDate = try map.value("closing_date", using: DateFormatterTransform(dateFormatter: Self.reusableDateFormatter))
            currentPrice = try map.value("current_price", using: HsNftProvider.stringToDecimalTransform)
            paymentToken = try map.value("payment_token_contract")
            takerAddress = try map.value("taker.address")
            side = try map.value("side")
            v = try? map.value("v")
        }
    }

    private struct PaymentTokenResponse: ImmutableMappable {
        let address: String
        let decimals: Int
        let ethPrice: Decimal

        init(map: Map) throws {
            address = try map.value("address")
            decimals = try map.value("decimals")
            ethPrice = try map.value("eth_price", using: HsNftProvider.stringToDecimalTransform)
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
