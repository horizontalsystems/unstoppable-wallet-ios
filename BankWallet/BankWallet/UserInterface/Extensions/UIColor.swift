import UIKit

extension UIColor {

    static var cryptoThemedDark: UIColor { return (App.shared.localStorage.lightMode ? UIColor(named: "LightThemeDark") : UIColor(named: "Dark")) ?? .black }
    static var cryptoThemedSteel20: UIColor { return (App.shared.localStorage.lightMode ? .white : UIColor(named: "Steel20")) ?? .black }
    static var cryptoThemedWhite: UIColor { return App.shared.localStorage.lightMode ? .black : white }
    static var cryptoThemedClearBackground: UIColor { return App.shared.localStorage.lightMode ? .white : .clear }
    static var cryptoThemedSilver: UIColor { return App.shared.localStorage.lightMode ? .black : .cryptoSilver }

    static var cryptoBarsColor: UIColor = UIColor(named: "BarsColor") ?? .black
    static var cryptoDark: UIColor = UIColor(named: "Dark") ?? .black
    static var cryptoGray: UIColor = UIColor(named: "Gray") ?? .black
    static var cryptoGreen: UIColor = UIColor(named: "Green") ?? .black
    static var cryptoGreenPressed: UIColor = UIColor(named: "GreenPressed") ?? .black
    static var cryptoGreenProgress: UIColor = UIColor(named: "GreenProgress") ?? .black
    static var cryptoLightBackground: UIColor = UIColor(named: "Light Background") ?? .black
    static var cryptoLightGray: UIColor = UIColor(named: "LightGray") ?? .black
    static var cryptoRed: UIColor = UIColor(named: "Red") ?? .black
    static var cryptoRedPressed: UIColor = UIColor(named: "RedPressed") ?? .black
    static var cryptoSilver: UIColor = UIColor(named: "Silver") ?? .black
    static var cryptoSteel20: UIColor = UIColor(named: "Steel20") ?? .black
    static var cryptoWhite50: UIColor = UIColor(named: "White50") ?? .black
    static var cryptoYellow: UIColor = UIColor(named: "Yellow") ?? .black
    static var cryptoYellowPressed: UIColor = UIColor(named: "YellowPressed") ?? .black

}
