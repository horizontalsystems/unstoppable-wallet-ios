import UIKit
import MarketKit

extension Coin {

    var imageUrl: String {
        let scale = Int(UIScreen.main.scale)
        return "https://cdn.blocksdecoded.com/coin-icons/32px/\(uid)@\(scale)x.png"
    }

}
