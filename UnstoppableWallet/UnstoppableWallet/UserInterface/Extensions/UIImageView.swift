import Alamofire
import Kingfisher
import UIKit

extension UIImageView {
    func setImage(withUrlString urlString: String, placeholder: UIImage?, alternativeUrlString: String? = nil) {
        let options: [KingfisherOptionsInfoItem] = [.scaleFactor(UIScreen.main.scale)]

        if let alternativeUrlString, let alternativeUrl = URL(string: alternativeUrlString) {
            if ImageCache.default.isCached(forKey: alternativeUrlString) {
                kf.setImage(
                    with: alternativeUrl,
                    placeholder: placeholder,
                    options: options
                )
            } else {
                kf.setImage(
                    with: URL(string: urlString),
                    placeholder: placeholder,
                    options: options + [.alternativeSources([.network(alternativeUrl)])]
                )
            }
        } else {
            kf.setImage(
                with: URL(string: urlString),
                placeholder: placeholder,
                options: options
            )

            return
        }
    }
}
