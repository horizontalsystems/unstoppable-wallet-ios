import Foundation
import RxSwift
import ObjectMapper
import HsToolKit
import Alamofire
import MarketKit

class OpenSeaNftProvider {
    private let ethereumAddress = "0x0000000000000000000000000000000000000000"
    private let apiUrl = "https://api.opensea.io/api"

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

    private func nftPrice(platformCoin: PlatformCoin?, value: Decimal) -> NftPrice? {
        guard let platformCoin = platformCoin else {
            return nil
        }

        return NftPrice(
                platformCoin: platformCoin,
                value: Decimal(sign: .plus, exponent: -platformCoin.decimals, significand: value)
        )
    }

    private func collections(assetResponses: [AssetResponse]) -> [NftCollection] {
        var collectionResponses = [CollectionResponse]()
        var addresses = [String]()

        for assetResponse in assetResponses {
            if !collectionResponses.contains(where: { $0.slug == assetResponse.collection.slug }) {
                collectionResponses.append(assetResponse.collection)
            }

            if let lastSale = assetResponse.lastSale {
                addresses.append(lastSale.paymentToken.address)
            }
        }

        let platformCoinMap = platformCoinMap(addresses: addresses)

        return collectionResponses.map { collectionResponse in
            let assetResponses = assetResponses.filter { $0.collection.slug == collectionResponse.slug }

            return NftCollection(
                    slug: collectionResponse.slug,
                    name: collectionResponse.name,
                    imageUrl: collectionResponse.imageUrl,
                    floorPrice: nil,
                    assets: assetResponses.map { assetResponse in
                        NftAsset(
                                tokenId: assetResponse.tokenId,
                                name: assetResponse.name,
                                imageUrl: assetResponse.imageUrl,
                                lastPrice: assetResponse.lastSale.flatMap { nftPrice(platformCoin: platformCoinMap[$0.paymentToken.address], value: $0.totalPrice) }
                        )
                    }
            )
        }
    }

}

extension OpenSeaNftProvider: INftProvider {

    func collectionsSingle(address: String) -> Single<[NftCollection]> {
        let parameters: Parameters = [
            "format": "json",
            "limit": 50,
            "owner": address
        ]

        let url = "\(apiUrl)/v1/assets"

        let headers = HTTPHeaders([
            HTTPHeader.userAgent("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_11_5) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/50.0.2661.102 Safari/537.36")
        ])
        let request = networkManager.session.request(url, parameters: parameters, headers: headers)

        return networkManager.single(request: request).map { [weak self] (response: Response) in
            self?.collections(assetResponses: response.assets) ?? []
        }
    }

}

extension OpenSeaNftProvider {

    struct Response: ImmutableMappable {
        let assets: [AssetResponse]

        init(map: Map) throws {
            assets = try map.value("assets")
        }
    }

    struct AssetResponse: ImmutableMappable {
        let tokenId: Decimal
        let name: String?
        let imageUrl: String
        let collection: CollectionResponse
        let lastSale: SaleResponse?

        init(map: Map) throws {
            tokenId = try map.value("token_id", using: OpenSeaNftProvider.stringToDecimalTransform)
            name = try? map.value("name")
            imageUrl = try map.value("image_preview_url")
            collection = try map.value("collection")
            lastSale = try? map.value("last_sale")
        }
    }

    struct SaleResponse: ImmutableMappable {
        let totalPrice: Decimal
        let paymentToken: PaymentTokenResponse

        init(map: Map) throws {
            totalPrice = try map.value("total_price", using: OpenSeaNftProvider.stringToDecimalTransform)
            paymentToken = try map.value("payment_token")
        }
    }

    struct PaymentTokenResponse: ImmutableMappable {
        let address: String

        init(map: Map) throws {
            address = try map.value("address")
        }
    }

    struct CollectionResponse: ImmutableMappable {
        let slug: String
        let name: String
        let imageUrl: String?

        init(map: Map) throws {
            slug = try map.value("slug")
            name = try map.value("name")
            imageUrl = try? map.value("image_url")
        }
    }

    private static let stringToDecimalTransform: TransformOf<Decimal, String> = TransformOf(fromJSON: { string -> Decimal? in
        guard let string = string else { return nil }
        return Decimal(string: string)
    }, toJSON: { (value: Decimal?) in
        guard let value = value else { return nil }
        return value.description
    })

}
