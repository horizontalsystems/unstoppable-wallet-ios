import UIKit
import MarketKit

extension FullCoin {

    var imagePlaceholder: UIImage? {
        platforms.count == 1 ? platforms.first?.coinType.imagePlaceholder : UIImage(named: "icon_placeholder_24")
    }

}
