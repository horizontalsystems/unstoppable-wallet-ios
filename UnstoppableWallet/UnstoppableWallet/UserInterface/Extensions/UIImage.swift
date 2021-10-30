import UIKit
import MarketKit

extension UIImage {

    static func qrCodeImage(qrCodeString: String, size: CGFloat) -> UIImage? {
        let data = qrCodeString.data(using: .utf8)

        let filter = CIFilter(name: "CIQRCodeGenerator")!
        filter.setValue(data, forKey: "inputMessage")

        guard let outputImage = filter.outputImage else {
            return nil
        }

        let format = UIGraphicsImageRendererFormat()
        format.scale = UIScreen.main.scale

        let outputSize = CGSize(width: size, height: size)

        return UIGraphicsImageRenderer(size: outputSize, format: format).image { _ in
            let scaleFactor = size / outputImage.extent.width
            let scaledImage = outputImage.transformed(by: CGAffineTransform(scaleX: scaleFactor, y: scaleFactor))
            let image = UIImage(ciImage: scaledImage)

            image.draw(in: CGRect(origin: .zero, size: outputSize))
        }
    }

    static func image(coinType: CoinType) -> UIImage? {
        UIImage(named: "\(coinType.id)") ??
                coinType.blockchainType.map { UIImage(named: "Coin Icon Placeholder - \($0)") } ??
                UIImage(named: "icon_placeholder_24")
    }

    static var appIcon: UIImage? {
        guard let iconsDictionary = Bundle.main.infoDictionary?["CFBundleIcons"] as? [String:Any],
              let primaryIconsDictionary = iconsDictionary["CFBundlePrimaryIcon"] as? [String:Any],
              let iconFiles = primaryIconsDictionary["CFBundleIconFiles"] as? [String],
              let lastIcon = iconFiles.last else {return nil }
        return UIImage(named: lastIcon)
    }

    static func circleImage(size: CGFloat, color: UIColor) -> UIImage? {
        let size = CGSize(width: size, height: size)

        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        let path = UIBezierPath(roundedRect: CGRect(origin: .zero, size: size), cornerRadius: size.width / 2)
        color.setFill()
        path.fill()
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }

}
