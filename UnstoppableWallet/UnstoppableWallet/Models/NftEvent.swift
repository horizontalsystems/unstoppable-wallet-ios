import Foundation

struct NftEvent {
    let asset: NftAsset
    let type: EventType?
    let date: Date
    let amount: NftPrice?
}

extension NftEvent {

    enum EventType: String {
        case list = "list"
        case sale = "sale"
        case offer = "offer"
        case bid = "bid"
        case bidCancel = "bid_cancel"
        case transfer = "transfer"
        case approve = "approve"
        case custom = "custom"
        case payout = "payout"
        case cancel = "cancel"
        case bulkCancel = "bulk_cancel"
    }

}

struct PagedNftEvents {
    let events: [NftEvent]
    let cursor: String?
}
