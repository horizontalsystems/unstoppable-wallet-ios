import MarketKit
import UIKit

extension CoinTreasury {
    var fundLogoUrl: String {
        let scale = Int(UIScreen.main.scale)
        return "https://cdn.blocksdecoded.com/treasury-icons/\(fundUid)@\(scale)x.png"
    }
}

extension CoinTreasury: Hashable {
    public static func == (lhs: CoinTreasury, rhs: CoinTreasury) -> Bool {
        lhs.fundUid == rhs.fundUid
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(fundUid)
    }
}
