import Foundation
import MarketKit

struct NftEventMetadata {
    let asset: NftAssetMetadata
    let type: EventType?
    let date: Date
    let amount: NftPrice?
}

extension NftEventMetadata {

    enum EventType {
        case list
        case sale
        case offer
        case bid
        case bidCancel
        case transfer
        case approve
        case custom
        case payout
        case cancel
        case bulkCancel
    }

}
