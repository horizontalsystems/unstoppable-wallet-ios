import MarketKit
import UIKit

extension CoinTreasury {
    var fundLogoUrl: String {
        let scale = Int(UIScreen.main.scale)
        return "https://cdn.blocksdecoded.com/treasury-icons/\(fundUid)@\(scale)x.png"
    }
}
