import Foundation
import RxSwift
import HsToolKit
import MarketKit
import ObjectMapper
import Alamofire

class OpenSeaNftProvider {
    private let baseUrl = "https://api.opensea.io/api/v1"
    private let collectionLimit = 300
    private let assetLimit = 30
    private let zeroAddress = "0x0000000000000000000000000000000000000000"

    private let networkManager: NetworkManager
    private let marketKit: MarketKit.Kit
    private let hsBaseUrl: String
    private let headers: HTTPHeaders
    private let hsHeaders: HTTPHeaders?
    private let encoding: ParameterEncoding = URLEncoding(arrayEncoding: .noBrackets, boolEncoding: .literal)

    init(networkManager: NetworkManager, marketKit: MarketKit.Kit, appConfigProvider: AppConfigProvider) {
        self.networkManager = networkManager
        self.marketKit = marketKit

        headers = HTTPHeaders([
            HTTPHeader.userAgent("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_11_5) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/50.0.2661.102 Safari/537.36")
        ])

        hsBaseUrl = appConfigProvider.marketApiUrl
        hsHeaders = appConfigProvider.hsProviderApiKey.flatMap { HTTPHeaders([HTTPHeader(name: "apikey", value: $0)]) }
    }

    private func collectionsSingle(address: String, offset: Int) -> Single<[CollectionResponse]> {
        let parameters: Parameters = [
            "asset_owner": address,
            "limit": collectionLimit,
            "offset": offset,
            "format": "json"
        ]

        let request = networkManager.session.request("\(baseUrl)/collections", parameters: parameters, encoding: encoding, headers: headers)
        return networkManager.single(request: request)
    }

    private func assetsSingle(address: String? = nil, collection: String? = nil, cursor: String? = nil) -> Single<AssetsResponse> {
        var parameters: Parameters = [
            "include_orders": true,
            "limit": assetLimit,
            "format": "json"
        ]

        if let address = address {
            parameters["owner"] = address
        }

        if let collection = collection {
            parameters["collection"] = collection
        }

        if let cursor = cursor {
            parameters["cursor"] = cursor
        }

        let request = networkManager.session.request("\(baseUrl)/assets", parameters: parameters, encoding: encoding, headers: headers)
        return networkManager.single(request: request)
    }

    private func assetsSingle(references: [AssetReference]) -> Single<AssetsResponse> {
        let parameters: Parameters = [
            "asset_contract_addresses": references.map { $0.contractAddress },
            "token_ids": references.map { $0.tokenId },
            "limit": assetLimit,
            "format": "json"
        ]

        let request = networkManager.session.request("\(baseUrl)/assets", parameters: parameters, encoding: encoding, headers: headers)
        return networkManager.single(request: request)
    }

    private func assetSingle(contractAddress: String, tokenId: String) -> Single<AssetResponse> {
        let parameters: Parameters = [
            "include_orders": true,
            "format": "json"
        ]

        let request = networkManager.session.request("\(baseUrl)/asset/\(contractAddress)/\(tokenId)", parameters: parameters, encoding: encoding, headers: headers)
        return networkManager.single(request: request)
    }

    private func collectionSingle(slug: String) -> Single<SingleCollectionResponse> {
        let parameters: Parameters = [
            "format": "json"
        ]

        let request = networkManager.session.request("\(baseUrl)/collection/\(slug)", parameters: parameters, encoding: encoding, headers: headers)
        return networkManager.single(request: request)
    }

    private func eventsSingle(collection: String? = nil, contractAddress: String? = nil, tokenId: String? = nil, eventType: String?, cursor: String?) -> Single<EventsResponse> {
        var parameters: Parameters = [
            "simplified": true
        ]

        if let collection = collection {
            parameters["collection_slug"] = collection
        }

        if let contractAddress = contractAddress {
            parameters["asset_contract_address"] = contractAddress
        }

        if let tokenId = tokenId {
            parameters["token_id"] = tokenId
        }

        if let eventType = eventType {
            parameters["event_type"] = eventType
        }

        if let cursor = cursor {
            parameters["cursor"] = cursor
        }

        let request = networkManager.session.request("\(hsBaseUrl)/v1/nft/events", parameters: parameters, encoding: encoding, headers: hsHeaders)
        return networkManager.single(request: request)
    }

