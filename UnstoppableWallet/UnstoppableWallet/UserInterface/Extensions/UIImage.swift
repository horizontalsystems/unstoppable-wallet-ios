import UIKit

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

    static func image(coinCode: String, blockchainType: String? = nil) -> UIImage? {
        var image = UIImage(named: "\(coinCode.lowercased())")

        if image == nil, let blockchainType = blockchainType {
            image = UIImage(named: blockchainType.lowercased())
        }

        return image?.tinted(with: .themeGray)
    }

}
