import UIKit

extension UIColor {
    static var crypto_Dark_LightBackground: UIColor { return App.shared.localStorage.lightMode ? .cryptoLightBackground : .cryptoDark }
    static var crypto_Dark_Bars: UIColor { return App.shared.localStorage.lightMode ? .cryptoBars : .cryptoDark }
    static var crypto_Bars_Dark: UIColor { return App.shared.localStorage.lightMode ? .cryptoDark : .cryptoBars }
    static var crypto_Dark96_Bars96: UIColor { return App.shared.localStorage.lightMode ? .cryptoBars96 : .cryptoDark96 }
    static var crypto_Steel20_White: UIColor { return App.shared.localStorage.lightMode ? .white : .cryptoSteel20 }
    static var crypto_Steel40OnDark_Steel20: UIColor { return App.shared.localStorage.lightMode ? .cryptoSteel20 : .cryptoSteel40OnDark }
    static var crypto_Steel20_Steel40: UIColor { return App.shared.localStorage.lightMode ? .cryptoSteel20 : .cryptoSteel40 }
    static var crypto_Steel20_Clear: UIColor { return App.shared.localStorage.lightMode ? .cryptoSteel20 : .clear }
    static var crypto_White_Black: UIColor { return App.shared.localStorage.lightMode ? .black : white }
    static var crypto_Bars_Black: UIColor { return App.shared.localStorage.lightMode ? .black : cryptoBars }
    static var crypto_Black_Bars: UIColor { return App.shared.localStorage.lightMode ? .cryptoBars : black }
    static var crypto_White_Steel20: UIColor { return App.shared.localStorage.lightMode ? .white : cryptoSteel20 }
    static var crypto_Clear_White: UIColor { return App.shared.localStorage.lightMode ? .white : .clear }
    static var crypto_Silver_Black: UIColor { return App.shared.localStorage.lightMode ? .black : .cryptoSilver }
    static var crypto_Steel20_LightBackground: UIColor { return App.shared.localStorage.lightMode ? .cryptoLightBackground : .cryptoSteel20 }
    static var crypto_Steel40_LightGray: UIColor { return App.shared.localStorage.lightMode ? .cryptoLightGray : .cryptoSteel40 }
    static var crypto_White_Gray: UIColor { return App.shared.localStorage.lightMode ? .white : .cryptoGray }
    static var crypto_Dark_White: UIColor { return App.shared.localStorage.lightMode ? .white: .cryptoDark }
    static var crypto_Dark50_White50: UIColor { return App.shared.localStorage.lightMode ? .cryptoWhite50: .cryptoDark50 }
    static var crypto_SteelDark_White: UIColor { return App.shared.localStorage.lightMode ? .white: .cryptoSteelDark }
    static var crypto_SteelDark_Bars: UIColor { return App.shared.localStorage.lightMode ? .cryptoBars: .cryptoSteelDark }
    static var crypto_LightGray_SteelDark: UIColor { return App.shared.localStorage.lightMode ? .cryptoLightGray: .cryptoSteelDark }
    static var crypto_Black20_Steel20: UIColor { return App.shared.localStorage.lightMode ? .cryptoSteel20: .cryptoBlack20 }
    static var crypto_Black50_Steel20: UIColor { return App.shared.localStorage.lightMode ? .cryptoSteel20: .cryptoBlack50 }

    static var crypto_Silver_Dark50: UIColor { return App.shared.localStorage.lightMode ? .cryptoDark50 : .cryptoSilver50 }

    static let cryptoBars: UIColor = UIColor(named: "Bars") ?? .black
    static let cryptoBars96: UIColor = UIColor(named: "Bars96") ?? .black
    static let cryptoDark: UIColor = UIColor(named: "Dark") ?? .black
    static let cryptoDark50: UIColor = UIColor(named: "Dark50") ?? .black
    static let cryptoDark96: UIColor = UIColor(named: "Dark96") ?? .black
    static let cryptoGray: UIColor = UIColor(named: "Gray") ?? .black
    static let cryptoGray50: UIColor = UIColor(named: "Gray50") ?? .black
    static let cryptoGreen: UIColor = UIColor(named: "Green") ?? .black
    static let cryptoGreen50: UIColor = UIColor(named: "Green50") ?? .black
    static let cryptoGreenPressed: UIColor = UIColor(named: "GreenPressed") ?? .black
    static let cryptoGreen20: UIColor = UIColor(named: "Green20") ?? .black
    static let cryptoLightBackground: UIColor = UIColor(named: "LightBackground") ?? .black
    static let cryptoLightGray: UIColor = UIColor(named: "LightGray") ?? .black
    static let cryptoRed: UIColor = UIColor(named: "Red") ?? .black
    static let cryptoRedPressed: UIColor = UIColor(named: "RedPressed") ?? .black
    static let cryptoSilver: UIColor = UIColor(named: "Silver") ?? .black
    static let cryptoSilver50: UIColor = UIColor(named: "Silver50") ?? .black
    static let cryptoSteel20: UIColor = UIColor(named: "Steel20") ?? .black
    static let cryptoSteel20OnDark: UIColor = UIColor(named: "Steel20OnDark") ?? .black
    static let cryptoSteel40OnDark: UIColor = UIColor(named: "Steel40OnDark") ?? .black
    static let cryptoBlack20: UIColor = UIColor(named: "Black20") ?? .black
    static let cryptoBlack50: UIColor = UIColor(named: "Black50") ?? .black
    static let cryptoSteel40: UIColor = UIColor(named: "Steel40") ?? .black
    static let cryptoSteelDark: UIColor = UIColor(named: "SteelDark") ?? .black
    static let cryptoWhite50: UIColor = UIColor(named: "White50") ?? .black
    static let cryptoWhite60: UIColor = UIColor(named: "White60") ?? .black
    static let cryptoYellow: UIColor = UIColor(named: "Yellow") ?? .black
    static let cryptoYellow50: UIColor = UIColor(named: "Yellow50") ?? .black
    static let cryptoYellow40: UIColor = UIColor(named: "Yellow40") ?? .black
    static let cryptoYellowPressed: UIColor = UIColor(named: "YellowPressed") ?? .black
}
