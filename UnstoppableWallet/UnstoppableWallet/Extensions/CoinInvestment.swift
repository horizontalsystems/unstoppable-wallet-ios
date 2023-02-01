import UIKit
import MarketKit

extension CoinInvestment.Fund {

    var logoUrl: String {
        let scale = Int(UIScreen.main.scale)
        return "https://cdn.blocksdecoded.com/fund-icons/\(uid)@\(scale)x.png"
    }

}