    private func recursiveCollectionsSingle(address: String, offset: Int = 0, allCollections: [CollectionResponse] = []) -> Single<[CollectionResponse]> {
        collectionsSingle(address: address, offset: offset)
                .flatMap { [weak self] collections in
                    guard let strongSelf = self else {
                        throw ProviderError.weakReference
                    }

                    let allCollections = allCollections + collections

                    if collections.count == strongSelf.collectionLimit {
                        return strongSelf.recursiveCollectionsSingle(address: address, offset: allCollections.count, allCollections: allCollections)
                    } else {
                        return Single.just(allCollections)
                    }
                }
    }

    private func recursiveAssetsSingle(address: String, cursor: String? = nil, allAssets: [AssetResponse] = []) -> Single<[AssetResponse]> {
        assetsSingle(address: address, cursor: cursor)
                .flatMap { [weak self] response in
                    guard let strongSelf = self else {
                        throw ProviderError.weakReference
                    }

                    let allAssets = allAssets + response.assets

                    if let cursor = response.cursor {
                        return strongSelf.recursiveAssetsSingle(address: address, cursor: cursor, allAssets: allAssets)
                    } else {
                        return Single.just(allAssets)
                    }
                }
    }

    private func collections(blockchainType: BlockchainType, responses: [CollectionResponse]) -> [NftCollectionMetadata] {
        let baseToken = try? marketKit.token(query: TokenQuery(blockchainType: blockchainType, tokenType: .native))

        return responses.map { response in
            collection(blockchainType: blockchainType, response: response, baseToken: baseToken)
        }
    }

    private func collection(blockchainType: BlockchainType, response: CollectionResponse, baseToken: Token? = nil) -> NftCollectionMetadata {
        let baseToken = baseToken ?? (try? marketKit.token(query: TokenQuery(blockchainType: blockchainType, tokenType: .native)))

        return NftCollectionMetadata(
                blockchainType: blockchainType,
                providerUid: response.slug,
                contracts: response.contracts.map { $0.address },
                name: response.name,
                description: response.description,
                imageUrl: response.largeImageUrl,
                thumbnailImageUrl: response.imageUrl,
                externalLink: response.externalUrl,
                discordLink: response.discordUrl,
                twitterUsername: response.twitterUsername,
                count: response.stats?.count,
                ownerCount: response.stats?.ownerCount,
                totalSupply: response.stats?.totalSupply,
                totalVolume: response.stats?.totalVolume,
                floorPrice: nftPrice(token: baseToken, value: response.stats?.floorPrice, shift: false),
                marketCap: nftPrice(token: baseToken, value: response.stats?.marketCap, shift: false),
                royalty: response.devSellerFeeBasisPoints / 100,
                inceptionDate: response.contracts.first?.createdDate,
                volume1d: nftPrice(token: baseToken, value: response.stats?.oneDayVolume, shift: false),
                change1d: response.stats?.oneDayChange,
                sales1d: response.stats?.oneDaySales,
                averagePrice1d: nftPrice(token: baseToken, value: response.stats?.oneDayAveragePrice, shift: false),
                volume7d: nftPrice(token: baseToken, value: response.stats?.sevenDayVolume, shift: false),
                change7d: response.stats?.sevenDayChange,
                sales7d: response.stats?.sevenDaySales,
                averagePrice7d: nftPrice(token: baseToken, value: response.stats?.sevenDayAveragePrice, shift: false),
                volume30d: nftPrice(token: baseToken, value: response.stats?.thirtyDayVolume, shift: false),
                change30d: response.stats?.thirtyDayChange,
                sales30d: response.stats?.thirtyDaySales,
                averagePrice30d: nftPrice(token: baseToken, value: response.stats?.thirtyDayAveragePrice, shift: false)
        )
    }

    private func assets(blockchainType: BlockchainType, responses: [AssetResponse]) -> [NftAssetMetadata] {
        var addresses = Set<String>()

        for response in responses {
            if let lastSale = response.lastSale {
                addresses.insert(lastSale.paymentTokenAddress.lowercased())
            }

            for order in response.orders {
                for offer in order.offers + order.considerations {
                    addresses.insert(offer.token.lowercased())
                }
            }
        }

        let tokenMap = tokenMap(blockchainType: blockchainType, addresses: Array(addresses))

        return responses.map { response in
            asset(blockchainType: blockchainType, response: response, tokenMap: tokenMap)
        }
    }

