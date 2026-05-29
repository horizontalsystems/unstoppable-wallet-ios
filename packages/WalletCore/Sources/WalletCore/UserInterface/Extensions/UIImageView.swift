import Kingfisher
import UIKit

public extension UIImageView {
    func asyncSetImage(imageBlock: @escaping () -> UIImage?) {
        DispatchQueue.global(qos: .userInitiated).async {
            let image = imageBlock()

            DispatchQueue.main.async {
                self.image = image
            }
        }
    }

    func setImage(withUrlString urlString: String, placeholder: UIImage?) {
        kf.setImage(with: URL(string: urlString), placeholder: placeholder, options: [.scaleFactor(UIScreen.main.scale)])
    }

    internal func setImage(url urlString: String?, alternativeUrl alternativeUrlString: String? = nil, placeholder: UIImage? = nil) {
        image = nil

        let options: [KingfisherOptionsInfoItem] = [.onlyLoadFirstFrame, .transition(.fade(0.5))]
        let url = urlString.flatMap { URL(string: $0) }

        if let alternativeUrlString, let alternativeUrl = URL(string: alternativeUrlString) {
            if ImageCache.default.isCached(forKey: alternativeUrlString) {
                kf.setImage(with: alternativeUrl, placeholder: placeholder, options: options)
            } else {
                kf.setImage(with: url, placeholder: placeholder, options: options + [.alternativeSources([.network(alternativeUrl)])])
            }
        } else {
            kf.setImage(with: url, placeholder: placeholder, options: options)
        }
    }
}
