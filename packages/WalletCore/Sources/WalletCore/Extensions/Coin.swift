import MarketKit
import UIKit

extension Coin {
    var imageUrl: String {
        let scale = Int(UIScreen.main.scale)
        return "https://cdn.blocksdecoded.com/coin-icons/32px/\(uid)@\(scale)x.png"
    }

    public static func imageUrl(uid: String) -> String {
        let scale = Int(UIScreen.main.scale)
        return "https://cdn.blocksdecoded.com/coin-icons/32px/\(uid)@\(scale)x.png"
    }

    // Same rule as the server: a coin re-listed on another chain keeps the original coingecko_id
    var isSynthetic: Bool {
        guard let coinGeckoId else { return false }
        return coinGeckoId != uid
    }
}
