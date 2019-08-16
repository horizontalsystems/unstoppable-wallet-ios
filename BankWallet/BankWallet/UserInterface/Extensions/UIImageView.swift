import UIKit

extension UIImageView {

    func asyncSetImage(imageBlock: @escaping () -> (UIImage?)) {
        DispatchQueue.global(qos: .userInitiated).async {
            let image = imageBlock()

            DispatchQueue.main.async {
                self.image = image
            }
        }
    }

}
