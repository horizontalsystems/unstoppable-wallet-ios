import Foundation
import RxSwift
import HsToolKit
import MarketKit
import ObjectMapper
import Alamofire

class ReservoirNftProvider {
    private let baseUrl = "https://api.reservoir.tools"

    private let networkManager: NetworkManager
    private let marketKit: MarketKit.Kit

    init(networkManager: NetworkManager, marketKit: MarketKit.Kit) {
        self.networkManager = networkManager
        self.marketKit = marketKit
    }

    private func events(blockchainType: BlockchainType, responses: [EventResponse]) -> [NftEventMetadata] {
        do {
            let token = try marketKit.token(query: TokenQuery(blockchainType: blockchainType, tokenType: .native))

            return responses.map { response in
                NftEventMetadata(
                        nftUid: response.tokenId.map { .evm(blockchainType: blockchainType, contractAddress: response.contract, tokenId: $0) },
                        previewImageUrl: response.tokenImage,
                        type: eventType(apiEventType: response.type),
                        date: response.date,
                        price: nftPrice(token: token, value: response.price)
                )
            }
        } catch {
            return []
        }
    }

    private func nftPrice(token: Token?, value: Decimal?) -> NftPrice? {
        guard let token = token, let value = value else {
            return nil
        }

        return NftPrice(token: token, value: value)
    }

    private func apiEventType(eventType: NftEventMetadata.EventType?) -> String? {
        guard let eventType = eventType else {
            return nil
        }

        switch eventType {
        case .sale: return "sale"
        case .transfer: return "transfer"
        case .mint: return "mint"
        case .list: return "ask"
        case .listCancel: return "ask_cancel"
        case .offer: return "bid"
        case .offerCancel: return "bid_cancel"
        }
    }

    private func eventType(apiEventType: String?) -> NftEventMetadata.EventType? {
        guard let apiEventType = apiEventType else {
            return nil
        }

        switch apiEventType {
        case "sale": return .sale
        case "transfer": return .transfer
        case "mint": return .mint
        case "ask": return .list
        case "ask_cancel": return .listCancel
        case "bid": return .offer
        case "bid_cancel": return .offerCancel
        default: return nil
        }
    }

}

extension ReservoirNftProvider: INftEventProvider {

    func assetEventsMetadataSingle(nftUid: NftUid, eventType: NftEventMetadata.EventType?, paginationData: PaginationData?) -> Single<([NftEventMetadata], PaginationData?)> {
        var parameters: Parameters = [:]

        if let eventType = apiEventType(eventType: eventType) {
            parameters["types"] = [eventType]
        }

        if let cursor = paginationData?.cursor {
            parameters["continuation"] = cursor
        }

        let request = networkManager.session.request("\(baseUrl)/tokens/\(nftUid.contractAddress):\(nftUid.tokenId)/activity/v4", parameters: parameters)

        return networkManager.single(request: request)
                .map { [weak self] (response: EventsResponse) in
                    guard let strongSelf = self else {
                        throw ProviderError.weakReference
                    }

                    let events = strongSelf.events(blockchainType: nftUid.blockchainType, responses: response.events)

                    return (events, response.cursor.map { .cursor(value: $0) })
                }
    }

    func collectionEventsMetadataSingle(blockchainType: BlockchainType, contractAddress: String, eventType: NftEventMetadata.EventType?, paginationData: PaginationData?) -> Single<([NftEventMetadata], PaginationData?)> {
        var parameters: Parameters = [
            "collection": contractAddress
        ]

        if let eventType = apiEventType(eventType: eventType) {
            parameters["types"] = [eventType]
        }

        if let cursor = paginationData?.cursor {
            parameters["continuation"] = cursor
        }

        let request = networkManager.session.request("\(baseUrl)/collections/activity/v5", parameters: parameters)

        return networkManager.single(request: request)
                .map { [weak self] (response: EventsResponse) in
                    guard let strongSelf = self else {
                        throw ProviderError.weakReference
                    }

                    let events = strongSelf.events(blockchainType: blockchainType, responses: response.events)

                    return (events, response.cursor.map { .cursor(value: $0) })
                }
    }

}

extension ReservoirNftProvider {

    private struct EventResponse: ImmutableMappable {
        let contract: String
        let tokenId: String?
        let tokenImage: String?
        let type: String
        let date: Date
        let price: Decimal?

        init(map: Map) throws {
            contract = try map.value("contract")
            tokenId = try? map.value("token.tokenId")
            tokenImage = try? map.value("token.tokenImage")
            type = try map.value("type")
            date = try map.value("timestamp", using: DateTransform())
            price = try? map.value("price", using: Transform.doubleToDecimalTransform)
        }
    }

    private struct EventsResponse: ImmutableMappable {
        let cursor: String?
        let events: [EventResponse]

        init(map: Map) throws {
            cursor = try? map.value("continuation")
            events = try map.value("activities")
        }
    }

    enum ProviderError: Error {
        case weakReference
    }

}
