import UIKit

extension UIButton {

    func setBackgroundColor(color: UIColor, gradient: (colors: [UIColor], height: CGFloat)? = nil, forState state: UIControl.State) {
        let height = gradient?.height ?? 1
        var gradientLayer: CAGradientLayer?

        if let gradient = gradient {
            gradientLayer = CAGradientLayer()
            gradientLayer?.locations = [0.0, 1.0]
            gradientLayer?.colors = gradient.colors.map { $0.cgColor }
            gradientLayer?.frame = CGRect(x: 0, y: 0, width: 1, height: height)
        }

        UIGraphicsBeginImageContext(CGSize(width: 1, height: height))

        if let context = UIGraphicsGetCurrentContext() {
            context.setFillColor(color.cgColor)
            context.fill(CGRect(x: 0, y: 0, width: 1, height: height))
            gradientLayer?.render(in: context)

            let colorImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()

            setBackgroundImage(colorImage, for: state)
        }
    }

}
