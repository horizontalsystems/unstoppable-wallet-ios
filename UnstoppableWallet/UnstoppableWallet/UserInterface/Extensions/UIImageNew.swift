import UIKit
import MarketKit

extension UIImage {

    static func image(coinType: CoinType) -> UIImage? {
        UIImage(named: "\(coinType.id)") ??
                coinType.blockchainType.map { UIImage(named: "Coin Icon Placeholder - \($0)") } ??
                UIImage(named: "icon_placeholder_24")
    }

}