    private func assetsBrief(requestedNftUids: [NftUid], responses: [AssetResponse]) -> [NftAssetBriefMetadata] {
        requestedNftUids.map { nftUid in
            let response = responses.first { $0.contract.address == nftUid.contractAddress && $0.tokenId == nftUid.tokenId }

            return NftAssetBriefMetadata(
                    nftUid: nftUid,
                    providerCollectionUid: response?.collection.slug,
                    name: response?.name,
                    imageUrl: response?.imageUrl,
                    previewImageUrl: response?.imagePreviewUrl
            )
        }
    }

    private func asset(blockchainType: BlockchainType, response: AssetResponse, tokenMap: [String: Token]? = nil) -> NftAssetMetadata {
        let map: [String: Token]

        if let tokenMap = tokenMap {
            map = tokenMap
        } else {
            var addresses = Set<String>()

            if let lastSale = response.lastSale {
                addresses.insert(lastSale.paymentTokenAddress.lowercased())
            }
            for order in response.orders {
                for offer in order.offers + order.considerations {
                    addresses.insert(offer.token.lowercased())
                }
            }

            map = self.tokenMap(blockchainType: blockchainType, addresses: Array(addresses))
        }

        let bidOrders = response.orders.filter { $0.side == "bid" && $0.orderType == "criteria" }
        let offers = bidOrders.compactMap { order -> NftPrice? in
            guard let offer = order.offers.first, let token = map[offer.token.lowercased()] else {
                return nil
            }

            return nftPrice(token: token, value: order.currentPrice, shift: true)
        }

        var saleInfo: NftAssetMetadata.SaleInfo?

        let basicAskOrders = response.orders.filter { $0.side == "ask" && $0.orderType == "basic" }
        let englishAskOrders = response.orders.filter { $0.side == "ask" && $0.orderType == "english" }

        if !basicAskOrders.isEmpty {
            saleInfo = self.saleInfo(type: .onSale, orders: basicAskOrders, map: map)
        } else if !englishAskOrders.isEmpty {
            saleInfo = self.saleInfo(type: .onAuction, orders: englishAskOrders, map: map)
        }

        return NftAssetMetadata(
                nftUid: .evm(blockchainType: blockchainType, contractAddress: response.contract.address, tokenId: response.tokenId),
                providerCollectionUid: response.collection.slug,
                name: response.name,
                imageUrl: response.imageUrl,
                previewImageUrl: response.imagePreviewUrl,
                description: response.description,
                nftType: response.contract.schemaName,
                externalLink: response.externalLink,
                providerLink: response.permalink,
                traits: response.traits.map { NftAssetMetadata.Trait(type: $0.type, value: $0.value, count: $0.count) },
                providerTraitLink: "https://opensea.io/assets/\(response.collection.slug)?search[stringTraits][0][name]=$traitName&search[stringTraits][0][values][0]=$traitValue&search[sortAscending]=true&search[sortBy]=PRICE",
                lastSalePrice: response.lastSale.flatMap { nftPrice(token: map[$0.paymentTokenAddress.lowercased()], value: $0.totalPrice, shift: true) },
                offers: offers,
                saleInfo: saleInfo
        )
    }

    private func saleInfo(type: NftAssetMetadata.SaleType, orders: [OrderResponse], map: [String: Token]) -> NftAssetMetadata.SaleInfo {
        NftAssetMetadata.SaleInfo(
                type: type,
                listings: orders.compactMap { order -> NftAssetMetadata.SaleListing? in
                    guard let consideration = order.considerations.first, let token = map[consideration.token.lowercased()] else {
                        return nil
                    }

                    return NftAssetMetadata.SaleListing(
                            untilDate: order.expirationDate,
                            price: nftPrice(token: token, value: order.currentPrice, shift: true)
                    )
                }
        )
    }

