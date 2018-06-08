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

    static var cryptoYellow: UIColor = UIColor(named: "Yellow") ?? .black
    static var cryptoSilver: UIColor = UIColor(named: "Silver") ?? .black
    static var cryptoGreen: UIColor = UIColor(named: "Green") ?? .black
    static var cryptoSteel50: UIColor = UIColor(named: "Steel50") ?? .black
    static var cryptoDark: UIColor = UIColor(named: "Dark") ?? .black
    static var cryptoGray: UIColor = UIColor(named: "Gray") ?? .black

}
