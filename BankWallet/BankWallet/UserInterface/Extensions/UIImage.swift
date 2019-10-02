import UIKit

extension UIImage {

    public convenience init?(color: UIColor, size: CGSize = CGSize(width: 1, height: 1)) {
        let rect = CGRect(origin: .zero, size: size)
        UIGraphicsBeginImageContextWithOptions(rect.size, false, 0.0)
        color.setFill()
        UIRectFill(rect)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        guard let cgImage = image?.cgImage else { return nil }
        self.init(cgImage: cgImage)
    }

    public static func gradientImage(fromColor: UIColor, toColor: UIColor, size: CGSize, startPoint: CGPoint = CGPoint(x: 0.5, y: 0), endPoint: CGPoint = CGPoint(x: 0.5, y: 1)) -> UIImage {
        let layer = CAGradientLayer()
        layer.startPoint = startPoint
        layer.endPoint = endPoint
        layer.frame = CGRect(origin: CGPoint.zero, size: size)
        layer.colors = [fromColor.cgColor, toColor.cgColor]

        UIGraphicsBeginImageContext(size);
        if let context = UIGraphicsGetCurrentContext() {
            layer.render(in: context)
            if let image = UIGraphicsGetImageFromCurrentImageContext() {
                UIGraphicsEndImageContext();
                return image
            }
        }

        UIGraphicsEndImageContext();
        return UIImage()
    }

    func tinted(with color: UIColor) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(size, false, scale)

        defer { UIGraphicsEndImageContext() }

        color.set()
        withRenderingMode(.alwaysTemplate).draw(in: CGRect(origin: .zero, size: size))

        return UIGraphicsGetImageFromCurrentImageContext()
    }

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

    convenience init?(coin: Coin) {
        self.init(named: "\(coin.code.lowercased())")
    }

}