    private func events(blockchainType: BlockchainType, responses: [EventResponse]) -> [NftEventMetadata] {
        var addresses = Set<String>()

        for response in responses {
            if let paymentToken = response.paymentToken {
                addresses.insert(paymentToken.address.lowercased())
            }
        }

        let tokenMap = tokenMap(blockchainType: blockchainType, addresses: Array(addresses))

        return responses.compactMap { response in
            var amount: NftPrice?

            if let paymentToken = response.paymentToken, let value = response.amount {
                amount = nftPrice(token: tokenMap[paymentToken.address.lowercased()], value: value, shift: true)
            }

            guard let assetResponse = response.asset else {
                return nil
            }

            return NftEventMetadata(
                    asset: asset(blockchainType: blockchainType, response: assetResponse, tokenMap: [:]),
                    type: eventType(openSeaEventType: response.type),
                    date: response.date,
                    amount: amount
            )
        }
    }

    private func nftPrice(token: Token?, value: Decimal?, shift: Bool) -> NftPrice? {
        guard let token = token, let value = value else {
            return nil
        }

        return nftPrice(token: token, value: value, shift: shift)
    }

    private func nftPrice(token: Token, value: Decimal, shift: Bool) -> NftPrice {
        NftPrice(
                token: token,
                value: shift ? Decimal(sign: .plus, exponent: -token.decimals, significand: value) : value
        )
    }

    private func tokenType(address: String) -> TokenType {
        if address == zeroAddress {
            return .native
        } else {
            return .eip20(address: address)
        }
    }

    private func tokenMap(blockchainType: BlockchainType, addresses: [String]) -> [String: Token] {
        do {
            var map = [String: Token]()
            let tokenTypes = addresses.map { tokenType(address: $0) }
            let tokens = try marketKit.tokens(queries: tokenTypes.map { TokenQuery(blockchainType: blockchainType, tokenType: $0) })

            for token in tokens {
                switch token.type {
                case .native:
                    map[zeroAddress] = token
                case .eip20(let address):
                    map[address.lowercased()] = token
                default:
                    ()
                }
            }

            return map
        } catch {
            return [:]
        }
    }

    private func openSeaEventType(eventType: NftEventMetadata.EventType?) -> String? {
        guard let eventType = eventType else {
            return nil
        }

        switch eventType {
        case .list: return "created"
        case .sale: return "successful"
        case .offer: return "offer_entered"
        case .bid: return "bid_entered"
        case .bidCancel: return "bid_withdrawn"
        case .transfer: return "transfer"
        case .approve: return "approve"
        case .custom: return "custom"
        case .payout: return "payout"
        case .cancel: return "cancelled"
        case .bulkCancel: return "bulk_cancel"
        }
    }

    private func eventType(openSeaEventType: String?) -> NftEventMetadata.EventType? {
        guard let openSeaEventType = openSeaEventType else {
            return nil
        }

        switch openSeaEventType {
        case "created": return .list
        case "successful": return .sale
        case "offer_entered": return .offer
        case "bid_entered": return .bid
        case "bid_withdrawn": return .bidCancel
        case "transfer": return .transfer
        case "approve": return .approve
        case "custom": return .custom
        case "payout": return .payout
        case "cancelled": return .cancel
        case "bulk_cancel": return .bulkCancel
        default: return nil
        }
    }

}

extension OpenSeaNftProvider: INftProvider {

    var title: String {
        "OpenSea"
    }

    func collectionLink(providerUid: String) -> String? {
        "https://opensea.io/collection/\(providerUid)"
    }

    func addressMetadataSingle(blockchainType: BlockchainType, address: String) -> Single<NftAddressMetadata> {
        let collectionsSingle = recursiveCollectionsSingle(address: address).map { [weak self] responses -> [NftCollectionMetadata] in
            guard let strongSelf = self else {
                throw ProviderError.weakReference
            }

            return strongSelf.collections(blockchainType: blockchainType, responses: responses)
        }

        let assetsSingle = recursiveAssetsSingle(address: address).map { [weak self] responses -> [NftAssetMetadata] in
            guard let strongSelf = self else {
                throw ProviderError.weakReference
            }

            return strongSelf.assets(blockchainType: blockchainType, responses: responses)
        }

        return Single.zip(collectionsSingle, assetsSingle)
                .map { collections, assets in
                    let collectionsMetadata = collections.map { collection in
                        NftCollectionShortMetadata(
                                providerUid: collection.providerUid,
                                name: collection.name,
                                thumbnailImageUrl: collection.imageUrl ?? collection.thumbnailImageUrl,
                                averagePrice7d: collection.averagePrice7d,
                                averagePrice30d: collection.averagePrice30d
                        )
                    }

                    let assetsMetadata = assets.map { asset in
                        NftAssetShortMetadata(
                                nftUid: asset.nftUid,
                                providerCollectionUid: asset.providerCollectionUid,
                                name: asset.name,
                                previewImageUrl: asset.previewImageUrl,
                                onSale: asset.saleInfo != nil,
                                lastSalePrice: asset.lastSalePrice
                        )
                    }

                    return NftAddressMetadata(collections: collectionsMetadata, assets: assetsMetadata)
                }
    }

