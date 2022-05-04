import Foundation

struct NftEvent {
    let asset: NftAsset
    let type: EventType
    let date: Date
    let amount: NftPrice?
}

extension NftEvent {

    enum EventType: String, CaseIterable {
        case sale = "sale"
        case list = "list"
        case bid = "bid"
        case bidCancel = "bid_cancel"
        case transfer = "transfer"
    }

}

struct PagedNftEvents {
    let events: [NftEvent]
    let cursor: String?
}
