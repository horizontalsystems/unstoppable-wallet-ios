import Alamofire
import Kingfisher
import MarketKit
import UIKit

extension UIImageView {
    func setImage(coin: Coin?, placeholder: String? = nil) {
        let options: [KingfisherOptionsInfoItem] = [.scaleFactor(UIScreen.main.scale)]
        let placeholder = UIImage(named: placeholder ?? "placeholder_circle_32")

        if let alternativeUrlString = coin?.image, let alternativeUrl = URL(string: alternativeUrlString) {
            if ImageCache.default.isCached(forKey: alternativeUrlString) {
                kf.setImage(
                    with: alternativeUrl,
                    placeholder: placeholder,
                    options: options
                )
            } else {
                kf.setImage(
                    with: URL(string: coin?.imageUrl ?? ""),
                    placeholder: placeholder,
                    options: options + [.alternativeSources([.network(alternativeUrl)])]
                )
            }
        } else {
            kf.setImage(
                with: URL(string: coin?.imageUrl ?? ""),
                placeholder: placeholder,
                options: options
            )

            return
        }

        cornerRadius = CGFloat.iconSize32 / 2
    }
}
