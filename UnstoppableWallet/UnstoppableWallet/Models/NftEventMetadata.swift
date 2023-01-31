import Foundation
import MarketKit

struct NftEventMetadata {
    let nftUid: NftUid?
    let previewImageUrl: String?
    let type: EventType?
    let date: Date
    let price: NftPrice?
}

extension NftEventMetadata {

    enum EventType {
        case sale
        case transfer
        case mint
        case list
        case listCancel
        case offer
        case offerCancel
    }

}
