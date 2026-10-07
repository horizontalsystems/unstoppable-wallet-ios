import Alamofire
import Kingfisher
import MarketKit
import UIKit

extension UIImageView {
    func setImage(coin: Coin?, placeholder: String? = nil) {
        setImage(url: coin?.imageUrl, alternativeUrl: coin?.image, placeholder: UIImage(named: placeholder ?? "placeholder_circle"))
        cornerRadius = CGFloat.iconSize32 / 2
    }
}