    func assetsBriefMetadataSingle(nftUids: [NftUid]) -> Single<[NftAssetBriefMetadata]> {
        let references = nftUids.map { nftUid in
            AssetReference(contractAddress: nftUid.contractAddress, tokenId: nftUid.tokenId)
        }

        let chunkedReferences = stride(from: 0, to: references.count, by: assetLimit).map {
            Array(references[$0..<min($0 + assetLimit, references.count)])
        }

        let singles = chunkedReferences.map {
            assetsSingle(references: $0)
        }

        return Single.zip(singles)
                .map { [weak self] assetsResponses in
                    guard let strongSelf = self else {
                        throw ProviderError.weakReference
                    }

                    let assets = assetsResponses.map { $0.assets }.reduce([], +)

                    return strongSelf.assetsBrief(requestedNftUids: nftUids, responses: assets)
                }
    }

    func extendedAssetMetadataSingle(nftUid: NftUid, providerCollectionUid: String) -> Single<(NftAssetMetadata, NftCollectionMetadata)> {
        Single.zip(
                        assetSingle(contractAddress: nftUid.contractAddress, tokenId: nftUid.tokenId),
                        collectionSingle(slug: providerCollectionUid)
        )
                .map { [weak self] assetResponse, collectionResponse in
                    guard let strongSelf = self else {
                        throw ProviderError.weakReference
                    }

                    return (
                            strongSelf.asset(blockchainType: nftUid.blockchainType, response: assetResponse),
                            strongSelf.collection(blockchainType: nftUid.blockchainType, response: collectionResponse.collection)
                    )
                }
    }

    func collectionAssetsMetadataSingle(blockchainType: BlockchainType, providerCollectionUid: String, paginationData: PaginationData?) -> Single<([NftAssetMetadata], PaginationData?)> {
        assetsSingle(collection: providerCollectionUid, cursor: paginationData?.cursor)
                .map { [weak self] response in
                    guard let strongSelf = self else {
                        throw ProviderError.weakReference
                    }

                    let assets = strongSelf.assets(blockchainType: blockchainType, responses: response.assets)

                    return (assets, response.cursor.map { .cursor(value: $0) })
                }
    }

    func collectionMetadataSingle(blockchainType: BlockchainType, providerUid: String) -> Single<NftCollectionMetadata> {
        collectionSingle(slug: providerUid)
                .map { [weak self] response in
                    guard let strongSelf = self else {
                        throw ProviderError.weakReference
                    }

                    return strongSelf.collection(blockchainType: blockchainType, response: response.collection)
                }
    }

    func assetEventsMetadataSingle(nftUid: NftUid, eventType: NftEventMetadata.EventType?, paginationData: PaginationData?) -> Single<([NftEventMetadata], PaginationData?)> {
        eventsSingle(contractAddress: nftUid.contractAddress, tokenId: nftUid.tokenId, eventType: openSeaEventType(eventType: eventType), cursor: paginationData?.cursor)
                .map { [weak self] response in
                    guard let strongSelf = self else {
                        throw ProviderError.weakReference
                    }

                    let events = strongSelf.events(blockchainType: nftUid.blockchainType, responses: response.events)

                    return (events, response.cursor.map { .cursor(value: $0) })
                }
    }

