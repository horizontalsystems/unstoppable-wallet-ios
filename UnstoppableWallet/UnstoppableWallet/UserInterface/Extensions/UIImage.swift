import UIKit
import CoinKit

extension UIImage {

    convenience init?(qrCodeString: String, size: CGFloat) {
        let data = qrCodeString.data(using: .utf8)

        let filter = CIFilter(name: "CIQRCodeGenerator")!
        filter.setValue(data, forKey: "inputMessage")

        guard let outputImage = filter.outputImage else {
            return nil
        }

        let scaleFactor = size / outputImage.extent.width
        let scaledImage = outputImage.transformed(by: CGAffineTransform(scaleX: scaleFactor, y: scaleFactor))

        self.init(ciImage: scaledImage)
    }

    static func image(coinType: CoinType) -> UIImage? {
        UIImage(named: "\(coinType.id)") ??
                coinType.blockchainType.map { UIImage(named: $0.lowercased()) } ??
                UIImage(named: "icon_placeholder_24")
    }

}
