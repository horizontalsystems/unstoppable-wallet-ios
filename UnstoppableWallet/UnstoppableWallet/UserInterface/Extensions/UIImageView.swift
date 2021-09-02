import UIKit
import Alamofire
import AlamofireImage

extension UIImageView {

    func asyncSetImage(imageBlock: @escaping () -> UIImage?) {
        DispatchQueue.global(qos: .userInitiated).async {
            let image = imageBlock()

            DispatchQueue.main.async {
                self.image = image
            }
        }
    }

    func setImage(withUrlString urlString: String) {
        image = nil

        AF.request(urlString).responseImage { [weak self] response in
            if case .success(let image) = response.result {
                self?.image = image
            }
        }
    }

}