    func collectionEventsMetadataSingle(blockchainType: BlockchainType, providerUid: String, eventType: NftEventMetadata.EventType?, paginationData: PaginationData?) -> Single<([NftEventMetadata], PaginationData?)> {
        eventsSingle(collection: providerUid, eventType: openSeaEventType(eventType: eventType), cursor: paginationData?.cursor)
                .map { [weak self] response in
                    guard let strongSelf = self else {
                        throw ProviderError.weakReference
                    }

                    let events = strongSelf.events(blockchainType: blockchainType, responses: response.events)

                    return (events, response.cursor.map { .cursor(value: $0) })
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
        let largeImageUrl: String?
        let externalUrl: String?
        let discordUrl: String?
        let twitterUsername: String?
        let devSellerFeeBasisPoints: Decimal
        let stats: CollectionStatsResponse?

        init(map: Map) throws {
            contracts = (try? map.value("primary_asset_contracts")) ?? []
            slug = try map.value("slug")
            name = try map.value("name")
            description = try? map.value("description")
            imageUrl = try? map.value("image_url")
            largeImageUrl = try? map.value("large_image_url")
            externalUrl = try? map.value("external_url")
            discordUrl = try? map.value("discord_url")
            twitterUsername = try? map.value("twitter_username")
            devSellerFeeBasisPoints = try map.value("dev_seller_fee_basis_points", using: Transform.stringToDecimalTransform)
            stats = try? map.value("stats")
        }
    }

    private struct AssetResponse: ImmutableMappable {
        let contract: AssetContractResponse
        let collection: CollectionResponse
        let tokenId: String
        let name: String?
        let imageUrl: String?
        let imagePreviewUrl: String?
        let description: String?
        let externalLink: String?
        let permalink: String?
        let traits: [TraitResponse]
        let lastSale: SaleResponse?
        let orders: [OrderResponse]

        init(map: Map) throws {
            contract = try map.value("asset_contract")
            collection = try map.value("collection")
            tokenId = try map.value("token_id")
            name = try? map.value("name")
            imageUrl = try? map.value("image_url")
            imagePreviewUrl = try? map.value("image_preview_url")
            description = try? map.value("description")
            externalLink = try? map.value("external_link")
            permalink = try? map.value("permalink")
            traits = (try? map.value("traits")) ?? []
            lastSale = try? map.value("last_sale")
            orders = (try? map.value("seaport_sell_orders")) ?? []
        }
    }

    private struct AssetContractResponse: ImmutableMappable {
        private static let reusableDateFormatter: DateFormatter = {
            let dateFormatter = DateFormatter(withFormat: "yyyy-MM-dd'T'HH:mm:ss.SSS", locale: "en_US_POSIX")
            dateFormatter.timeZone = TimeZone(abbreviation: "GMT")!
            return dateFormatter
        }()

        let address: String
        let createdDate: Date
        let schemaName: String

        init(map: Map) throws {
            address = try map.value("address")
            createdDate = try map.value("created_date", using: DateFormatterTransform(dateFormatter: Self.reusableDateFormatter))
            schemaName = try map.value("schema_name")
        }
    }

    private struct CollectionStatsResponse: ImmutableMappable {
        let oneDayVolume: Decimal
        let oneDayChange: Decimal
        let oneDaySales: Int
        let oneDayAveragePrice: Decimal
        let sevenDayVolume: Decimal
        let sevenDayChange: Decimal
        let sevenDaySales: Int
        let sevenDayAveragePrice: Decimal
        let thirtyDayVolume: Decimal
        let thirtyDayChange: Decimal
        let thirtyDaySales: Int
        let thirtyDayAveragePrice: Decimal
        let totalVolume: Decimal?
        let totalSupply: Int
        let count: Int?
        let ownerCount: Int?
        let marketCap: Decimal
        let floorPrice: Decimal?

        init(map: Map) throws {
            oneDayVolume = try map.value("one_day_volume", using: Transform.doubleToDecimalTransform)
            oneDayChange = try map.value("one_day_change", using: Transform.doubleToDecimalTransform)
            oneDaySales = try map.value("one_day_sales")
            oneDayAveragePrice = try map.value("one_day_average_price", using: Transform.doubleToDecimalTransform)
            sevenDayVolume = try map.value("seven_day_volume", using: Transform.doubleToDecimalTransform)
            sevenDayChange = try map.value("seven_day_change", using: Transform.doubleToDecimalTransform)
            sevenDaySales = try map.value("seven_day_sales")
            sevenDayAveragePrice = try map.value("seven_day_average_price", using: Transform.doubleToDecimalTransform)
            thirtyDayVolume = try map.value("thirty_day_volume", using: Transform.doubleToDecimalTransform)
            thirtyDayChange = try map.value("thirty_day_change", using: Transform.doubleToDecimalTransform)
            thirtyDaySales = try map.value("thirty_day_sales")
            thirtyDayAveragePrice = try map.value("thirty_day_average_price", using: Transform.doubleToDecimalTransform)
            totalVolume = try map.value("total_volume", using: Transform.doubleToDecimalTransform)
            totalSupply = try map.value("total_supply")
            count = try? map.value("count")
            ownerCount = try? map.value("num_owners")
            marketCap = try map.value("market_cap", using: Transform.doubleToDecimalTransform)
            floorPrice = try? map.value("floor_price", using: Transform.doubleToDecimalTransform)
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
            totalPrice = try map.value("total_price", using: Transform.stringToDecimalTransform)
            paymentTokenAddress = try map.value("payment_token.address")
        }
    }

    private struct OrderResponse: ImmutableMappable {
        let expirationDate: Date
        let offers: [OrderOfferResponse]
        let considerations: [OrderOfferResponse]
        let currentPrice: Decimal
        let side: String
        let orderType: String

        init(map: Map) throws {
            expirationDate = try map.value("expiration_time", using: DateTransform(unit: .seconds))
            offers = try map.value("protocol_data.parameters.offer")
            considerations = try map.value("protocol_data.parameters.consideration")
            currentPrice = try map.value("current_price", using: Transform.stringToDecimalTransform)
            side = try map.value("side")
            orderType = try map.value("order_type")
        }
    }

    private struct OrderOfferResponse: ImmutableMappable {
        let token: String

        init(map: Map) throws {
            token = try map.value("token")
        }
    }

    private struct PaymentTokenResponse: ImmutableMappable {
        let address: String
        let decimals: Int
        let ethPrice: Decimal

        init(map: Map) throws {
            address = try map.value("address")
            decimals = try map.value("decimals")
            ethPrice = try map.value("eth_price", using: Transform.stringToDecimalTransform)
        }
    }

    private struct EventResponse: ImmutableMappable {
        private static let reusableDateFormatter: DateFormatter = {
            let dateFormatter = DateFormatter(withFormat: "yyyy-MM-dd'T'HH:mm:ss", locale: "en_US_POSIX")
            dateFormatter.timeZone = TimeZone(abbreviation: "GMT")!
            return dateFormatter
        }()
        private static let reusableDateFormatter2: DateFormatter = {
            let dateFormatter = DateFormatter(withFormat: "yyyy-MM-dd'T'HH:mm:ss.SSS", locale: "en_US_POSIX")
            dateFormatter.timeZone = TimeZone(abbreviation: "GMT")!
            return dateFormatter
        }()

        let asset: AssetResponse?
        let type: String
        let date: Date
        let amount: Decimal?
        let paymentToken: PaymentTokenResponse?

        init(map: Map) throws {
            asset = try? map.value("asset")
            type = try map.value("event_type")
            date = try (try? map.value("event_timestamp", using: DateFormatterTransform(dateFormatter: Self.reusableDateFormatter))) ?? map.value("event_timestamp", using: DateFormatterTransform(dateFormatter: Self.reusableDateFormatter2))
            amount = try? map.value("total_price", using: Transform.stringToDecimalTransform)
            paymentToken = try? map.value("payment_token")
        }
    }

    private struct AssetsResponse: ImmutableMappable {
        let cursor: String?
        let assets: [AssetResponse]

        init(map: Map) throws {
            cursor = try? map.value("next")
            assets = try map.value("assets")
        }
    }

    private struct EventsResponse: ImmutableMappable {
        let cursor: String?
        let events: [EventResponse]

        init(map: Map) throws {
            cursor = try? map.value("next")
            events = try map.value("asset_events")
        }
    }

    private struct SingleCollectionResponse: ImmutableMappable {
        let collection: CollectionResponse

        init(map: Map) throws {
            collection = try map.value("collection")
        }
    }

    private struct AssetReference {
        let contractAddress: String
        let tokenId: String
    }

    enum ProviderError: Error {
        case weakReference
    }

}
