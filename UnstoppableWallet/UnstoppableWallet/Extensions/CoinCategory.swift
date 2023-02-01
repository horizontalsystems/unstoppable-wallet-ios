import UIKit
import MarketKit

extension CoinCategory {

    var imageUrl: String {
        let scale = Int(UIScreen.main.scale)
        return "https://cdn.blocksdecoded.com/category-icons/\(uid)@\(scale)x.png"
    }

}
