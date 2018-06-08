import UIKit

extension UIColor {

    public convenience init(hex: Int, alpha: Double = 1) {
        self.init(
                red: CGFloat((hex >> 16) & 0xff) / 255,
                green: CGFloat((hex >> 8) & 0xff) / 255,
                blue: CGFloat(hex & 0xff) / 255,
                alpha: CGFloat(alpha)
        )
    }

    static var walletOrange: UIColor = UIColor(hex: 0xf7b731)

}
